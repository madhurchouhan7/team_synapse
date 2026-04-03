// lib/core/network/api_exception.dart
// Strongly-typed exception that wraps all Dio / server errors.

import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  // ── Factory: convert a raw DioException ─────────────────────────────────
  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          statusCode: 408,
          message:
              'Connection timed out. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 500;
        final responseData = e.response?.data;

        // Try to extract a server-provided 'message' field
        String serverMessage =
            _extractMessage(responseData) ??
            _defaultMessageForStatus(statusCode);

        return ApiException(
          statusCode: statusCode,
          message: serverMessage,
          data: responseData,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          statusCode: 499,
          message: 'Request was cancelled.',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          statusCode: 503,
          message:
              'Could not reach the server. Make sure the backend is running.',
        );

      default:
        return ApiException(
          statusCode: 500,
          message: e.message ?? 'An unexpected error occurred.',
        );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    return null;
  }

  static String _defaultMessageForStatus(int code) {
    return switch (code) {
      400 => 'Bad request.',
      401 => 'Unauthorised. Please sign in again.',
      403 => 'You don\'t have permission to do that.',
      404 => 'Resource not found.',
      409 => 'Conflict — resource already exists.',
      422 => 'Unprocessable data.',
      429 => 'Too many requests. Slow down!',
      500 => 'Server error. Please try again later.',
      503 => 'Service unavailable.',
      _ => 'Something went wrong (HTTP $code).',
    };
  }

  bool get isUnauthorised => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
  bool get isNetworkError => statusCode == 503 || statusCode == 408;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
