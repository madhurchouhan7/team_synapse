import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/auth/models/user_model.dart';
import 'package:watt_sense/feature/auth/repository/auth_repository.dart';
import 'package:watt_sense/feature/auth/services/auth_service.dart';

// ─── Service & Repository Providers ──────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(authService: ref.read(authServiceProvider));
});

// ─── Auth State Stream Provider ───────────────────────────────────────────────
// Emits UserModel? whenever the auth state changes.
// null = signed out, UserModel = signed in.

final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ─── Auth Notifier (for handling sign-in / sign-up actions) ──────────────────

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({this.status = AuthStatus.idle, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.signInWithEmailAndPassword(email: email, password: password);
      state = const AuthState(status: AuthStatus.success);
      return true;
    } on Exception catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _friendlyError(e.toString()),
      );
      return false;
    }
  }

  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = const AuthState(status: AuthStatus.success);
      return true;
    } on Exception catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _friendlyError(e.toString()),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _repo.signInWithGoogle();
      if (user == null) {
        state = const AuthState(status: AuthStatus.idle);
        return false;
      }
      state = const AuthState(status: AuthStatus.success);
      return true;
    } on Exception catch (e) {
      print("Google SignIn Exception: $e");
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _friendlyError(e.toString()),
      );
      return false;
    }
  }

  Future<void> sendPasswordReset({required String email}) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.sendPasswordResetEmail(email: email);
      state = const AuthState(status: AuthStatus.success);
    } on Exception catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _friendlyError(e.toString()),
      );
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  /// Mark that the current user has completed onboarding.
  Future<void> markOnboardingComplete(String uid) async {
    await _repo.markOnboardingComplete(uid);
  }

  void resetState() {
    state = const AuthState(status: AuthStatus.idle);
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (raw.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('weak-password')) {
      return 'Password should be at least 6 characters.';
    }
    if (raw.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (raw.contains('network-request-failed')) {
      return 'No internet connection. Please try again.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    if (raw.contains('invalid-credential')) {
      return 'Invalid credentials. Please check and try again.';
    }
    if (raw.contains('sign_in_failed') || raw.contains('ApiException: 10')) {
      return 'Google Sign-In misconfigured. Please update google-services.json.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
