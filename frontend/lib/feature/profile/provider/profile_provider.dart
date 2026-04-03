import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/profile/repository/profile_repository.dart';

enum ProfileOperationStatus { idle, saving, saveError, saveSuccess }

class ProfileDraft {
  final String name;
  final String avatarUrl;

  const ProfileDraft({this.name = '', this.avatarUrl = ''});

  ProfileDraft copyWith({String? name, String? avatarUrl}) {
    return ProfileDraft(
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class ProfileOperationState {
  final ProfileOperationStatus status;
  final String? message;
  final Map<String, String> fieldErrors;

  const ProfileOperationState({
    this.status = ProfileOperationStatus.idle,
    this.message,
    this.fieldErrors = const {},
  });

  bool get isSaving => status == ProfileOperationStatus.saving;
  bool get hasSaveError => status == ProfileOperationStatus.saveError;
  bool get hasSaveSuccess => status == ProfileOperationStatus.saveSuccess;
}

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  return ProfileRepository(authRepository: ref.watch(authRepositoryProvider));
});

final profileDraftProvider = StateProvider<ProfileDraft>((ref) {
  return const ProfileDraft();
});

final profileOperationProvider = StateProvider<ProfileOperationState>((ref) {
  return const ProfileOperationState();
});

final avatarUploadProgressProvider = StateProvider<double?>((ref) {
  return null;
});

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Map<String, dynamic>>(
      ProfileNotifier.new,
    );

class ProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  FutureOr<Map<String, dynamic>> build() async {
    final repository = ref.read(profileRepositoryProvider);
    final profile = await repository.fetchProfile();
    _hydrateDraft(profile);
    return profile;
  }

  void setDraftName(String value) {
    final current = ref.read(profileDraftProvider);
    ref.read(profileDraftProvider.notifier).state = current.copyWith(
      name: value,
    );
  }

  void setDraftAvatarUrl(String value) {
    final current = ref.read(profileDraftProvider);
    ref.read(profileDraftProvider.notifier).state = current.copyWith(
      avatarUrl: value,
    );
  }

  Future<void> retryFetch() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileRepositoryProvider).fetchProfile();
      _hydrateDraft(profile);
      return profile;
    });
  }

  Future<void> uploadAvatarFile(String filePath) async {
    ref.read(avatarUploadProgressProvider.notifier).state = 0.0;
    ref.read(profileOperationProvider.notifier).state =
        const ProfileOperationState();

    try {
      final uploadedUrl = await ref
          .read(profileRepositoryProvider)
          .uploadAvatarFromFile(
            filePath: filePath,
            onProgress: (progress) {
              ref.read(avatarUploadProgressProvider.notifier).state = progress;
            },
          );
      setDraftAvatarUrl(uploadedUrl);
      ref.read(avatarUploadProgressProvider.notifier).state = null;
      ref.read(profileOperationProvider.notifier).state =
          const ProfileOperationState();
    } on ProfileRequestException catch (error) {
      ref.read(avatarUploadProgressProvider.notifier).state = null;
      ref.read(profileOperationProvider.notifier).state = ProfileOperationState(
        status: ProfileOperationStatus.saveError,
        message: error.message,
      );
    } catch (_) {
      ref.read(avatarUploadProgressProvider.notifier).state = null;
      ref
          .read(profileOperationProvider.notifier)
          .state = const ProfileOperationState(
        status: ProfileOperationStatus.saveError,
        message:
            'We could not upload your avatar right now. Please check your connection and try again.',
      );
    }
  }

  Future<void> saveProfile() async {
    final previous = state.valueOrNull;
    final draft = ref.read(profileDraftProvider);
    ref.read(profileOperationProvider.notifier).state =
        const ProfileOperationState(status: ProfileOperationStatus.saving);

    try {
      final updated = await ref
          .read(profileRepositoryProvider)
          .updateProfile(name: draft.name, avatarUrl: draft.avatarUrl);

      // Keep auth-backed UI (dashboard/profile header) in sync with edits.
      try {
        await ref.read(authRepositoryProvider).refreshUserData();
      } catch (_) {
        // Save already succeeded and profile cache is updated.
      }
      ref.invalidate(authStateProvider);

      _hydrateDraft(updated);
      state = AsyncData(updated);
      ref
          .read(profileOperationProvider.notifier)
          .state = const ProfileOperationState(
        status: ProfileOperationStatus.saveSuccess,
        message: 'Profile updated successfully.',
      );
    } on ProfileValidationException catch (error) {
      if (previous != null) {
        state = AsyncData(previous);
      }
      ref.read(profileOperationProvider.notifier).state = ProfileOperationState(
        status: ProfileOperationStatus.saveError,
        message: error.message,
        fieldErrors: error.fieldErrors,
      );
    } on ProfileRequestException catch (error) {
      if (previous != null) {
        state = AsyncData(previous);
      }
      ref.read(profileOperationProvider.notifier).state = ProfileOperationState(
        status: ProfileOperationStatus.saveError,
        message: error.message,
      );
    } catch (_) {
      if (previous != null) {
        state = AsyncData(previous);
      }
      ref
          .read(profileOperationProvider.notifier)
          .state = const ProfileOperationState(
        status: ProfileOperationStatus.saveError,
        message:
            'We could not update your profile right now. Check your connection, review highlighted fields, and try again.',
      );
    }
  }

  Future<void> retrySave() async {
    await saveProfile();
  }

  void clearOperationFeedback() {
    ref.read(profileOperationProvider.notifier).state =
        const ProfileOperationState();
  }

  void _hydrateDraft(Map<String, dynamic> profile) {
    ref.read(profileDraftProvider.notifier).state = ProfileDraft(
      name: (profile['name'] ?? '').toString(),
      avatarUrl: (profile['avatarUrl'] ?? '').toString(),
    );
  }
}
