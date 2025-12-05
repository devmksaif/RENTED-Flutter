import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class ReviewService {
  final StorageService _storageService = StorageService();

  /// Get all reviews for a product
  Future<List<Map<String, dynamic>>> getProductReviews(int productId) async {
    final url = '${ApiConfig.productReviews}/$productId/reviews';
    
    try {
      AppLogger.apiRequest('GET', url);
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final reviews = List<Map<String, dynamic>>.from(responseData['data'] ?? []);
        AppLogger.i('✅ Retrieved ${reviews.length} reviews for product $productId');
        return reviews;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getProductReviews', e);
      AppLogger.e('Failed to get product reviews', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get product rating statistics
  Future<Map<String, dynamic>> getProductRating(int productId) async {
    final url = '${ApiConfig.productRating}/$productId/rating';
    
    try {
      AppLogger.apiRequest('GET', url);
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final rating = {
          'average_rating': responseData['average_rating'] ?? 0.0,
          'review_count': responseData['review_count'] ?? 0,
        };
        AppLogger.i('✅ Retrieved rating for product $productId: ${rating['average_rating']} (${rating['review_count']} reviews)');
        return rating;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getProductRating', e);
      AppLogger.e('Failed to get product rating', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get user's reviews
  Future<List<Map<String, dynamic>>> getUserReviews() async {
    final url = ApiConfig.userReviews;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('getUserReviews', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('GET', url, headers: ApiConfig.getAuthHeaders(token));
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final reviews = List<Map<String, dynamic>>.from(responseData['data'] ?? []);
        AppLogger.i('✅ Retrieved ${reviews.length} user reviews');
        return reviews;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getUserReviews', e);
      AppLogger.e('Failed to get user reviews', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Create a review
  Future<Map<String, dynamic>> createReview({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    final url = ApiConfig.reviews;
    final body = {
      'product_id': productId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('createReview', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      // Validate rating
      if (rating < 1 || rating > 5) {
        AppLogger.validationError('rating', 'Rating must be between 1 and 5');
        throw ApiError(
          message: 'Rating must be between 1 and 5',
          statusCode: 400,
        );
      }

      AppLogger.apiRequest('POST', url, body: body, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('📝 Creating review for product $productId with rating $rating');
      
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
        final review = responseData['data'] ?? responseData;
        AppLogger.i('✅ Review created successfully: ID ${review['id']}');
        return review;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('createReview', e);
      AppLogger.e('Failed to create review', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Update a review
  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    int? rating,
    String? comment,
  }) async {
    final url = '${ApiConfig.reviews}/$reviewId';
    final body = <String, dynamic>{};
    if (rating != null) {
      if (rating < 1 || rating > 5) {
        AppLogger.validationError('rating', 'Rating must be between 1 and 5');
        throw ApiError(
          message: 'Rating must be between 1 and 5',
          statusCode: 400,
        );
      }
      body['rating'] = rating;
    }
    if (comment != null) body['comment'] = comment;

    if (body.isEmpty) {
      AppLogger.w('⚠️ Update review called with no changes');
      throw ApiError(
        message: 'No changes provided to update',
        statusCode: 400,
      );
    }
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('updateReview', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('PUT', url, body: body, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('✏️ Updating review $reviewId');
      
      final response = await http
          .put(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final review = responseData['data'] ?? responseData;
        AppLogger.i('✅ Review updated successfully: ID $reviewId');
        return review;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('updateReview', e);
      AppLogger.e('Failed to update review', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Delete a review
  Future<void> deleteReview(int reviewId) async {
    final url = '${ApiConfig.reviews}/$reviewId';
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('deleteReview', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('DELETE', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('🗑️ Deleting review $reviewId');
      
      final response = await http
          .delete(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      AppLogger.apiResponse(response.statusCode, url);

      if (response.statusCode == 204 || response.statusCode == 200) {
        AppLogger.i('✅ Review deleted successfully: ID $reviewId');
        return;
      } else {
        final responseData = jsonDecode(response.body);
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('deleteReview', e);
      AppLogger.e('Failed to delete review', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}

