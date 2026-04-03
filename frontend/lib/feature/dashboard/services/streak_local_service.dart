// lib/feature/dashboard/services/streak_local_service.dart
//
// Hive-backed local cache for streak data.
// The Flutter app reads from this first (instant), then syncs with MongoDB
// in the background.  On a successful API response the cache is refreshed.

import 'package:hive_flutter/hive_flutter.dart';

/// The Hive box name shared across the app.
const _kBoxName = 'streak_cache';

/// Keys inside the Hive box.
const _kStreak = 'streak';
const _kLastCheckIn = 'lastCheckIn'; // stored as ISO-8601 String
const _kLongestStreak = 'longestStreak';
const _kUpdatedAt = 'updatedAt'; // epoch ms int

class StreakData {
  final int streak;
  final DateTime? lastCheckIn;
  final int longestStreak;
  final DateTime updatedAt;

  const StreakData({
    required this.streak,
    this.lastCheckIn,
    required this.longestStreak,
    required this.updatedAt,
  });

  /// Whether the cached data is fresh enough (< 5 minutes old).
  bool get isFresh {
    return DateTime.now().difference(updatedAt).inMinutes < 5;
  }
}

class StreakLocalService {
  static StreakLocalService? _instance;
  static StreakLocalService get instance =>
      _instance ??= StreakLocalService._();
  StreakLocalService._();

  Box? _box;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  /// Call once from main() after Hive.initFlutter().
  Future<void> init() async {
    _box = await Hive.openBox(_kBoxName);
  }

  Box get _opened {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'StreakLocalService not initialised. '
        'Call StreakLocalService.instance.init() in main().',
      );
    }
    return _box!;
  }

  // ── Read ─────────────────────────────────────────────────────────────────────

  /// Returns cached streak data, or null if nothing is stored yet.
  StreakData? read() {
    final box = _opened;
    final streakRaw = box.get(_kStreak);
    if (streakRaw == null) return null;

    final lastCheckInStr = box.get(_kLastCheckIn) as String?;
    final longestStreakRaw = box.get(_kLongestStreak) as int? ?? 0;
    final updatedAtMs = box.get(_kUpdatedAt) as int?;

    return StreakData(
      streak: streakRaw as int,
      lastCheckIn: lastCheckInStr != null
          ? DateTime.tryParse(lastCheckInStr)
          : null,
      longestStreak: longestStreakRaw,
      updatedAt: updatedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtMs)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  // ── Write ─────────────────────────────────────────────────────────────────────

  /// Persists a streak snapshot from the backend response.
  Future<void> write({
    required int streak,
    required DateTime? lastCheckIn,
    required int longestStreak,
  }) async {
    final box = _opened;
    await box.putAll({
      _kStreak: streak,
      _kLastCheckIn: lastCheckIn?.toUtc().toIso8601String(),
      _kLongestStreak: longestStreak,
      _kUpdatedAt: DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Optimistically update the local cache before the API responds.
  /// Keeps the existing longestStreak so we don't accidentally lower it.
  Future<void> writeOptimistic({
    required int streak,
    required DateTime lastCheckIn,
  }) async {
    final existing = read();
    final longestStreak = existing != null
        ? existing.longestStreak.clamp(streak, 9999)
        : streak;
    await write(
      streak: streak,
      lastCheckIn: lastCheckIn,
      longestStreak: longestStreak,
    );
  }

  // ── Clear ─────────────────────────────────────────────────────────────────────

  Future<void> clear() async {
    await _opened.clear();
  }
}
