import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class VerificationService {
  final StorageService _storageService = StorageService();

  /// Get verification status from API
  /// Returns a map with status, document_type, submitted_at, reviewed_at, admin_notes
  Future<Map<String, dynamic>?> getVerificationStatus() async {
    final url = ApiConfig.verifyStatus;
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('✅ Fetching verification status');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Authentication required');
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
      );

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        try {
          final data = responseData?['data'] as Map<String, dynamic>?;
          AppLogger.i('✅ Verification status retrieved');
          return data;
        } catch (e) {
          AppLogger.e('Invalid response format from server', e);
          throw Exception('Invalid response format from server');
        }
      } else if (response.statusCode == 404) {
        // No verification request found
        AppLogger.i('ℹ️ No verification request found');
        return null;
      } else {
        // Try to parse error message
        String errorMessage = 'Failed to fetch verification status';
        try {
          errorMessage = responseData?['message'] ?? errorMessage;
        } catch (e) {
          // If response is not JSON, use status code message
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          } else {
            errorMessage = 'Server error (${response.statusCode})';
          }
        }
        AppLogger.apiError(url, response.statusCode, errorMessage, errors: responseData?['errors']);
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      if (e is! Exception) {
        AppLogger.e('Unexpected error in getVerificationStatus', e, stackTrace);
      }
      if (e.toString().contains('Exception: ')) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      throw Exception(e.toString());
    }
  }

  /// Submit verification documents
  /// Requires 3 images: id_front, id_back, and selfie
  Future<Map<String, dynamic>> submitVerification({
    required String idFrontPath,
    required String idBackPath,
    required String selfiePath,
    required String documentType,
  }) async {
    final url = ApiConfig.verify;
    try {
      AppLogger.apiRequest('POST', url, body: {'document_type': documentType});
      AppLogger.i('✅ Submitting verification documents');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Authentication required');
        throw Exception('Authentication required');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      // Add headers
      request.headers.addAll(ApiConfig.getMultipartHeaders(token));

      // Add files (all 3 required by API)
      request.files.add(
        await http.MultipartFile.fromPath('id_front', idFrontPath),
      );

      request.files.add(
        await http.MultipartFile.fromPath('id_back', idBackPath),
      );

      request.files.add(
        await http.MultipartFile.fromPath('selfie', selfiePath),
      );

      // Add document type
      request.fields['document_type'] = documentType;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = responseData?['data'] as Map<String, dynamic>?;
          AppLogger.i('✅ Verification documents submitted successfully');
          return data ?? {};
        } catch (e) {
          AppLogger.e('Invalid response format from server', e);
          throw Exception('Invalid response format from server');
        }
      } else {
        // Try to parse error message
        String errorMessage = 'Failed to submit verification';
        try {
          errorMessage = responseData?['message'] ?? errorMessage;
        } catch (e) {
          // If response is not JSON, use status code message
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          } else {
            errorMessage = 'Server error (${response.statusCode})';
          }
        }
        AppLogger.apiError(url, response.statusCode, errorMessage, errors: responseData?['errors']);
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      if (e is! Exception) {
        AppLogger.e('Unexpected error in submitVerification', e, stackTrace);
      }
      if (e.toString().contains('Exception: ')) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      throw Exception(e.toString());
    }
  }
}
