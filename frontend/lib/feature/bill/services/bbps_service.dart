import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';

class BbpsService {
  final ApiClient _apiClient;

  BbpsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Fetches bill details using Setu BBPS integration.
  ///
  /// Throws an [Exception] if the [billerId] or [consumerNumber] is invalid,
  /// or if there are any network/API issues.
  Future<Map<String, dynamic>> fetchBill({
    required String billerId,
    required String consumerNumber,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.bbpsFetchBill,
        data: {'billerId': billerId, 'consumerNumber': consumerNumber},
      );

      final responseData = response.data;

      // Since our API structurally returns { success: true, data: { ... } }
      if (responseData['success'] == true) {
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch bill data');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        final message = errorData is Map
            ? errorData['message']
            : 'Server error occurred';
        throw Exception(
          message ??
              'Failed to fetch bill. Status code: ${e.response?.statusCode}',
        );
      } else {
        throw Exception(
          'Network error occurred. Please check your internet connection.',
        );
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
