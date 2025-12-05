import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class OfferService {
  final StorageService _storageService = StorageService();

  /// Create a new offer in a conversation
  /// API: POST /conversations/{conversationId}/offers
  Future<Map<String, dynamic>> createOffer({
    required int conversationId,
    required int productId,
    required double amount,
    String? message,
    String? offerType, // 'rental' or 'purchase'
    String? startDate, // For rental offers
    String? endDate, // For rental offers
  }) async {
    final url = '${ApiConfig.conversations}/$conversationId/offers';
    final body = <String, dynamic>{
      'product_id': productId,
      'amount': amount,
      if (message != null && message.isNotEmpty) 'message': message,
      if (offerType != null) 'offer_type': offerType,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('createOffer', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('POST', url, body: body, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('💰 Creating offer: \$$amount for conversation $conversationId');

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
        final offer = responseData['data'] ?? responseData;
        AppLogger.i('✅ Offer created successfully: ID ${offer['id']}');
        return offer;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('createOffer', e);
      AppLogger.e('Failed to create offer', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Accept an offer
  /// API: POST /conversations/{conversationId}/offers/{offerId}/accept
  Future<Map<String, dynamic>> acceptOffer({
    required int conversationId,
    required int offerId,
  }) async {
    final url = '${ApiConfig.conversations}/$conversationId/offers/$offerId/accept';

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('acceptOffer', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('POST', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('✅ Accepting offer $offerId');

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final result = responseData['data'] ?? responseData;
        AppLogger.i('✅ Offer accepted successfully');
        return result;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('acceptOffer', e);
      AppLogger.e('Failed to accept offer', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Reject an offer
  /// API: POST /conversations/{conversationId}/offers/{offerId}/reject
  Future<void> rejectOffer({
    required int conversationId,
    required int offerId,
  }) async {
    final url = '${ApiConfig.conversations}/$conversationId/offers/$offerId/reject';

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('rejectOffer', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('POST', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('❌ Rejecting offer $offerId');

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      AppLogger.apiResponse(response.statusCode, url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.i('✅ Offer rejected successfully');
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
      AppLogger.networkError('rejectOffer', e);
      AppLogger.e('Failed to reject offer', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get all offers for a conversation
  /// API: GET /conversations/{conversationId}/offers
  Future<List<Map<String, dynamic>>> getConversationOffers(int conversationId) async {
    final url = '${ApiConfig.conversations}/$conversationId/offers';

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('getConversationOffers', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('GET', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('📋 Fetching offers for conversation $conversationId');

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final offers = List<Map<String, dynamic>>.from(responseData['data'] ?? []);
        AppLogger.i('✅ Retrieved ${offers.length} offers');
        return offers;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getConversationOffers', e);
      AppLogger.e('Failed to load offers', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}

