import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import 'storage_service.dart';

class SocialAuthService {
  final StorageService _storageService = StorageService();

  /// Get Google OAuth redirect URL
  Future<String> getGoogleAuthUrl() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.googleAuth),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData['url'] ?? '';
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

  /// Handle Google OAuth callback
  /// Note: This is typically handled by the backend redirect, but this method
  /// can be used if the callback URL returns JSON directly
  Future<Map<String, dynamic>> handleGoogleCallback({
    required String code,
    String? state,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.googleAuthCallback).replace(
        queryParameters: {
          'code': code,
          if (state != null) 'state': state,
        },
      );

      final response = await http
          .get(
            uri,
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save token if provided
        if (responseData['token'] != null) {
          await _storageService.saveToken(responseData['token']);
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Successfully authenticated with Google',
          'user': responseData['user'],
          'token': responseData['token'],
        };
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

