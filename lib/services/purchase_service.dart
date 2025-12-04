import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/purchase.dart';
import '../models/api_error.dart';
import 'storage_service.dart';

class PurchaseService {
  final StorageService _storageService = StorageService();

  /// Create a purchase request
  Future<Purchase> createPurchase({
    required int productId,
    String? notes,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.purchases),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({
              'product_id': productId,
              if (notes != null) 'notes': notes,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return Purchase.fromJson(responseData['data']);
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

  /// Get user's purchases
  Future<List<Purchase>> getUserPurchases() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.userPurchases),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> purchasesJson = responseData['data'];
        return purchasesJson.map((json) => Purchase.fromJson(json)).toList();
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

  /// Complete purchase (product owner only)
  Future<Purchase> completePurchase(int purchaseId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.purchases}/$purchaseId/complete'),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Purchase.fromJson(responseData['data']);
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

  /// Cancel purchase (product owner or buyer)
  Future<Purchase> cancelPurchase(int purchaseId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.purchases}/$purchaseId/cancel'),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Purchase.fromJson(responseData['data']);
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
