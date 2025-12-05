import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/purchase.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class PurchaseService {
  final StorageService _storageService = StorageService();

  /// Create a purchase request
  Future<Purchase> createPurchase({
    required int productId,
    String? notes,
  }) async {
    final url = ApiConfig.purchases;
    final body = {
      'product_id': productId,
      if (notes != null) 'notes': notes,
    };
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('createPurchase', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('POST', url, body: body, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('🛒 Creating purchase for product $productId');

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
        final purchase = Purchase.fromJson(responseData['data']);
        AppLogger.i('✅ Purchase created successfully: ID ${purchase.id}');
        return purchase;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('createPurchase', e);
      AppLogger.e('Failed to create purchase', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get user's purchases
  Future<List<Purchase>> getUserPurchases() async {
    final url = ApiConfig.userPurchases;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('getUserPurchases', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('GET', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('🛒 Fetching user purchases');

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final List<dynamic> purchasesJson = responseData['data'];
        final purchases = purchasesJson.map((json) => Purchase.fromJson(json)).toList();
        AppLogger.i('✅ Retrieved ${purchases.length} user purchases');
        return purchases;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getUserPurchases', e);
      AppLogger.e('Failed to load user purchases', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Complete purchase (product owner only)
  Future<Purchase> completePurchase(int purchaseId) async {
    final url = '${ApiConfig.purchases}/$purchaseId/complete';
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('completePurchase', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('PUT', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('✅ Completing purchase $purchaseId');

      final response = await http
          .put(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final purchase = Purchase.fromJson(responseData['data']);
        AppLogger.i('✅ Purchase completed successfully: ID $purchaseId');
        return purchase;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('completePurchase', e);
      AppLogger.e('Failed to complete purchase', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Cancel purchase (product owner or buyer)
  Future<Purchase> cancelPurchase(int purchaseId) async {
    final url = '${ApiConfig.purchases}/$purchaseId/cancel';
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('cancelPurchase', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('PUT', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('❌ Cancelling purchase $purchaseId');

      final response = await http
          .put(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final purchase = Purchase.fromJson(responseData['data']);
        AppLogger.i('✅ Purchase cancelled successfully: ID $purchaseId');
        return purchase;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('cancelPurchase', e);
      AppLogger.e('Failed to cancel purchase', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}
