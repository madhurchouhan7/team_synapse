// lib/feature/smart_plug/providers/telemetry_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/feature/smart_plug/models/telemetry_reading_model.dart';

class TelemetryState {
  final List<TelemetryReading> readings;
  final int anomalyCount;
  final bool isLoading;
  final String? error;

  const TelemetryState({
    this.readings = const [],
    this.anomalyCount = 0,
    this.isLoading = false,
    this.error,
  });

  TelemetryState copyWith({
    List<TelemetryReading>? readings,
    int? anomalyCount,
    bool? isLoading,
    String? error,
  }) =>
      TelemetryState(
        readings:     readings ?? this.readings,
        anomalyCount: anomalyCount ?? this.anomalyCount,
        isLoading:    isLoading ?? this.isLoading,
        error:        error,
      );

  List<TelemetryReading> get anomalies =>
      readings.where((r) => r.isAnomaly).toList();
}

// Family provider — keyed by plug mongo ID
final telemetryProvider = StateNotifierProvider.family<
    TelemetryNotifier,
    TelemetryState,
    String>((ref, plugId) => TelemetryNotifier(plugId));

class TelemetryNotifier extends StateNotifier<TelemetryState> {
  final String _plugId;

  TelemetryNotifier(this._plugId) : super(const TelemetryState(isLoading: true)) {
    fetch();
  }

  Future<void> fetch({int limit = 50}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '/smart-plugs/$_plugId/telemetry',
        queryParams: {'limit': limit},
      );
      final d         = response.data['data'] as Map<String, dynamic>;
      final rawList   = d['readings'] as List<dynamic>? ?? [];
      final readings  = rawList
          .whereType<Map>()
          .map((e) => TelemetryReading.fromMap(e.cast<String, dynamic>()))
          .toList();
      // Ensure ascending order for chart
      readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      state = TelemetryState(
        readings:     readings,
        anomalyCount: (d['anomalyCount'] as num?)?.toInt() ?? 0,
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
