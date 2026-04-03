import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watt_sense/core/network/api_client.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(apiClient: ApiClient.instance);
});

class StreakCheckInResult {
  final int streak;
  final DateTime lastCheckIn;
  final int longestStreak;
  final bool alreadyCheckedIn;
  final String message;

  const StreakCheckInResult({
    required this.streak,
    required this.lastCheckIn,
    required this.longestStreak,
    required this.alreadyCheckedIn,
    required this.message,
  });

  factory StreakCheckInResult.fromJson(Map<String, dynamic> json) {
    return StreakCheckInResult(
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      lastCheckIn: DateTime.parse(json['lastCheckIn'] as String).toLocal(),
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      alreadyCheckedIn: json['alreadyCheckedIn'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}

class UserRepository {
  final ApiClient _apiClient;

  UserRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> saveGPSAddress({
    required double lat,
    required double lng,
  }) async {
    try {
      await _apiClient.put(
        '/users/me',
        data: {
          'address': {'lat': lat, 'lng': lng},
        },
      );
    } catch (e) {
      throw Exception('Failed to save GPS location: $e');
    }
  }

  Future<void> saveAddress({
    required String state,
    required String city,
    required String discom,
    double? lat,
    double? lng,
  }) async {
    try {
      await _apiClient.put(
        '/users/me',
        data: {
          'address': {
            'state': state,
            'city': city,
            'discom': discom,
            'lat': lat,
            'lng': lng,
          },
        },
      );
    } catch (e) {
      throw Exception('Failed to save address: $e');
    }
  }

  Future<void> saveHouseholdDetails({
    required int peopleCount,
    String? familyType,
    String? houseType,
  }) async {
    try {
      await _apiClient.put(
        '/users/me',
        data: {
          'household': {
            'peopleCount': peopleCount,
            'familyType': familyType,
            'houseType': houseType,
          },
        },
      );
    } catch (e) {
      throw Exception('Failed to save household details: $e');
    }
  }

  Future<void> savePlanPreferences({
    required List<String> mainGoals,
    required String focusArea,
  }) async {
    try {
      await _apiClient.put(
        '/users/me',
        data: {
          'planPreferences': {'mainGoals': mainGoals, 'focusArea': focusArea},
        },
      );
    } catch (e) {
      throw Exception('Failed to save plan preferences: $e');
    }
  }

  Future<Map<String, dynamic>?> saveActivePlan(
    Map<String, dynamic>? planData,
  ) async {
    try {
      final response = await _apiClient.put(
        '/users/me',
        data: {'activePlan': planData},
      );
      final updatedUserData = response.data['data'] as Map<String, dynamic>?;

      // Update local cache immediately for synchronous UI transitions
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final prefs = await SharedPreferences.getInstance();
        if (planData != null) {
          await prefs.setString(
            'active_plan_${firebaseUser.uid}',
            jsonEncode(planData),
          );
        } else {
          await prefs.remove('active_plan_${firebaseUser.uid}');
        }
      }
      return updatedUserData;
    } catch (e) {
      throw Exception('Failed to activate plan: $e');
    }
  }

  // ── Streak API ──────────────────────────────────────────────────────────────

  /// Calls POST /users/me/streak — the server handles all the streak logic.
  /// Returns the fresh streak state from MongoDB.
  Future<StreakCheckInResult> checkInStreak() async {
    try {
      final response = await _apiClient.post('/users/me/streak', data: {});
      final data = response.data['data'] as Map<String, dynamic>;
      return StreakCheckInResult.fromJson(data);
    } catch (e) {
      throw Exception('Failed to record check-in: $e');
    }
  }

  /// Calls GET /users/me/streak — fetches latest streak without modifying it.
  Future<StreakCheckInResult> fetchStreak() async {
    try {
      final response = await _apiClient.get('/users/me/streak');
      final data = response.data['data'] as Map<String, dynamic>;
      return StreakCheckInResult.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch streak: $e');
    }
  }

  /// Legacy: direct streak update (kept for backwards compat with any other callers).
  Future<void> updateStreak(int streak, DateTime lastCheckIn) async {
    try {
      await _apiClient.put(
        '/users/me',
        data: {'streak': streak, 'lastCheckIn': lastCheckIn.toIso8601String()},
      );
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  // ── Heatmap API ──────────────────────────────────────────────────────────────

  /// POST /users/me/heatmap — writes today's intensity for the current day.
  /// Returns { dateKey: "YYYY-MM-DD", intensity: 0|1|2|3 }.
  Future<Map<String, dynamic>> recordHeatmap({
    required int completedCount,
    required int totalCount,
  }) async {
    try {
      final response = await _apiClient.post(
        '/users/me/heatmap',
        data: {'completedCount': completedCount, 'totalCount': totalCount},
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to record heatmap: $e');
    }
  }

  /// GET /users/me/heatmap?year=YYYY&month=M — fetches the monthly heatmap.
  /// Returns Map<"YYYY-MM-DD", int>.
  Future<Map<String, int>> fetchMonthlyHeatmap({
    required int year,
    required int month,
  }) async {
    try {
      final response = await _apiClient.get(
        '/users/me/heatmap',
        queryParams: {'year': year, 'month': month},
      );
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return data.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (e) {
      throw Exception('Failed to fetch heatmap: $e');
    }
  }
}
