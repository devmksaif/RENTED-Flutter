import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/rental.dart';
import '../models/api_error.dart';
import 'storage_service.dart';

class RentalService {
  final StorageService _storageService = StorageService();

  /// Create a rental request
  Future<Rental> createRental({
    required int productId,
    required String startDate,
    required String endDate,
    String? notes,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.rentals),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({
              'product_id': productId,
              'start_date': startDate,
              'end_date': endDate,
              if (notes != null) 'notes': notes,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return Rental.fromJson(responseData['data']);
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

  /// Get user's rentals
  Future<List<Rental>> getUserRentals() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.userRentals),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> rentalsJson = responseData['data'];
        return rentalsJson.map((json) => Rental.fromJson(json)).toList();
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

  /// Get rentals for a specific product
  Future<List<Rental>> getProductRentals(int productId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.products}/$productId/rentals'),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> rentalsJson = responseData['data'];
        return rentalsJson.map((json) => Rental.fromJson(json)).toList();
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

  /// Update rental status (product owner only)
  Future<Rental> updateRentalStatus({
    required int rentalId,
    required String status,
    String? notes,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.rentals}/$rentalId'),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({
              'status': status,
              if (notes != null) 'notes': notes,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Rental.fromJson(responseData['data']);
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
