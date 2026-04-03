import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/core/network/api_exception.dart';
import 'package:watt_sense/feature/auth/models/user_model.dart';
import 'package:watt_sense/feature/auth/services/auth_service.dart';
import 'package:watt_sense/feature/dashboard/services/streak_local_service.dart';

/// Key used in SharedPreferences to persist onboarding status.
const String _kOnboardingCompleteKey = 'onboarding_complete';

class AuthRepository {
  final AuthService _authService;

  AuthRepository({AuthService? authService})
    : _authService = authService ?? AuthService();

  // ─── Streams ──────────────────────────────────────────────────────────────

  /// Emits a [UserModel] when signed in, or null when signed out.
  Stream<UserModel?> get authStateChanges async* {
    await for (final firebaseUser in _authService.authStateChanges) {
      if (firebaseUser == null) {
        yield null;
        continue;
      }

      // 1. Yield cached user immediately for instant offline-first UI
      final cachedUser = await _getCachedUser(firebaseUser);
      if (cachedUser != null) {
        yield cachedUser;
      }

      // 2. Fetch fresh user from network, update cache, and yield
      try {
        final freshUser = await _fetchAndCacheUser(firebaseUser);
        yield freshUser;
      } catch (e) {
        if (_isUnauthorizedError(e)) {
          await signOut();
          yield null;
          continue;
        }

        // If network fails, and we didn't have a cache, yield a basic user
        if (cachedUser == null) {
          yield UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
            isOnboardingComplete: await isOnboardingComplete(firebaseUser.uid),
          );
        }
      }
    }
  }

  /// Triggers a refresh of the user data by forcefully fetching it and returning it.
  /// This is used for pull-to-refresh without listening to auth state changes.
  Future<UserModel?> refreshUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    try {
      return await _fetchAndCacheUser(firebaseUser);
    } catch (e) {
      if (_isUnauthorizedError(e)) {
        await signOut();
        return null;
      }

      // Keep the app usable during transient backend failures.
      return await _getCachedUser(firebaseUser);
    }
  }

  Future<String?> currentUserId() async {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> writeProfileCacheForCurrentUser(
    Map<String, dynamic> profileData,
  ) async {
    final uid = await currentUserId();
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile_$uid', jsonEncode(profileData));

    final backendOnboarding = profileData['onboardingCompleted'] as bool?;
    if (backendOnboarding != null) {
      await prefs.setBool('${_kOnboardingCompleteKey}_$uid', backendOnboarding);
    }
  }

  Future<Map<String, dynamic>?> readProfileCacheForCurrentUser() async {
    final uid = await currentUserId();
    if (uid == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString('user_profile_$uid');
    if (profileStr == null) return null;

    try {
      return jsonDecode(profileStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<UserModel?> _getCachedUser(User firebaseUser) async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString('user_profile_${firebaseUser.uid}');
    final planStr = prefs.getString('active_plan_${firebaseUser.uid}');

    if (profileStr == null) return null; // No cache

    try {
      final userData = jsonDecode(profileStr);
      Map<String, dynamic>? activePlan;
      if (planStr != null) {
        activePlan = jsonDecode(planStr) as Map<String, dynamic>?;
      }

      final streak = (userData['streak'] as num?)?.toInt() ?? 0;
      final lastCheckInStr = userData['lastCheckIn'] as String?;
      DateTime? lastCheckIn;
      if (lastCheckInStr != null) {
        lastCheckIn = DateTime.tryParse(lastCheckInStr);
      }

      final isOnboarding =
          prefs.getBool('${_kOnboardingCompleteKey}_${firebaseUser.uid}') ??
          false;
      final profileName = (userData['name'] as String?)?.trim();
      final profileAvatar = (userData['avatarUrl'] as String?)?.trim();
      final effectiveDisplayName =
          (profileName != null && profileName.isNotEmpty)
          ? profileName
          : firebaseUser.displayName;
      final effectivePhotoUrl =
          (profileAvatar != null && profileAvatar.isNotEmpty)
          ? profileAvatar
          : firebaseUser.photoURL;

      return UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: effectiveDisplayName,
        photoUrl: effectivePhotoUrl,
        activePlan: activePlan,
        streak: streak,
        lastCheckIn: lastCheckIn,
        isOnboardingComplete: isOnboarding,
      );
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> _fetchAndCacheUser(User firebaseUser) async {
    final prefs = await SharedPreferences.getInstance();
    bool isOnboardingComplete =
        prefs.getBool('${_kOnboardingCompleteKey}_${firebaseUser.uid}') ??
        false;

    String? profileName;
    String? profileAvatar;
    Map<String, dynamic>? activePlan;
    int streak = 0;
    DateTime? lastCheckIn;

    // GET /users/me — profile summary
    final response = await ApiClient.instance.get('/users/me');
    if (response.statusCode == 200 && response.data['data'] != null) {
      final userData = response.data['data'];
      profileName = (userData['name'] as String?)?.trim();
      profileAvatar = (userData['avatarUrl'] as String?)?.trim();
      streak = (userData['streak'] as num?)?.toInt() ?? 0;
      final lastCheckInStr = userData['lastCheckIn'] as String?;
      if (lastCheckInStr != null) {
        lastCheckIn = DateTime.tryParse(lastCheckInStr);
      }

      // Backend is the source of truth for onboarding state
      final backendOnboarding = userData['onboardingCompleted'] as bool?;
      if (backendOnboarding != null) {
        isOnboardingComplete = backendOnboarding;
        await prefs.setBool(
          '${_kOnboardingCompleteKey}_${firebaseUser.uid}',
          backendOnboarding,
        );
      }

      // Update local profile cache
      await prefs.setString(
        'user_profile_${firebaseUser.uid}',
        jsonEncode(userData),
      );

      // Seed Hive streak cache
      final localService = StreakLocalService.instance;
      final cached = localService.read();
      if (cached == null || !cached.isFresh) {
        await localService.write(
          streak: streak,
          lastCheckIn: lastCheckIn,
          longestStreak: (userData['longestStreak'] as num?)?.toInt() ?? 0,
        );
      }

      // Fetch activePlan separately
      try {
        final planRes = await ApiClient.instance.get('/users/me/active-plan');
        if (planRes.statusCode == 200 && planRes.data['data'] != null) {
          activePlan = planRes.data['data'] as Map<String, dynamic>?;
          // Cache active plan
          await prefs.setString(
            'active_plan_${firebaseUser.uid}',
            jsonEncode(activePlan),
          );
        } else {
          // Clear plan cache if none on server
          await prefs.remove('active_plan_${firebaseUser.uid}');
        }
      } catch (_) {
        // Fallback to cache if plan fetch fails
        final cachedPlanStr = prefs.getString(
          'active_plan_${firebaseUser.uid}',
        );
        if (cachedPlanStr != null) {
          try {
            activePlan = jsonDecode(cachedPlanStr) as Map<String, dynamic>?;
          } catch (_) {}
        }
      }
    } else {
      // If profile fetch unsuccessful, throw to let the outer fallback handle it
      throw Exception('Failed to fetch user profile');
    }

    final effectiveDisplayName = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : firebaseUser.displayName;
    final effectivePhotoUrl =
        (profileAvatar != null && profileAvatar.isNotEmpty)
        ? profileAvatar
        : firebaseUser.photoURL;

    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: effectiveDisplayName,
      photoUrl: effectivePhotoUrl,
      activePlan: activePlan,
      streak: streak,
      lastCheckIn: lastCheckIn,
      isOnboardingComplete: isOnboardingComplete,
    );
  }

  // ─── Auth actions ─────────────────────────────────────────────────────────

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchAndCacheUser(credential.user!);
  }

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _authService.createUserWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    return _fetchAndCacheUser(credential.user!);
  }

  Future<UserModel?> signInWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    if (credential == null) return null;
    return _fetchAndCacheUser(credential.user!);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _authService.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    // Optional: Clear user cache on signout
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_${user.uid}');
      await prefs.remove('active_plan_${user.uid}');
    }
    await _authService.signOut();
  }

  // ─── Onboarding persistence ───────────────────────────────────────────────

  /// Call this after the user completes the onboarding flow.
  Future<void> markOnboardingComplete(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_kOnboardingCompleteKey}_$uid', true);

    // Best-effort: persist to backend so onboarding doesn't reappear on new installs
    try {
      await ApiClient.instance.put(
        '/users/me',
        data: {'onboardingCompleted': true},
      );
    } catch (_) {
      // If backend is down, the local flag still unblocks navigation.
    }
  }

  /// Check if the current user has completed onboarding.
  Future<bool> isOnboardingComplete(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_kOnboardingCompleteKey}_$uid') ?? false;
  }

  bool _isUnauthorizedError(Object error) {
    if (error is ApiException) {
      return error.isUnauthorised;
    }

    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return true;
      }
      final inner = error.error;
      if (inner is ApiException) {
        return inner.isUnauthorised;
      }
    }

    return false;
  }
}
