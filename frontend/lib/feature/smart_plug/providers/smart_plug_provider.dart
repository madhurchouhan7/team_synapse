// lib/feature/smart_plug/providers/smart_plug_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/feature/smart_plug/models/smart_plug_model.dart';

// ── Summary state (for dashboard widget) ────────────────────────────────────
class SmartPlugSummary {
  final int totalPlugs;
  final int onlinePlugs;
  final int anomalyPlugs;
  final double liveWattage;
  final List<SmartPlugModel> plugs;

  const SmartPlugSummary({
    required this.totalPlugs,
    required this.onlinePlugs,
    required this.anomalyPlugs,
    required this.liveWattage,
    required this.plugs,
  });

  bool get hasAnomalies => anomalyPlugs > 0;
}

// ── Providers ────────────────────────────────────────────────────────────────

/// Full plug list — used by the SmartPlugScreen
final smartPlugListProvider = StateNotifierProvider<
    SmartPlugListNotifier,
    AsyncValue<List<SmartPlugModel>>>((ref) => SmartPlugListNotifier());

/// Summary for the dashboard widget
final smartPlugSummaryProvider = StateNotifierProvider<
    SmartPlugSummaryNotifier,
    AsyncValue<SmartPlugSummary>>((ref) => SmartPlugSummaryNotifier());

// ── Notifiers ────────────────────────────────────────────────────────────────

class SmartPlugListNotifier
    extends StateNotifier<AsyncValue<List<SmartPlugModel>>> {
  SmartPlugListNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.get('/smart-plugs');
      final data =
          (response.data['data'] as List<dynamic>? ?? []);
      final plugs = data
          .whereType<Map>()
          .map((e) => SmartPlugModel.fromMap(e.cast<String, dynamic>()))
          .toList();
      state = AsyncValue.data(plugs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<SmartPlugModel?> registerPlug({
    required String name,
    String? applianceId,
    String vendor = 'simulator',
    bool isSimulated = true,
    String? location,
    double? baselineWattage,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'vendor': vendor,
        'isSimulated': isSimulated,
        if (applianceId != null) 'applianceId': applianceId,
        if (location != null) 'location': location,
        if (baselineWattage != null) 'baselineWattage': baselineWattage,
      };
      final response = await ApiClient.instance.post('/smart-plugs', data: body);
      final newPlug = SmartPlugModel.fromMap(
          (response.data['data'] as Map).cast<String, dynamic>());

      state.whenData((list) {
        state = AsyncValue.data([newPlug, ...list]);
      });
      return newPlug;
    } catch (_) {
      return null;
    }
  }

  Future<void> deletePlug(String plugId) async {
    try {
      await ApiClient.instance.delete('/smart-plugs/$plugId');
      state.whenData((list) {
        state = AsyncValue.data(list.where((p) => p.id != plugId).toList());
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> triggerReading(
    String plugId, {
    double? wattageOverride,
    bool forceSpike = false,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/smart-plugs/$plugId/simulate',
        data: {
          if (wattageOverride != null) 'wattageOverride': wattageOverride,
          'forceSpike': forceSpike,
        },
      );
      // Refresh list to show updated lastReading
      refresh();
      return response.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}

class SmartPlugSummaryNotifier
    extends StateNotifier<AsyncValue<SmartPlugSummary>> {
  SmartPlugSummaryNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final response = await ApiClient.instance.get('/smart-plugs/summary');
      final d = response.data['data'] as Map<String, dynamic>;
      final plugs = (d['plugs'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => SmartPlugModel.fromMap(e.cast<String, dynamic>()))
          .toList();

      state = AsyncValue.data(
        SmartPlugSummary(
          totalPlugs:   (d['totalPlugs'] as num?)?.toInt() ?? 0,
          onlinePlugs:  (d['onlinePlugs'] as num?)?.toInt() ?? 0,
          anomalyPlugs: (d['anomalyPlugs'] as num?)?.toInt() ?? 0,
          liveWattage:  (d['liveWattage'] as num?)?.toDouble() ?? 0.0,
          plugs:        plugs,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
