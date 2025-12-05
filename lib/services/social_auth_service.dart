import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class SocialAuthService {
  final StorageService _storageService = StorageService();

  /// Get Google OAuth redirect URL
  Future<String> getGoogleAuthUrl() async {
    final url = ApiConfig.googleAuth;
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('🔐 Getting Google OAuth URL');

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        AppLogger.i('✅ Google OAuth URL retrieved');
        return responseData['url'] ?? '';
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getGoogleAuthUrl', e);
      AppLogger.e('Failed to get Google OAuth URL', e, stackTrace);
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
    final uri = Uri.parse(ApiConfig.googleAuthCallback).replace(
      queryParameters: {
        'code': code,
        if (state != null) 'state': state,
      },
    );
    final url = uri.toString();
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('🔐 Handling Google OAuth callback');

      final response = await http
          .get(
            uri,
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        // Save token if provided
        if (responseData['token'] != null) {
          await _storageService.saveToken(responseData['token']);
        }

        AppLogger.i('✅ Google OAuth authentication successful');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Successfully authenticated with Google',
          'user': responseData['user'],
          'token': responseData['token'],
        };
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('handleGoogleCallback', e);
      AppLogger.e('Failed to handle Google OAuth callback', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}

