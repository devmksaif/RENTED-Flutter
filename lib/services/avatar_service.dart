import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/api_error.dart';
import 'storage_service.dart';

class AvatarService {
  final StorageService _storageService = StorageService();

  /// Upload or update user avatar
  /// Automatically deletes old avatar when updating
  Future<User> uploadAvatar(String avatarPath) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      // Check if file exists
      final avatarFile = File(avatarPath);
      if (!await avatarFile.exists()) {
        throw ApiError(message: 'Avatar file not found', statusCode: 400);
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.userAvatar),
      );

      // Add headers
      request.headers.addAll(ApiConfig.getMultipartHeaders(token));

      // Add avatar file
      request.files.add(
        await http.MultipartFile.fromPath('avatar', avatarPath),
      );

      // Send request
      final streamedResponse = await request.send().timeout(
        ApiConfig.connectionTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromJson(responseData['data']);
        // Update locally stored user
        await _storageService.saveUser(user);
        return user;
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on SocketException {
      throw ApiError(message: 'No internet connection', statusCode: 0);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        message: 'Failed to upload avatar: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Delete user avatar
  Future<User> deleteAvatar() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .delete(
            Uri.parse(ApiConfig.userAvatar),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromJson(responseData['data']);
        // Update locally stored user
        await _storageService.saveUser(user);
        return user;
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on SocketException {
      throw ApiError(message: 'No internet connection', statusCode: 0);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        message: 'Failed to delete avatar: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}
