import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import 'storage_service.dart';

class DisputeService {
  final StorageService _storageService = StorageService();

  /// Get all disputes for the authenticated user
  Future<List<Map<String, dynamic>>> getDisputes() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.disputes),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(responseData['data'] ?? []);
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

  /// Get a specific dispute by ID
  Future<Map<String, dynamic>> getDispute(int disputeId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.disputes}/$disputeId'),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData['data'];
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

  /// Create a dispute
  Future<Map<String, dynamic>> createDispute({
    int? rentalId,
    int? purchaseId,
    required int reportedAgainst,
    required String disputeType,
    required String description,
    List<String>? evidence,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      if (rentalId == null && purchaseId == null) {
        throw ApiError(
          message: 'Either rental_id or purchase_id must be provided',
          statusCode: 400,
        );
      }

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

      final response = await http
          .post(
            Uri.parse(ApiConfig.disputes),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseData['data'] ?? responseData;
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

  /// Update dispute status (admin/moderator)
  Future<Map<String, dynamic>> updateDisputeStatus({
    required int disputeId,
    required String status,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.disputes}/$disputeId/status'),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({'status': status}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData['data'] ?? responseData;
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

  /// Resolve a dispute (admin/moderator)
  Future<Map<String, dynamic>> resolveDispute({
    required int disputeId,
    required String resolution,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.disputes}/$disputeId/resolve'),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({'resolution': resolution}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData['data'] ?? responseData;
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

