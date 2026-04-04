// lib/feature/smart_plug/providers/smart_plug_provider.dart
// Riverpod providers for smart plug list, summary, and CRUD operations.
// Handles both simulated plugs and real Tuya devices.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/feature/smart_plug/models/smart_plug_model.dart';

// ── Smart plug list provider ──────────────────────────────────────────────────
final smartPlugListProvider =
    StateNotifierProvider<
      SmartPlugListNotifier,
      AsyncValue<List<SmartPlugModel>>
    >((_) => SmartPlugListNotifier());

class SmartPlugListNotifier
    extends StateNotifier<AsyncValue<List<SmartPlugModel>>> {
  SmartPlugListNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = const AsyncValue.loading();
      final response = await ApiClient.instance.get('/smart-plugs');
      final list = (response.data['data'] as List? ?? [])
          .map((e) => SmartPlugModel.fromMap(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  /// Register a new plug (simulated or real Tuya device).
  Future<SmartPlugModel?> registerPlug({
    required String name,
    String? location,
    bool isSimulated = true,
    String vendor = 'simulator',
    double? baselineWattage,
    // Tuya-specific
    String? tuyaDeviceId,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'vendor': vendor,
        'isSimulated': isSimulated,
        if (location != null) 'location': location,
        if (baselineWattage != null) 'baselineWattage': baselineWattage,
        if (tuyaDeviceId != null) 'tuyaDeviceId': tuyaDeviceId,
      };

      final response = await ApiClient.instance.post(
        '/smart-plugs',
        data: body,
      );
      final plug = SmartPlugModel.fromMap(
        response.data['data'] as Map<String, dynamic>,
      );

      state = state.whenData((plugs) => [plug, ...plugs]);
      return plug;
    } catch (_) {
      rethrow;
    }
  }

  /// Delete a plug.
  Future<void> deletePlug(String id) async {
    await ApiClient.instance.delete('/smart-plugs/$id');
    state = state.whenData((plugs) => plugs.where((p) => p.id != id).toList());
  }

  /// Manually trigger a reading with optional spike.
  Future<bool> triggerReading(String id, {bool forceSpike = false}) async {
    final response = await ApiClient.instance.post(
      '/smart-plugs/$id/simulate',
      data: {'forceSpike': forceSpike},
    );

    // Keep REST snapshot in sync so dashboard can reflect anomaly state
    // even if a websocket event is delayed or unavailable.
    await _load();

    final data = response.data['data'] as Map<String, dynamic>?;
    return data?['isAnomaly'] == true;
  }

  /// Turn a real Tuya plug on or off.
  Future<void> controlTuyaPlug(String id, {required bool turnOn}) async {
    await ApiClient.instance.post(
      '/smart-plugs/$id/control',
      data: {'turnOn': turnOn},
    );
  }
}

// ── Summary provider ──────────────────────────────────────────────────────────
final smartPlugSummaryProvider =
    StateNotifierProvider<
      SmartPlugSummaryNotifier,
      AsyncValue<SmartPlugSummary>
    >((_) => SmartPlugSummaryNotifier());

class SmartPlugSummary {
  final int totalPlugs;
  final int onlinePlugs;
  final int anomalyPlugs;
  final double liveWattage;

  const SmartPlugSummary({
    this.totalPlugs = 0,
    this.onlinePlugs = 0,
    this.anomalyPlugs = 0,
    this.liveWattage = 0,
  });

  bool get hasAnomalies => anomalyPlugs > 0;
}

class SmartPlugSummaryNotifier
    extends StateNotifier<AsyncValue<SmartPlugSummary>> {
  SmartPlugSummaryNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ApiClient.instance.get('/smart-plugs/summary');
      final d = response.data['data'] as Map<String, dynamic>;
      state = AsyncValue.data(
        SmartPlugSummary(
          totalPlugs: d['totalPlugs'] as int? ?? 0,
          onlinePlugs: d['onlinePlugs'] as int? ?? 0,
          anomalyPlugs: d['anomalyPlugs'] as int? ?? 0,
          liveWattage: (d['liveWattage'] as num?)?.toDouble() ?? 0,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();
}

// ── Tuya device discovery provider ───────────────────────────────────────────
final tuyaDevicesProvider = FutureProvider<List<TuyaDevice>>((ref) async {
  final response = await ApiClient.instance.get('/smart-plugs/tuya-devices');
  final list = response.data['data'];
  if (list == null) return [];
  if (list is List) {
    return list
        .map((e) => TuyaDevice.fromMap(e as Map<String, dynamic>))
        .toList();
  }
  // Some Tuya endpoints wrap in { list: [...] }
  final inner = (list as Map)['list'] as List? ?? [];
  return inner
      .map((e) => TuyaDevice.fromMap(e as Map<String, dynamic>))
      .toList();
});

class TuyaDevice {
  final String id;
  final String name;
  final String category;
  final bool online;

  const TuyaDevice({
    required this.id,
    required this.name,
    required this.category,
    required this.online,
  });

  factory TuyaDevice.fromMap(Map<String, dynamic> m) => TuyaDevice(
    id: m['id'] as String? ?? m['device_id'] as String? ?? '',
    name: m['name'] as String? ?? 'Unknown Device',
    category: m['category'] as String? ?? 'unknown',
    online: m['online'] as bool? ?? false,
  );
}
