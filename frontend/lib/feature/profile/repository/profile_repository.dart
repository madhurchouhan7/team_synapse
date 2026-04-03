import 'package:dio/dio.dart';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/core/network/api_exception.dart';
import 'package:watt_sense/feature/auth/repository/auth_repository.dart';

abstract class IProfileRepository {
  Future<Map<String, dynamic>> fetchProfile({bool allowCacheFallback = true});

  Future<String> uploadAvatarFromFile({
    required String filePath,
    void Function(double progress)? onProgress,
  });

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String avatarUrl,
  });
}

class ProfileValidationException implements Exception {
  final String message;
  final Map<String, String> fieldErrors;

  const ProfileValidationException({
    required this.message,
    required this.fieldErrors,
  });

  @override
  String toString() => 'ProfileValidationException: $message';
}

class ProfileRequestException implements Exception {
  final String message;
  final bool isRetryable;

  const ProfileRequestException({
    required this.message,
    required this.isRetryable,
  });

  @override
  String toString() => 'ProfileRequestException: $message';
}

class ProfileRepository implements IProfileRepository {
  final AuthRepository? _authRepository;
  final Future<Map<String, dynamic>> Function()? _fetchProfileRequest;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)?
  _updateProfileRequest;
  final Future<void> Function(Map<String, dynamic> profile)? _cacheWriter;
  final Future<Map<String, dynamic>?> Function()? _cacheReader;

  ProfileRepository({
    AuthRepository? authRepository,
    Future<Map<String, dynamic>> Function()? fetchProfileRequest,
    Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)?
    updateProfileRequest,
    Future<void> Function(Map<String, dynamic> profile)? cacheWriter,
    Future<Map<String, dynamic>?> Function()? cacheReader,
  }) : _authRepository = authRepository,
       _fetchProfileRequest = fetchProfileRequest,
       _updateProfileRequest = updateProfileRequest,
       _cacheWriter = cacheWriter,
       _cacheReader = cacheReader;

  @override
  Future<Map<String, dynamic>> fetchProfile({
    bool allowCacheFallback = true,
  }) async {
    try {
      final profile = _normalizeProfile(
        _fetchProfileRequest != null
            ? await _fetchProfileRequest.call()
            : await _defaultFetchProfileRequest(),
      );
      await _writeProfileCache(profile);
      return profile;
    } catch (error) {
      if (allowCacheFallback) {
        final cached = await _readProfileCache();
        if (cached != null) {
          return _normalizeProfile(cached);
        }
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String avatarUrl,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'avatarUrl': avatarUrl.trim(),
    };

    try {
      final updated = _normalizeProfile(
        _updateProfileRequest != null
            ? await _updateProfileRequest.call(payload)
            : await _defaultUpdateProfileRequest(payload),
      );
      await _writeProfileCache(updated);
      return updated;
    } catch (error) {
      if (error is DioException && error.error is ApiException) {
        final apiError = error.error as ApiException;
        final fieldErrors = _extractFieldErrors(apiError.data);
        if (apiError.statusCode == 400 && fieldErrors.isNotEmpty) {
          throw ProfileValidationException(
            message: apiError.message,
            fieldErrors: fieldErrors,
          );
        }

        throw ProfileRequestException(
          message: apiError.message,
          isRetryable:
              apiError.isNetworkError ||
              apiError.isServerError ||
              apiError.statusCode == 409,
        );
      }

      if (error is ProfileValidationException ||
          error is ProfileRequestException) {
        rethrow;
      }

      throw const ProfileRequestException(
        message:
            'We could not update your profile right now. Check your connection, review highlighted fields, and try again.',
        isRetryable: true,
      );
    }
  }

  Future<Map<String, dynamic>> _defaultFetchProfileRequest() async {
    final response = await ApiClient.instance.get('/users/me');
    return _extractEnvelopeData(response.data);
  }

  Future<Map<String, dynamic>> _defaultUpdateProfileRequest(
    Map<String, dynamic> payload,
  ) async {
    final response = await ApiClient.instance.put('/users/me', data: payload);
    return _extractEnvelopeData(response.data);
  }

  @override
  Future<String> uploadAvatarFromFile({
    required String filePath,
    void Function(double progress)? onProgress,
  }) async {
    final authRepository = _authRepository ?? AuthRepository();
    final uid = await authRepository.currentUserId();
    if (uid == null) {
      throw const ProfileRequestException(
        message: 'Please sign in again to upload your avatar.',
        isRetryable: false,
      );
    }

    final extension = filePath.split('.').last.toLowerCase();
    final safeExt = extension.isEmpty ? 'jpg' : extension;
    final storagePath =
        'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    try {
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final task = ref.putFile(File(filePath));
      StreamSubscription<TaskSnapshot>? progressSub;
      if (onProgress != null) {
        progressSub = task.snapshotEvents.listen(
          (snapshot) {
            final total = snapshot.totalBytes;
            final transferred = snapshot.bytesTransferred;
            if (total <= 0) {
              return;
            }
            final progress = (transferred / total).clamp(0.0, 1.0);
            onProgress(progress);
          },
          onError: (_) {
            // Upload task errors are handled by await task below.
          },
          cancelOnError: false,
        );
      }

      try {
        await task;
      } finally {
        await progressSub?.cancel();
      }
      onProgress?.call(1.0);
      return await ref.getDownloadURL();
    } on PlatformException {
      throw const ProfileRequestException(
        message:
            'Upload service is not ready on this device session. Please restart the app and try again.',
        isRetryable: true,
      );
    } on FirebaseException {
      throw const ProfileRequestException(
        message:
            'We could not upload your avatar right now. Please check your connection and try again.',
        isRetryable: true,
      );
    }
  }

  Future<void> _writeProfileCache(Map<String, dynamic> profile) async {
    if (_cacheWriter != null) {
      await _cacheWriter.call(profile);
      return;
    }
    await (_authRepository ?? AuthRepository()).writeProfileCacheForCurrentUser(
      profile,
    );
  }

  Future<Map<String, dynamic>?> _readProfileCache() async {
    if (_cacheReader != null) {
      return _cacheReader.call();
    }
    return (_authRepository ?? AuthRepository())
        .readProfileCacheForCurrentUser();
  }

  Map<String, dynamic> _extractEnvelopeData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw const ProfileRequestException(
      message: 'Unexpected profile response from server.',
      isRetryable: false,
    );
  }

  Map<String, dynamic> _normalizeProfile(Map<String, dynamic> profile) {
    final normalized = <String, dynamic>{...profile};
    normalized['name'] = (profile['name'] ?? profile['displayName'] ?? '')
        .toString();
    normalized['avatarUrl'] =
        (profile['avatarUrl'] ?? profile['photoUrl'] ?? '').toString();
    return normalized;
  }

  Map<String, String> _extractFieldErrors(dynamic errorData) {
    final errors = <String, String>{};

    if (errorData is! Map<String, dynamic>) {
      return errors;
    }

    final details = errorData['details'];
    if (details is List) {
      for (final item in details) {
        if (item is Map<String, dynamic>) {
          final field = item['path']?.toString();
          final message = item['message']?.toString();
          if (field != null && message != null && field.isNotEmpty) {
            errors[field] = message;
          }
        }
      }
    }

    final envelopeErrors = errorData['errors'];
    if (envelopeErrors is List) {
      for (final item in envelopeErrors) {
        if (item is Map<String, dynamic>) {
          final field = item['field']?.toString();
          final message = item['message']?.toString();
          if (field != null && message != null && field.isNotEmpty) {
            errors[field] = message;
          }
        }
      }
    }

    return errors;
  }
}
