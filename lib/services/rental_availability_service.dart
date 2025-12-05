import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import 'storage_service.dart';

class RentalAvailabilityService {
  final StorageService _storageService = StorageService();

  /// Get product availability calendar
  Future<Map<String, dynamic>> getProductAvailability(
    int productId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.productAvailability}/$productId/availability');
      final uriWithParams = startDate != null || endDate != null
          ? uri.replace(queryParameters: {
              if (startDate != null) 'start_date': startDate,
              if (endDate != null) 'end_date': endDate,
            })
          : uri;

      final response = await http
          .get(
            uriWithParams,
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
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
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.checkAvailability}/$productId/check-availability'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'start_date': startDate,
              'end_date': endDate,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
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
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final body = <String, dynamic>{
        'dates': dates,
      };

      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.blockDates}/$productId/block-dates'),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseData;
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}

