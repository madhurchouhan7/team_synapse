// lib/feature/smart_plug/providers/ws_telemetry_provider.dart
// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider that subscribes to the WebSocket stream and maintains
// a live map of per-plug wattage readings with a rolling history buffer.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/core/network/ws_client.dart';
import 'package:watt_sense/feature/smart_plug/models/telemetry_reading_model.dart';

const int _kHistoryLimit = 60; // keep last 60 points per plug (~5 min @ 5s)

// ── Live reading data per plug ──────────────────────────────────────────────
class LivePlugData {
  final String plugId;
  final String plugName;
  final String applianceName;
  final double wattage;
  final double voltage;
  final bool isAnomaly;
  final String? deviceState; // e.g. 'cooling', 'compressor_on'
  final DateTime timestamp;
  final List<TelemetryReading> history;

  const LivePlugData({
    required this.plugId,
    required this.plugName,
    required this.applianceName,
    required this.wattage,
    required this.voltage,
    required this.isAnomaly,
    this.deviceState,
    required this.timestamp,
    required this.history,
  });

  LivePlugData copyWith({
    double? wattage,
    double? voltage,
    bool? isAnomaly,
    String? deviceState,
    DateTime? timestamp,
    List<TelemetryReading>? history,
  }) => LivePlugData(
    plugId: plugId,
    plugName: plugName,
    applianceName: applianceName,
    wattage: wattage ?? this.wattage,
    voltage: voltage ?? this.voltage,
    isAnomaly: isAnomaly ?? this.isAnomaly,
    deviceState: deviceState ?? this.deviceState,
    timestamp: timestamp ?? this.timestamp,
    history: history ?? this.history,
  );
}

// ── State ─────────────────────────────────────────────────────────────────────
class WsTelemetryState {
  /// Map<plugId, LivePlugData>
  final Map<String, LivePlugData> liveData;

  /// Most recent in-app anomaly event (for banner)
  final WsEvent? latestAnomaly;

  /// Connection status
  final bool isConnected;

  const WsTelemetryState({
    this.liveData = const {},
    this.latestAnomaly,
    this.isConnected = false,
  });

  WsTelemetryState copyWith({
    Map<String, LivePlugData>? liveData,
    WsEvent? latestAnomaly,
    bool? isConnected,
  }) => WsTelemetryState(
    liveData: liveData ?? this.liveData,
    latestAnomaly: latestAnomaly ?? this.latestAnomaly,
    isConnected: isConnected ?? this.isConnected,
  );

  double get totalLiveWattage =>
      liveData.values.fold(0.0, (s, d) => s + d.wattage);

  bool get hasAnomalies => liveData.values.any((d) => d.isAnomaly);

  List<LivePlugData> get anomalousPlugs =>
      liveData.values.where((d) => d.isAnomaly).toList();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final wsTelemetryProvider =
    StateNotifierProvider<WsTelemetryNotifier, WsTelemetryState>(
      (_) => WsTelemetryNotifier(),
    );

class WsTelemetryNotifier extends StateNotifier<WsTelemetryState> {
  StreamSubscription<WsEvent>? _sub;
  String? _connectedUserId;

  WsTelemetryNotifier() : super(const WsTelemetryState());

  /// Connect the WebSocket and start listening.
  void connect(String userId) {
    final sameUser = _connectedUserId == userId;
    if (sameUser && _sub != null && WsClient.instance.isConnected) {
      state = state.copyWith(isConnected: true);
      return;
    }

    if (!sameUser && _connectedUserId != null) {
      _sub?.cancel();
      _sub = null;
      WsClient.instance.disconnect();
    }

    _connectedUserId = userId;
    WsClient.instance.connect(userId: userId);

    _sub ??= WsClient.instance.stream.listen(_handleEvent);
    state = state.copyWith(isConnected: true);
  }

  void disconnect() {
    _sub?.cancel();
    _sub = null;
    _connectedUserId = null;
    WsClient.instance.disconnect();
    state = state.copyWith(isConnected: false);
  }

  void _handleEvent(WsEvent event) {
    switch (event.type) {
      case 'reading':
        _handleReading(event);
        break;
      case 'anomaly':
        _handleAnomaly(event);
        break;
      case 'connected':
        state = state.copyWith(isConnected: true);
        break;
    }
  }

  void _handleReading(WsEvent event) {
    final d = event.data;
    final plugId = d['plugId'] as String? ?? '';
    final plugName = d['plugName'] as String? ?? plugId;
    final applianceName = d['applianceName'] as String? ?? plugName;
    final wattage = (d['wattage'] as num?)?.toDouble() ?? 0.0;
    final voltage = (d['voltage'] as num?)?.toDouble() ?? 230.0;
    final isAnomaly = d['isAnomaly'] as bool? ?? false;
    final deviceState = d['deviceState'] as String?;
    final ts =
        DateTime.tryParse(d['timestamp'] as String? ?? '') ?? DateTime.now();

    // Build a lightweight TelemetryReading for the history buffer
    final reading = TelemetryReading(
      id: '',
      plugId: plugId,
      wattage: wattage,
      voltage: voltage,
      isAnomaly: isAnomaly,
      timestamp: ts,
    );

    final existing = state.liveData[plugId];
    final history = List<TelemetryReading>.from(existing?.history ?? []);
    history.add(reading);
    if (history.length > _kHistoryLimit) {
      history.removeRange(0, history.length - _kHistoryLimit);
    }

    final newData = LivePlugData(
      plugId: plugId,
      plugName: plugName,
      applianceName: applianceName,
      wattage: wattage,
      voltage: voltage,
      isAnomaly: isAnomaly,
      deviceState: deviceState,
      timestamp: ts,
      history: history,
    );

    final updated = Map<String, LivePlugData>.from(state.liveData);
    updated[plugId] = newData;
    state = state.copyWith(liveData: updated);
  }

  void _handleAnomaly(WsEvent event) {
    state = state.copyWith(latestAnomaly: event);
  }

  /// Clear the latest anomaly alert (after user dismisses banner)
  void clearAnomaly() {
    state = WsTelemetryState(
      liveData: state.liveData,
      latestAnomaly: null,
      isConnected: state.isConnected,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
