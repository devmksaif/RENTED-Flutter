import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storageService = StorageService();

  /// Register a new user
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final url = ApiConfig.register;
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    
    try {
      AppLogger.apiRequest('POST', url, body: {...body, 'password': '***', 'password_confirmation': '***'});
      AppLogger.i('👤 Registering new user: $email');

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(responseData);
        // Save token to secure storage
        await _storageService.saveToken(authResponse.token);
        await _storageService.saveUser(authResponse.user);
        AppLogger.i('✅ User registered successfully: ${authResponse.user.name} (ID: ${authResponse.user.id})');
        return authResponse;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('register', e);
      AppLogger.e('Failed to register user', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final url = ApiConfig.login;
    final body = {'email': email, 'password': password};
    
    try {
      AppLogger.apiRequest('POST', url, body: {'email': email, 'password': '***'});
      AppLogger.i('🔐 Logging in user: $email');

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(responseData);
        // Save token to secure storage
        await _storageService.saveToken(authResponse.token);
        await _storageService.saveUser(authResponse.user);
        AppLogger.i('✅ User logged in successfully: ${authResponse.user.name} (ID: ${authResponse.user.id})');
        return authResponse;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('login', e);
      AppLogger.e('Failed to login user', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    final url = ApiConfig.logout;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.w('⚠️ Logout called but no token found, clearing local data');
        await _storageService.clearAll();
        return;
      }

      AppLogger.apiRequest('POST', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('🚪 Logging out user');

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      AppLogger.apiResponse(response.statusCode, url);

      if (response.statusCode == 200) {
        // Clear local storage
        await _storageService.clearAll();
        AppLogger.i('✅ User logged out successfully');
      } else {
        final responseData = jsonDecode(response.body);
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        // Still clear local data even if API call fails
        await _storageService.clearAll();
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      // Even if logout fails on server, clear local data
      await _storageService.clearAll();
      AppLogger.w('⚠️ Logout API failed but local data cleared: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      // Even if logout fails on server, clear local data
      await _storageService.clearAll();
      AppLogger.networkError('logout', e);
      AppLogger.e('Logout failed but local data cleared', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get current user
  Future<User> getCurrentUser() async {
    final url = ApiConfig.user;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('getCurrentUser', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('GET', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('👤 Fetching current user');

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final user = User.fromJson(responseData['data']);
        await _storageService.saveUser(user);
        AppLogger.i('✅ Retrieved current user: ${user.name} (ID: ${user.id})');
        return user;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getCurrentUser', e);
      AppLogger.e('Failed to get current user', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    final url = ApiConfig.userProfile;
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (currentPassword != null) body['current_password'] = currentPassword;
    if (password != null) {
      body['password'] = password;
      body['password_confirmation'] = passwordConfirmation;
    }

    if (body.isEmpty) {
      AppLogger.w('⚠️ Update profile called with no changes');
      throw ApiError(
        message: 'No changes provided to update',
        statusCode: 400,
      );
    }
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('updateProfile', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final logBody = {...body};
      if (logBody.containsKey('password')) logBody['password'] = '***';
      if (logBody.containsKey('current_password')) logBody['current_password'] = '***';
      if (logBody.containsKey('password_confirmation')) logBody['password_confirmation'] = '***';
      
      AppLogger.apiRequest('PUT', url, body: logBody, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('✏️ Updating user profile');

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
        final user = User.fromJson(responseData['data']);
        await _storageService.saveUser(user);
        AppLogger.i('✅ Profile updated successfully: ${user.name}');
        return user;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('updateProfile', e);
      AppLogger.e('Failed to update profile', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null;
  }

  /// Get saved user from storage
  Future<User?> getSavedUser() async {
    return await _storageService.getUser();
  }

  /// Validate token by checking if it's still valid
  Future<bool> validateToken() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return false;

      // Try to fetch current user to validate token
      final response = await http
          .get(
            Uri.parse(ApiConfig.user),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get login time
  Future<DateTime?> getLoginTime() async {
    return await _storageService.getLoginTime();
  }

  /// Force logout (clear local data without API call)
  Future<void> forceLogout() async {
    await _storageService.clearAll();
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    final url = ApiConfig.deleteAccount;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('deleteAccount', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('DELETE', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('🗑️ Deleting user account');

      final response = await http
          .delete(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      AppLogger.apiResponse(response.statusCode, url);

      if (response.statusCode == 200) {
        // Clear local storage after successful deletion
        await _storageService.clearAll();
        AppLogger.i('✅ Account deleted successfully');
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
      AppLogger.networkError('deleteAccount', e);
      AppLogger.e('Failed to delete account', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}
