import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../models/api_error.dart';
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
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.register),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(responseData);
        // Save token to secure storage
        await _storageService.saveToken(authResponse.token);
        await _storageService.saveUser(authResponse.user);
        return authResponse;
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

  /// Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.login),
            headers: ApiConfig.headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(responseData);
        // Save token to secure storage
        await _storageService.saveToken(authResponse.token);
        await _storageService.saveUser(authResponse.user);
        return authResponse;
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

  /// Logout user
  Future<void> logout() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.logout),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        // Clear local storage
        await _storageService.clearAll();
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      // Even if logout fails on server, clear local data
      await _storageService.clearAll();
      if (e is ApiError) rethrow;
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get current user
  Future<User> getCurrentUser() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.user),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromJson(responseData['data']);
        await _storageService.saveUser(user);
        return user;
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

  /// Update user profile
  Future<User> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (currentPassword != null) body['current_password'] = currentPassword;
      if (password != null) {
        body['password'] = password;
        body['password_confirmation'] = passwordConfirmation;
      }

      final response = await http
          .put(
            Uri.parse(ApiConfig.userProfile),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromJson(responseData['data']);
        await _storageService.saveUser(user);
        return user;
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

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null;
  }

  /// Get saved user from storage
  Future<User?> getSavedUser() async {
    return await _storageService.getUser();
  }
}
