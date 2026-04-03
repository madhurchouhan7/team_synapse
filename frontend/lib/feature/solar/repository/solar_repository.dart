import 'package:dio/dio.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/core/network/api_exception.dart';
import 'package:watt_sense/feature/solar/models/solar_models.dart';

abstract class ISolarRepository {
  Future<SolarEstimateResult> estimate(SolarEstimateRequest request);
}

class SolarEstimateException implements Exception {
  const SolarEstimateException({
    required this.message,
    required this.statusCode,
    this.isRetryable = false,
  });

  final String message;
  final int statusCode;
  final bool isRetryable;

  @override
  String toString() => 'SolarEstimateException($statusCode): $message';
}

class SolarRepository implements ISolarRepository {
  SolarRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  @override
  Future<SolarEstimateResult> estimate(SolarEstimateRequest request) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/solar/estimate',
        data: request.toJson(),
      );
      final envelope = _extractEnvelope(response.data);
      final payload = _extractPayload(envelope);
      return SolarEstimateResult.fromJson(payload);
    } on DioException catch (error) {
      if (error.error is ApiException) {
        final apiError = error.error as ApiException;
        throw SolarEstimateException(
          message: apiError.message,
          statusCode: apiError.statusCode,
          isRetryable: apiError.statusCode == 429 || apiError.statusCode >= 500,
        );
      }

      throw const SolarEstimateException(
        message: 'Unable to calculate solar estimate right now.',
        statusCode: 500,
        isRetryable: true,
      );
    }
  }

  Map<String, dynamic> _extractEnvelope(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _extractPayload(Map<String, dynamic> envelope) {
    final nested = envelope['data'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }

    throw const SolarEstimateException(
      message: 'Unexpected solar response from server.',
      statusCode: 500,
      isRetryable: false,
    );
  }
}
