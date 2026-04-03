import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:watt_sense/core/network/api_client.dart';

final applianceRepositoryProvider = Provider<ApplianceRepository>((ref) {
  return ApplianceRepository(apiClient: ApiClient.instance);
});

class ApplianceRepository {
  final ApiClient _apiClient;

  ApplianceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static const String _ifMatchHeader = 'If-Match';

  Map<String, dynamic> _normalizeEnvelope(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  String? _extractExpectedVersionFromEnvelope(Map<String, dynamic> appliance) {
    final candidate =
        appliance['_expectedVersion'] ??
        appliance['expectedVersion'] ??
        appliance['version'] ??
        appliance['__v'];
    if (candidate == null) {
      return null;
    }
    return candidate.toString();
  }

  ApplianceMutationException _mapMutationError(Object error) {
    if (error is ApplianceMutationException) {
      return error;
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final envelope = _normalizeEnvelope(error.response?.data);
      final errorCode = envelope['errorCode']?.toString();
      final requestId = envelope['requestId']?.toString();
      final timestamp = envelope['timestamp']?.toString();
      final details = envelope['details'] is List
          ? (envelope['details'] as List).cast<dynamic>()
          : const <dynamic>[];

      final message = envelope['message']?.toString() ?? 'Mutation failed.';

      if (statusCode == 412 || errorCode == 'PRECONDITION_FAILED') {
        return ApplianceMutationException(
          type: ApplianceMutationErrorType.conflict,
          message: message,
          errorCode: errorCode,
          requestId: requestId,
          timestamp: timestamp,
          details: details,
        );
      }

      if (statusCode == 400 ||
          statusCode == 422 ||
          errorCode == 'VALIDATION_ERROR') {
        return ApplianceMutationException(
          type: ApplianceMutationErrorType.validation,
          message: message,
          errorCode: errorCode,
          requestId: requestId,
          timestamp: timestamp,
          details: details,
        );
      }

      if (statusCode == 408 ||
          statusCode == 429 ||
          (statusCode != null && statusCode >= 500)) {
        return ApplianceMutationException(
          type: ApplianceMutationErrorType.retryable,
          message: message,
          errorCode: errorCode,
          requestId: requestId,
          timestamp: timestamp,
          details: details,
        );
      }
    }

    return ApplianceMutationException(
      type: ApplianceMutationErrorType.unknown,
      message: error.toString(),
    );
  }

  Future<void> saveAppliances(List<Map<String, dynamic>> appliances) async {
    try {
      // Map UI category labels to strict backend MongoDB Enums
      final mappedAppliances = appliances.map((app) {
        final Map<String, dynamic> modifiedApp = Map.from(app);
        switch (modifiedApp['category'].toString().toUpperCase()) {
          case 'COOLING':
            modifiedApp['category'] = 'cooling';
            break;
          case 'HEATING':
            modifiedApp['category'] = 'heating';
            break;
          case 'LIGHTING':
            modifiedApp['category'] = 'lighting';
            break;
          case 'KITCHEN':
          case 'ALWAYS ON': // Refrigerator mapping
            modifiedApp['category'] = 'kitchen';
            break;
          case 'LAUNDRY':
          case 'OCCASIONAL USE': // Washing Machine mapping
            modifiedApp['category'] = 'laundry';
            break;
          case 'COMPUTING':
            modifiedApp['category'] = 'computing';
            break;
          case 'ENTERTAINMENT':
            modifiedApp['category'] = 'entertainment';
            break;
          case 'CHARGING':
            modifiedApp['category'] = 'charging';
            break;
          case 'CLEANING':
            modifiedApp['category'] = 'cleaning';
            break;
          default:
            // Ensures safety fallback for backend validation if new UI categories are added later
            modifiedApp['category'] = 'other';
        }
        return modifiedApp;
      }).toList();

      await _apiClient.post(
        '/appliances/bulk',
        data: {'appliances': mappedAppliances},
      );
    } catch (e) {
      throw Exception('Failed to save appliances: $e');
    }
  }

  Future<Map<String, dynamic>> createAppliance({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _apiClient.post('/appliances', data: payload);
      return _normalizeEnvelope(response.data);
    } catch (error) {
      throw _mapMutationError(error);
    }
  }

  Future<Map<String, dynamic>> updateAppliance({
    required String applianceId,
    required Map<String, dynamic> payload,
    String? expectedVersion,
  }) async {
    final resolvedVersion =
        expectedVersion ?? _extractExpectedVersionFromEnvelope(payload);

    final requestPayload = Map<String, dynamic>.from(payload);
    if (resolvedVersion != null && resolvedVersion.isNotEmpty) {
      requestPayload['_expectedVersion'] = resolvedVersion;
    }

    try {
      final response = await _apiClient.patch(
        '/appliances/$applianceId',
        data: requestPayload,
        options: Options(
          headers: resolvedVersion == null
              ? null
              : <String, dynamic>{_ifMatchHeader: resolvedVersion},
        ),
      );
      return _normalizeEnvelope(response.data);
    } catch (error) {
      throw _mapMutationError(error);
    }
  }

  Future<Map<String, dynamic>> deleteAppliance({
    required String applianceId,
    String? expectedVersion,
  }) async {
    final requestPayload = <String, dynamic>{};
    if (expectedVersion != null && expectedVersion.isNotEmpty) {
      requestPayload['_expectedVersion'] = expectedVersion;
    }

    try {
      final response = await _apiClient.dio.delete(
        '/appliances/$applianceId',
        data: requestPayload.isEmpty ? null : requestPayload,
        options: Options(
          headers: expectedVersion == null
              ? null
              : <String, dynamic>{_ifMatchHeader: expectedVersion},
        ),
      );
      return _normalizeEnvelope(response.data);
    } catch (error) {
      throw _mapMutationError(error);
    }
  }

  Future<List<Map<String, dynamic>>> getAppliances() async {
    try {
      // Use the dedicated appliances endpoint, not the user profile
      final response = await _apiClient.get('/appliances');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final appliancesList = response.data['data'] as List<dynamic>;
        return List<Map<String, dynamic>>.from(appliancesList);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch appliances: $e');
    }
  }
}

enum ApplianceMutationErrorType { validation, conflict, retryable, unknown }

class ApplianceMutationException implements Exception {
  final ApplianceMutationErrorType type;
  final String message;
  final String? errorCode;
  final String? requestId;
  final String? timestamp;
  final List<dynamic> details;

  ApplianceMutationException({
    required this.type,
    required this.message,
    this.errorCode,
    this.requestId,
    this.timestamp,
    this.details = const <dynamic>[],
  });

  @override
  String toString() {
    return message;
  }
}
