import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import '../models/product.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class FavoriteService {
  final StorageService _storageService = StorageService();

  /// Get user's favorite products
  /// API: GET /favourites
  Future<List<Product>> getFavorites() async {
    final url = ApiConfig.favourites;
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('❤️ Fetching favorites');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Authentication required');
        throw ApiError(message: 'Authentication required', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final List<dynamic> data = responseData['data'] ?? [];
        AppLogger.d('📦 Raw favorites data count: ${data.length}');
        
        // API returns favourites with nested product object
        final products = <Product>[];
        
        for (var item in data) {
          try {
            Map<String, dynamic> productJson;
            
            // Handle different response structures
            if (item is Map && item.containsKey('product')) {
              final productValue = item['product'];
              
              // Product might be a Map or a JSON string
              if (productValue is String) {
                // Parse JSON string
                AppLogger.d('📦 Product is a JSON string, parsing...');
                productJson = jsonDecode(productValue) as Map<String, dynamic>;
              } else if (productValue is Map) {
                // Already a Map
                productJson = productValue as Map<String, dynamic>;
              } else {
                AppLogger.w('⚠️ Unexpected product type: ${productValue.runtimeType}');
                AppLogger.d('📦 Item structure: $item');
                continue; // Skip this item
              }
            } else if (item is Map<String, dynamic>) {
              // Direct product structure
              productJson = item;
            } else {
              AppLogger.w('⚠️ Unexpected item type: ${item.runtimeType}');
              AppLogger.d('📦 Item: $item');
              continue; // Skip this item
            }
            
            products.add(Product.fromJson(productJson));
          } catch (e, stackTrace) {
            AppLogger.e('Failed to parse product from favorites', e, stackTrace);
            AppLogger.d('📦 Item data: $item');
            // Continue with next item instead of failing completely
            continue;
          }
        }
        
        AppLogger.i('✅ Retrieved ${products.length} favorites (${data.length} total items)');
        return products;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getFavorites', e);
      AppLogger.e('Failed to load favorites', e, stackTrace);
      throw ApiError(message: 'Failed to load favorites', statusCode: 0);
    }
  }

  /// Toggle favorite status (add or remove)
  /// API: POST /favourites/toggle
  /// Returns: { "favourited": true/false, "message": "..." }
  Future<bool> toggleFavorite(int productId) async {
    final url = ApiConfig.favouritesToggle;
    try {
      AppLogger.apiRequest('POST', url, body: {'product_id': productId});
      AppLogger.i('❤️ Toggling favorite for product $productId');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Authentication required');
        throw ApiError(message: 'Authentication required', statusCode: 401);
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({'product_id': productId}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        // API returns { "favourited": true/false, "message": "..." }
        final favourited = responseData['favourited'] ?? false;
        AppLogger.i('✅ Favorite toggled: $favourited');
        return favourited;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('toggleFavorite', e);
      AppLogger.e('Failed to toggle favorite', e, stackTrace);
      throw ApiError(message: 'Failed to toggle favorite', statusCode: 0);
    }
  }

  /// Check if product is in favorites
  /// API: GET /favourites/check/{productId}
  /// Returns: { "favourited": true/false }
  Future<bool> isFavorite(int productId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return false;
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.favourites}/check/$productId'),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData['favourited'] ?? false;
      } else {
        // If check fails, return false
        return false;
      }
    } catch (e) {
      // Return false on error
      return false;
    }
  }

  /// Remove product from favorites (alternative to toggle)
  /// API: DELETE /favourites/{productId}
  Future<void> removeFromFavorites(int productId) async {
    final url = '${ApiConfig.favourites}/$productId';
    try {
      AppLogger.apiRequest('DELETE', url);
      AppLogger.i('❤️ Removing product $productId from favorites');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Authentication required');
        throw ApiError(message: 'Authentication required', statusCode: 401);
      }

      final response = await http
          .delete(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode != 200 && response.statusCode != 204) {
        AppLogger.apiError(url, response.statusCode, responseData?['message'] ?? 'Unknown error', errors: responseData?['errors']);
        throw ApiError.fromJson(responseData ?? {}, response.statusCode);
      }
      AppLogger.i('✅ Product removed from favorites');
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('removeFromFavorites', e);
      AppLogger.e('Failed to remove from favorites', e, stackTrace);
      throw ApiError(message: 'Failed to remove from favorites', statusCode: 0);
    }
  }
}
