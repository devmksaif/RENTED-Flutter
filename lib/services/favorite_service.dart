import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import '../models/product.dart';
import 'storage_service.dart';

class FavoriteService {
  final StorageService _storageService = StorageService();

  /// Get user's favorite products
  /// API: GET /favourites
  Future<List<Product>> getFavorites() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Authentication required', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.favourites),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> data = responseData['data'] ?? [];
        // API returns favourites with nested product object
        return data.map((json) {
          // Handle both direct product and nested product structure
          if (json['product'] != null) {
            return Product.fromJson(json['product']);
          }
          return Product.fromJson(json);
        }).toList();
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: 'Failed to load favorites', statusCode: 0);
    }
  }

  /// Toggle favorite status (add or remove)
  /// API: POST /favourites/toggle
  /// Returns: { "favourited": true/false, "message": "..." }
  Future<bool> toggleFavorite(int productId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Authentication required', statusCode: 401);
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.favouritesToggle),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({'product_id': productId}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // API returns { "favourited": true/false, "message": "..." }
        return responseData['favourited'] ?? false;
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
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
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Authentication required', statusCode: 401);
      }

      final response = await http
          .delete(
            Uri.parse('${ApiConfig.favourites}/$productId'),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        final responseData = jsonDecode(response.body);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: 'Failed to remove from favorites', statusCode: 0);
    }
  }
}
