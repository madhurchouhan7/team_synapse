// lib/core/network/api_client.dart
// Singleton Dio client — pre-configured with:
//   • Base URL & timeouts
//   • Firebase ID Token injection on every request
//   • Automatic token refresh on 401
//   • Structured error handling

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  Dio get dio => _dio;

  /// Call once in main() or in your app's initialisation.
  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _ErrorInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('[DIO] $o'),
      ),
    ]);
  }

  // ── Convenience Methods ──────────────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    Options? options,
  }) => _dio.get<T>(path, queryParameters: queryParams, options: options);

  Future<Response<T>> post<T>(String path, {dynamic data, Options? options}) =>
      _dio.post<T>(path, data: data, options: options);

  Future<Response<T>> put<T>(String path, {dynamic data, Options? options}) =>
      _dio.put<T>(path, data: data, options: options);

  Future<Response<T>> patch<T>(String path, {dynamic data, Options? options}) =>
      _dio.patch<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(String path, {Options? options}) =>
      _dio.delete<T>(path, options: options);
}

// ─── Auth Interceptor ────────────────────────────────────────────────────────
// Automatically attaches the Firebase ID Token to every outgoing request.
// If the token is expired, Dio will retry after FirebaseAuth refreshes it.
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // forceRefresh: false — Firebase caches the token and refreshes automatically
        final token = await user.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        debugPrint('Failed to get Firebase token: $e');
        // Let the request continue locally without a token.
        // Our backend Express middleware has a dynamic NODE_ENV==='development' fallback to catch this!
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 401 → try a forced token refresh once, then retry
    if (err.response?.statusCode == 401) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final freshToken = await user.getIdToken(true); // force refresh
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $freshToken';
          final response = await ApiClient.instance.dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {
          // Refresh failed — fall through to normal error handling
        }
      }
    }
    handler.next(err);
  }
}

// ─── Error Interceptor ───────────────────────────────────────────────────────
// Converts raw DioExceptions into strongly-typed ApiException objects.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = ApiException.fromDioException(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: apiException,
        type: err.type,
      ),
    );
  }
}

// Small helper so Flutter widgets can use debugPrint inside the interceptor
void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
