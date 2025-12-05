import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class RentalAvailabilityService {
  final StorageService _storageService = StorageService();

  /// Get product availability calendar
  Future<Map<String, dynamic>> getProductAvailability(
    int productId, {
    String? startDate,
    String? endDate,
  }) async {
    final uri = Uri.parse('${ApiConfig.productAvailability}/$productId/availability');
    final uriWithParams = startDate != null || endDate != null
        ? uri.replace(queryParameters: {
            if (startDate != null) 'start_date': startDate,
            if (endDate != null) 'end_date': endDate,
          })
        : uri;
    final url = uriWithParams.toString();
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('📅 Fetching availability for product $productId');

      final response = await http
          .get(
            uriWithParams,
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        AppLogger.i('✅ Availability retrieved');
        return responseData;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getProductAvailability', e);
      AppLogger.e('Failed to fetch availability', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Check if product is available for specific dates
  Future<Map<String, dynamic>> checkAvailability({
    required int productId,
    required String startDate,
    required String endDate,
  }) async {
    final url = '${ApiConfig.checkAvailability}/$productId/check-availability';
    try {
      AppLogger.apiRequest('POST', url, body: {'start_date': startDate, 'end_date': endDate});
      AppLogger.i('📅 Checking availability for product $productId from $startDate to $endDate');

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'start_date': startDate,
              'end_date': endDate,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        AppLogger.i('✅ Availability check completed');
        return responseData;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('checkAvailability', e);
      AppLogger.e('Failed to check availability', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Block dates for maintenance (product owner only)
  Future<Map<String, dynamic>> blockDatesForMaintenance({
    required int productId,
    required List<String> dates,
    String? notes,
  }) async {
    final url = '${ApiConfig.blockDates}/$productId/block-dates';
    try {
      final body = <String, dynamic>{
        'dates': dates,
      };

      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      AppLogger.apiRequest('POST', url, body: body);
      AppLogger.i('📅 Blocking dates for product $productId');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 201) {
        AppLogger.i('✅ Dates blocked successfully');
        return responseData;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('blockDatesForMaintenance', e);
      AppLogger.e('Failed to block dates', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}

