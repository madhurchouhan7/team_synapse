// lib/feature/insights/services/heatmap_local_service.dart
//
// Hive-backed local cache for the daily intensity heatmap.
// Architecture (MongoDB → Hive → UI):
//
//   1. On app start  → read from Hive instantly (zero-latency UI boot)
//   2. On action toggle → write optimistic Hive entry immediately
//   3. POST /users/me/heatmap → MongoDB writes the confirmed value
//   4. Response writes back to Hive (source of truth updated)
//   5. UI is always driven by Hive; never blocked on network

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

const _kBoxName = 'heatmap_cache';

/// Key for the full heatmap JSON blob: Map<"YYYY-MM-DD", int>
const _kHeatmapData = 'heatmap_data';

/// Epoch-ms timestamp of when the cache was last written
const _kUpdatedAt = 'heatmap_updated_at';

class HeatmapLocalService {
  static HeatmapLocalService? _instance;
  static HeatmapLocalService get instance =>
      _instance ??= HeatmapLocalService._();
  HeatmapLocalService._();

  Box? _box;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  /// Call once from main() after Hive.initFlutter().
  Future<void> init() async {
    _box = await Hive.openBox(_kBoxName);
  }

  Box get _opened {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'HeatmapLocalService not initialised. '
        'Call HeatmapLocalService.instance.init() in main().',
      );
    }
    return _box!;
  }

  // ── Read ─────────────────────────────────────────────────────────────────────

  /// Returns the cached heatmap as { "YYYY-MM-DD": 0|1|2|3 }.
  /// Returns an empty map if nothing is stored yet.
  Map<String, int> read() {
    final box = _opened;
    final raw = box.get(_kHeatmapData) as String?;
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  /// Whether the cache is fresh enough (written within the last 10 minutes).
  bool get isFresh {
    final ms = _opened.get(_kUpdatedAt) as int?;
    if (ms == null) return false;
    return DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(ms))
            .inMinutes <
        10;
  }

  // ── Write ─────────────────────────────────────────────────────────────────────

  /// Overwrites the full heatmap cache (called after a successful API response).
  Future<void> write(Map<String, int> heatmap) async {
    await _opened.putAll({
      _kHeatmapData: jsonEncode(heatmap),
      _kUpdatedAt: DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Optimistically updates a single day's intensity without a network round-trip.
  /// Merges into the existing cache; keeps all other days intact.
  Future<void> writeOptimistic({
    required String dateKey, // "YYYY-MM-DD"
    required int intensity, // 0|1|2|3
  }) async {
    final existing = read();
    existing[dateKey] = intensity;
    await write(existing);
  }

  // ── Clear ─────────────────────────────────────────────────────────────────────

  Future<void> clear() async {
    await _opened.clear();
  }
}
