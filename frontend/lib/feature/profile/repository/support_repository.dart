import 'package:dio/dio.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/core/network/api_exception.dart';
import 'package:watt_sense/feature/profile/models/contact_support_models.dart';

abstract class ISupportRepository {
  Future<ContactSupportTicketResult> submitTicket(
    ContactSupportTicketRequest request,
  );
}

class SupportSubmissionException implements Exception {
  const SupportSubmissionException({
    required this.message,
    required this.statusCode,
    this.errorCode,
    this.retryAfterSeconds,
    this.requestId,
    this.timestamp,
    this.isRetryable = false,
  });

  final String message;
  final int statusCode;
  final String? errorCode;
  final int? retryAfterSeconds;
  final String? requestId;
  final String? timestamp;
  final bool isRetryable;

  @override
  String toString() => 'SupportSubmissionException($statusCode): $message';
}

class SupportRepository implements ISupportRepository {
  SupportRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  static const String _supportPath = '/support/tickets';

  @override
  Future<ContactSupportTicketResult> submitTicket(
    ContactSupportTicketRequest request,
  ) async {
    try {
      final response = await _apiClient.post<dynamic>(
        _supportPath,
        data: request.toJson(),
      );
      final envelope = _extractEnvelope(response.data);
      final payload = _extractPayload(envelope);
      return ContactSupportTicketResult.fromJson(payload);
    } on DioException catch (error) {
      final apiError = error.error;
      if (apiError is ApiException) {
        final envelope = _extractEnvelope(apiError.data);
        final statusCode = apiError.statusCode;
        final errorCode = envelope['errorCode']?.toString();
        final retryAfterSeconds = _extractRetryAfterSeconds(
          error.response?.headers,
          envelope,
        );

        throw SupportSubmissionException(
          message: apiError.message,
          statusCode: statusCode,
          errorCode: errorCode,
          retryAfterSeconds: retryAfterSeconds,
          requestId: envelope['requestId']?.toString(),
          timestamp: envelope['timestamp']?.toString(),
          isRetryable: _isRetryable(statusCode, errorCode),
        );
      }

      throw const SupportSubmissionException(
        message: 'Unable to submit support request right now. Please retry.',
        statusCode: 500,
        isRetryable: true,
      );
    }
  }

  bool _isRetryable(int statusCode, String? errorCode) {
    if (statusCode == 429 || statusCode == 503 || statusCode >= 500) {
      return true;
    }

    return (errorCode ?? '').toUpperCase() == 'TEMPORARY_UNAVAILABLE';
  }

  int? _extractRetryAfterSeconds(
    Headers? headers,
    Map<String, dynamic> envelope,
  ) {
    final headerValue = headers?.map['retry-after']?.first;
    final fromHeader = int.tryParse(headerValue ?? '');
    if (fromHeader != null) {
      return fromHeader;
    }

    final fromEnvelope = envelope['retryAfterSeconds'];
    if (fromEnvelope is int) {
      return fromEnvelope;
    }

    return int.tryParse(fromEnvelope?.toString() ?? '');
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

    throw const SupportSubmissionException(
      message: 'Unexpected support response from server.',
      statusCode: 500,
      isRetryable: false,
    );
  }
}
