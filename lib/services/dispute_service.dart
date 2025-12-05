import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class DisputeService {
  final StorageService _storageService = StorageService();

  /// Get all disputes for the authenticated user
  Future<List<Map<String, dynamic>>> getDisputes() async {
    final url = ApiConfig.disputes;
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('⚖️ Fetching disputes');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
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
        final disputes = List<Map<String, dynamic>>.from(responseData['data'] ?? []);
        AppLogger.i('✅ Retrieved ${disputes.length} disputes');
        return disputes;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getDisputes', e);
      AppLogger.e('Failed to fetch disputes', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get a specific dispute by ID
  Future<Map<String, dynamic>> getDispute(int disputeId) async {
    final url = '${ApiConfig.disputes}/$disputeId';
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('⚖️ Fetching dispute $disputeId');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
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
        AppLogger.i('✅ Retrieved dispute $disputeId');
        return responseData['data'];
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getDispute', e);
      AppLogger.e('Failed to fetch dispute', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Create a dispute
  Future<Map<String, dynamic>> createDispute({
    int? rentalId,
    int? purchaseId,
    required int reportedAgainst,
    required String disputeType,
    required String description,
    List<String>? evidence,
  }) async {
    final url = ApiConfig.disputes;
    try {
      final body = <String, dynamic>{
        'reported_against': reportedAgainst,
        'dispute_type': disputeType,
        'description': description,
      };

      if (rentalId != null) {
        body['rental_id'] = rentalId;
      } else {
        body['purchase_id'] = purchaseId;
      }

      if (evidence != null && evidence.isNotEmpty) {
        body['evidence'] = evidence;
      }

      AppLogger.apiRequest('POST', url, body: body);
      AppLogger.i('⚖️ Creating dispute');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      if (rentalId == null && purchaseId == null) {
        AppLogger.apiError(url, 400, 'Either rental_id or purchase_id must be provided');
        throw ApiError(
          message: 'Either rental_id or purchase_id must be provided',
          statusCode: 400,
        );
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
        AppLogger.i('✅ Dispute created successfully');
        return responseData['data'] ?? responseData;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('createDispute', e);
      AppLogger.e('Failed to create dispute', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Update dispute status (admin/moderator)
  Future<Map<String, dynamic>> updateDisputeStatus({
    required int disputeId,
    required String status,
  }) async {
    final url = '${ApiConfig.disputes}/$disputeId/status';
    try {
      AppLogger.apiRequest('PUT', url, body: {'status': status});
      AppLogger.i('⚖️ Updating dispute $disputeId status to $status');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .put(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({'status': status}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        AppLogger.i('✅ Dispute status updated successfully');
        return responseData['data'] ?? responseData;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('updateDisputeStatus', e);
      AppLogger.e('Failed to update dispute status', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Resolve a dispute (admin/moderator)
  Future<Map<String, dynamic>> resolveDispute({
    required int disputeId,
    required String resolution,
  }) async {
    final url = '${ApiConfig.disputes}/$disputeId/resolve';
    try {
      AppLogger.apiRequest('POST', url, body: {'resolution': resolution});
      AppLogger.i('⚖️ Resolving dispute $disputeId');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({'resolution': resolution}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        AppLogger.i('✅ Dispute resolved successfully');
        return responseData['data'] ?? responseData;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('resolveDispute', e);
      AppLogger.e('Failed to resolve dispute', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}

