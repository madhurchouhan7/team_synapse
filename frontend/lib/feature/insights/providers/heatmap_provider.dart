// lib/feature/insights/providers/heatmap_provider.dart
//
// Architecture (MongoDB → Hive → UI):
//
//   1. On load      → read Hive immediately (instant UI)
//   2. On toggle    → compute new intensity → optimistic Hive write → rebuild UI
//   3. POST backend → MongoDB writes the real value
//   4. On success   → write confirmed value back to Hive → final rebuild
//   5. On GET       → merge server data back to Hive (background sync)
//
// The provider is driven by [_heatmapHiveTrigger] so any Hive write causes
// all dependent widgets to rebuild without a frame delay.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/auth/repository/user_repository.dart';
import 'package:watt_sense/feature/insights/services/heatmap_local_service.dart';

// ── Trigger counter ──────────────────────────────────────────────────────────
// Increment this to force all heatmap-dependent providers to rebuild.
final heatmapHiveTrigger = StateProvider<int>((ref) => 0);

// ── Read-only provider: current month's heatmap ──────────────────────────────
// Returns Map<"YYYY-MM-DD", 0|1|2|3> scoped to the current calendar month.
final heatmapProvider = Provider<Map<String, int>>((ref) {
  ref.watch(heatmapHiveTrigger); // Rebuild on any Hive write
  return HeatmapLocalService.instance.read();
});

// ── HeatmapNotifier ──────────────────────────────────────────────────────────
// Flow:
//   1. Compute intensity from completed/total
//   2. Write optimistic Hive entry → UI rebuilds instantly
//   3. POST /users/me/heatmap → MongoDB confirms
//   4. Write confirmed value to Hive → final UI reconfirm
class HeatmapNotifier extends StateNotifier<AsyncValue<void>> {
  final UserRepository _repo;
  final Ref _ref;

  HeatmapNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  void _bump() {
    _ref.read(heatmapHiveTrigger.notifier).update((v) => v + 1);
  }

  /// Call this whenever the daily action toggle state changes.
  /// [completedCount] is the number of completed actions.
  /// [totalCount] is the total number of actions.
  Future<void> recordIntensity({
    required int completedCount,
    required int totalCount,
  }) async {
    // ── Step 1: compute intensity locally ──────────────────────────────────────
    final int intensity;
    if (totalCount <= 0) {
      intensity = 0;
    } else {
      final ratio = completedCount / totalCount;
      if (ratio <= 0) {
        intensity = 0;
      } else if (ratio <= 0.33) {
        intensity = 1;
      } else if (ratio <= 0.66) {
        intensity = 2;
      } else {
        intensity = 3;
      }
    }

    // ── Step 2: optimistic Hive write ──────────────────────────────────────────
    final now = DateTime.now().toUtc();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await HeatmapLocalService.instance.writeOptimistic(
      dateKey: dateKey,
      intensity: intensity,
    );
    _bump(); // Instant UI rebuild

    // ── Step 3: POST to MongoDB ────────────────────────────────────────────────
    state = const AsyncValue.loading();
    try {
      final result = await _repo.recordHeatmap(
        completedCount: completedCount,
        totalCount: totalCount,
      );

      // ── Step 4: Write confirmed data ───────────────────────────────────────
      final confirmedIntensity =
          (result['intensity'] as num?)?.toInt() ?? intensity;
      await HeatmapLocalService.instance.writeOptimistic(
        dateKey: dateKey,
        intensity: confirmedIntensity,
      );
      _bump();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      // Keep the optimistic write — it's still better than showing nothing.
      state = AsyncValue.error(e, st);
    }
  }

  /// Fetches the full month's heatmap from the server and merges into Hive.
  /// Call on app resume / screen open when the cache is stale.
  Future<void> refreshFromServer({
    required int year,
    required int month,
  }) async {
    try {
      final serverData = await _repo.fetchMonthlyHeatmap(
        year: year,
        month: month,
      );

      // Merge: server is the authoritative source for past days.
      // We keep any keys from today that may not have synced yet.
      final existing = HeatmapLocalService.instance.read();
      final today = DateTime.now().toUtc();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final merged = {...serverData};
      if (existing.containsKey(todayKey) && !merged.containsKey(todayKey)) {
        merged[todayKey] = existing[todayKey]!;
      }

      await HeatmapLocalService.instance.write(merged);
      _bump();
    } catch (_) {
      // Silently fail — cached data is still served
    }
  }
}

final heatmapNotifierProvider =
    StateNotifierProvider<HeatmapNotifier, AsyncValue<void>>((ref) {
      final repo = ref.read(userRepositoryProvider);
      return HeatmapNotifier(repo, ref);
    });
