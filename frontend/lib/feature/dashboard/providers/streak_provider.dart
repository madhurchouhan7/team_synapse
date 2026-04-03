// lib/feature/dashboard/providers/streak_provider.dart
//
// Architecture (MongoDB → Hive → UI):
//
//  1.  On app start  → read from Hive immediately (zero-latency UI boot)
//  2.  After check-in → write optimistic Hive entry instantly
//  3.  POST /users/me/streak → MongoDB does the increment server-side
//  4.  Response stored back into Hive (source of truth updated)
//  5.  UI always driven by Hive; never waits for network to repaint

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/auth/models/user_model.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/auth/repository/user_repository.dart';
import 'package:watt_sense/feature/dashboard/services/streak_local_service.dart';

// ---------------------------------------------------------------------------
// StreakState — single snapshot consumed by all streak-related widgets
// ---------------------------------------------------------------------------
class StreakState {
  final int streak;
  final int longestStreak;
  final DateTime? lastCheckIn;
  final bool checkedInToday;
  final bool isStreakBroken;

  const StreakState({
    required this.streak,
    required this.longestStreak,
    this.lastCheckIn,
    required this.checkedInToday,
    required this.isStreakBroken,
  });

  static const zero = StreakState(
    streak: 0,
    longestStreak: 0,
    checkedInToday: false,
    isStreakBroken: false,
  );
}

// ---------------------------------------------------------------------------
// Hive-sourced streak provider
//
// Watches [_streakHiveTrigger] (a counter we bump whenever Hive is written)
// so the provider rebuilds as soon as the cache is updated — whether
// optimistically or after the real API response arrives.
// ---------------------------------------------------------------------------
final _streakHiveTrigger = StateProvider<int>((ref) => 0);

final streakStateProvider = Provider<StreakState>((ref) {
  // Subscribe to trigger so we rebuild whenever Hive is written
  ref.watch(_streakHiveTrigger);

  // Also watch Firebase auth (gives us initial data on first launch before
  // Hive is populated, and on fresh installs)
  final userAsync = ref.watch(authStateProvider);
  final UserModel? user = userAsync.valueOrNull;

  // Prefer Hive (faster, offline-ready)
  final cached = StreakLocalService.instance.read();

  final int rawStreak;
  final DateTime? lastCheckIn;
  final int longestStreak;

  if (cached != null) {
    rawStreak = cached.streak;
    lastCheckIn = cached.lastCheckIn;
    longestStreak = cached.longestStreak;
  } else if (user != null) {
    // Fallback to auth stream on very first launch
    rawStreak = user.streak;
    lastCheckIn = user.lastCheckIn;
    longestStreak = 0;
  } else {
    return StreakState.zero;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  bool checkedInToday = false;
  bool isStreakBroken = false;

  if (lastCheckIn != null) {
    final lastDay = DateTime(
      lastCheckIn.year,
      lastCheckIn.month,
      lastCheckIn.day,
    );
    final diffDays = today.difference(lastDay).inDays;
    checkedInToday = diffDays == 0;
    isStreakBroken = diffDays > 1 && rawStreak > 0;
  }

  return StreakState(
    streak: isStreakBroken ? 0 : rawStreak,
    longestStreak: longestStreak,
    lastCheckIn: lastCheckIn,
    checkedInToday: checkedInToday,
    isStreakBroken: isStreakBroken,
  );
});

// ---------------------------------------------------------------------------
// Simple int helper — backwards compat
// ---------------------------------------------------------------------------
final streakProvider = Provider<int>((ref) {
  return ref.watch(streakStateProvider).streak;
});

// ---------------------------------------------------------------------------
// Bool helper — used by insights_provider
// ---------------------------------------------------------------------------
final optimisticCheckInProvider = Provider<bool>((ref) {
  return ref.watch(streakStateProvider).checkedInToday;
});

// ---------------------------------------------------------------------------
// Weekday dots provider  (Mon=0 … Sun=6)
// ---------------------------------------------------------------------------
final streakWeekdaysProvider = Provider<List<bool>>((ref) {
  final state = ref.watch(streakStateProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayWeekdayIndex = now.weekday - 1;

  final List<bool> achieved = List.filled(7, false);
  if (state.streak <= 0 || state.lastCheckIn == null) return achieved;

  final lastCheckInDay = DateTime(
    state.lastCheckIn!.year,
    state.lastCheckIn!.month,
    state.lastCheckIn!.day,
  );
  final weekStart = today.subtract(Duration(days: todayWeekdayIndex));
  final weekEnd = weekStart.add(const Duration(days: 6));

  for (int i = 0; i < state.streak; i++) {
    final day = lastCheckInDay.subtract(Duration(days: i));
    if (!day.isBefore(weekStart) && !day.isAfter(weekEnd)) {
      achieved[day.weekday - 1] = true;
    }
  }
  return achieved;
});

// ---------------------------------------------------------------------------
// StreakNotifier
// Flow:
//   1. Write optimistic Hive entry → trigger UI rebuild instantly
//   2. POST /users/me/streak → MongoDB processes the increment
//   3. Write confirmed data from response back to Hive → trigger rebuild
//   4. If API fails → still kept the old Hive data (rollback)
// ---------------------------------------------------------------------------
class StreakNotifier extends StateNotifier<AsyncValue<void>> {
  final UserRepository _repo;
  final Ref _ref;

  StreakNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  void _bump() {
    _ref.read(_streakHiveTrigger.notifier).update((v) => v + 1);
  }

  /// Returns true if a new check-in was recorded, false if already done today.
  Future<bool> checkIn() async {
    // Read current Hive state (most accurate local source)
    final cached = StreakLocalService.instance.read();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (cached?.lastCheckIn != null) {
      final lastDay = DateTime(
        cached!.lastCheckIn!.year,
        cached.lastCheckIn!.month,
        cached.lastCheckIn!.day,
      );
      if (today.difference(lastDay).inDays == 0) {
        // Already checked in today — no-op
        return false;
      }
    }

    // ── Step 1: Optimistic Hive write ────────────────────────────────────────
    final optimisticStreak = (cached?.streak ?? 0) + 1;
    await StreakLocalService.instance.writeOptimistic(
      streak: optimisticStreak,
      lastCheckIn: now,
    );
    _bump(); // Trigger immediate UI rebuild

    // ── Step 2: Call MongoDB via backend ─────────────────────────────────────
    state = const AsyncValue.loading();
    try {
      final result = await _repo.checkInStreak();

      if (result.alreadyCheckedIn) {
        // Server says already done — write real data and return false
        await StreakLocalService.instance.write(
          streak: result.streak,
          lastCheckIn: result.lastCheckIn,
          longestStreak: result.longestStreak,
        );
        _bump();
        state = const AsyncValue.data(null);
        return false;
      }

      // ── Step 3: Confirm — write real response into Hive ───────────────────
      await StreakLocalService.instance.write(
        streak: result.streak,
        lastCheckIn: result.lastCheckIn,
        longestStreak: result.longestStreak,
      );
      _bump(); // Trigger final UI update with confirmed data

      // Optionally refresh the Firebase/authState in the background (low prio)
      _ref.invalidate(authStateProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      // ── Rollback: the old Hive data is still there (we overwrote with
      // optimistic). Restore from auth stream if possible.
      final userModel = _ref.read(authStateProvider).valueOrNull;
      if (userModel != null) {
        await StreakLocalService.instance.write(
          streak: userModel.streak,
          lastCheckIn: userModel.lastCheckIn,
          longestStreak: 0,
        );
        _bump();
      }
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Fetches fresh streak data from MongoDB and updates Hive.
  /// Call this on app resume / dashboard refresh.
  Future<void> refreshFromServer() async {
    try {
      final result = await _repo.fetchStreak();
      await StreakLocalService.instance.write(
        streak: result.streak,
        lastCheckIn: result.lastCheckIn,
        longestStreak: result.longestStreak,
      );
      _bump();
    } catch (_) {
      // Silently ignore — cached data is still served
    }
  }
}

final streakNotifierProvider =
    StateNotifierProvider<StreakNotifier, AsyncValue<void>>((ref) {
      final repo = ref.read(userRepositoryProvider);
      return StreakNotifier(repo, ref);
    });
