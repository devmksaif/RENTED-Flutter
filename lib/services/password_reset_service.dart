import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';

class PasswordResetService {
  /// Request password reset
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = ApiConfig.forgotPassword;
    try {
      AppLogger.apiRequest('POST', url, body: {'email': email});
      AppLogger.i('🔐 Requesting password reset for $email');

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.headers,
            body: jsonEncode({'email': email}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        AppLogger.i('✅ Password reset email sent');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset link sent to your email',
        };
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('forgotPassword', e);
      AppLogger.e('Failed to request password reset', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Reset password with token
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final url = ApiConfig.resetPassword;
    try {
      AppLogger.apiRequest('POST', url, body: {'email': email, 'token': '***', 'password': '***', 'password_confirmation': '***'});
      AppLogger.i('🔐 Resetting password for $email');

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'email': email,
              'token': token,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        AppLogger.i('✅ Password reset successfully');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password has been reset successfully',
        };
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('resetPassword', e);
      AppLogger.e('Failed to reset password', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}

