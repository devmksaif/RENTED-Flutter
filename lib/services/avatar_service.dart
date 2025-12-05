import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import 'image_upload_service.dart';

class AvatarService {
  final StorageService _storageService = StorageService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  /// Upload or update user avatar using the new unified upload API
  /// Automatically deletes old avatar when updating
  Future<User> uploadAvatar(String avatarPath) async {
    try {
      AppLogger.i('🖼️ Uploading avatar using new upload API');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError('uploadAvatar', 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      // Check if file exists
      final avatarFile = File(avatarPath);
      if (!await avatarFile.exists()) {
        AppLogger.apiError('uploadAvatar', 400, 'Avatar file not found');
        throw ApiError(message: 'Avatar file not found', statusCode: 400);
      }

      // Get current user to check for existing avatar
      final currentUser = await _storageService.getUser();
      
      // Upload avatar using new endpoint
      final uploadResult = await _imageUploadService.uploadAvatar(
        avatarPath: avatarPath,
        useBase64: false,
      );

      // Delete old avatar if exists
      if (currentUser?.avatarUrl != null && currentUser!.avatarUrl!.isNotEmpty) {
        try {
          // Extract path from URL if it's a full URL
          String? oldPath = currentUser.avatarUrl;
          if (oldPath != null && oldPath.contains('/storage/')) {
            oldPath = oldPath.split('/storage/').last;
          }
          if (oldPath != null && oldPath.isNotEmpty) {
            await _imageUploadService.deleteImage(oldPath);
            AppLogger.i('🗑️ Old avatar deleted');
          }
        } catch (e) {
          // Ignore deletion errors - old avatar might not exist
          AppLogger.w('Failed to delete old avatar: $e');
        }
      }

      // Update user profile with new avatar URL
      final url = ApiConfig.userProfile;
      AppLogger.apiRequest('PUT', url, body: {'avatar_url': uploadResult['url']});

      final response = await http
          .put(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({'avatar_url': uploadResult['url']}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final userData = responseData['data'];
        final user = User.fromJson(userData);
        
        // If the API response doesn't include the avatar_url, use the one we just uploaded
        if (user.avatarUrl == null || user.avatarUrl!.isEmpty) {
          AppLogger.w('⚠️ API response missing avatar_url, using uploaded URL');
          final userWithAvatar = User(
            id: user.id,
            name: user.name,
            email: user.email,
            avatarUrl: uploadResult['url'], // Use the URL from upload response
            emailVerifiedAt: user.emailVerifiedAt,
            verificationStatus: user.verificationStatus,
            verifiedAt: user.verifiedAt,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
          );
          AppLogger.d('📸 Updated user avatar_url: ${userWithAvatar.avatarUrl}');
          await _storageService.saveUser(userWithAvatar);
          AppLogger.i('✅ Avatar uploaded successfully');
          return userWithAvatar;
        }
        
        AppLogger.d('📸 Updated user avatar_url: ${user.avatarUrl}');
        // Update locally stored user
        await _storageService.saveUser(user);
        AppLogger.i('✅ Avatar uploaded successfully');
        return user;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on SocketException catch (e) {
      AppLogger.networkError('uploadAvatar', e);
      throw ApiError(message: 'No internet connection', statusCode: 0);
    } on ApiError catch (e) {
      AppLogger.apiError('uploadAvatar', e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('uploadAvatar', e);
      AppLogger.e('Failed to upload avatar', e, stackTrace);
      throw ApiError(
        message: 'Failed to upload avatar: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Upload avatar using base64 (for camera captures, etc.)
  Future<User> uploadAvatarBase64(String base64Avatar) async {
    try {
      AppLogger.i('🖼️ Uploading avatar (base64) using new upload API');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError('uploadAvatarBase64', 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      // Get current user to check for existing avatar
      final currentUser = await _storageService.getUser();
      
      // Upload avatar using new endpoint
      final uploadResult = await _imageUploadService.uploadAvatar(
        base64Avatar: base64Avatar,
        useBase64: true,
      );

      // Delete old avatar if exists
      if (currentUser?.avatarUrl != null && currentUser!.avatarUrl!.isNotEmpty) {
        try {
          String? oldPath = currentUser.avatarUrl;
          if (oldPath != null && oldPath.contains('/storage/')) {
            oldPath = oldPath.split('/storage/').last;
          }
          if (oldPath != null && oldPath.isNotEmpty) {
            await _imageUploadService.deleteImage(oldPath);
            AppLogger.i('🗑️ Old avatar deleted');
          }
        } catch (e) {
          AppLogger.w('Failed to delete old avatar: $e');
        }
      }

      // Update user profile with new avatar URL
      final url = ApiConfig.userProfile;
      AppLogger.apiRequest('PUT', url, body: {'avatar_url': uploadResult['url']});

      final response = await http
          .put(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({'avatar_url': uploadResult['url']}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final userData = responseData['data'];
        final user = User.fromJson(userData);
        
        // If the API response doesn't include the avatar_url, use the one we just uploaded
        if (user.avatarUrl == null || user.avatarUrl!.isEmpty) {
          AppLogger.w('⚠️ API response missing avatar_url, using uploaded URL');
          final userWithAvatar = User(
            id: user.id,
            name: user.name,
            email: user.email,
            avatarUrl: uploadResult['url'], // Use the URL from upload response
            emailVerifiedAt: user.emailVerifiedAt,
            verificationStatus: user.verificationStatus,
            verifiedAt: user.verifiedAt,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
          );
          AppLogger.d('📸 Updated user avatar_url: ${userWithAvatar.avatarUrl}');
          await _storageService.saveUser(userWithAvatar);
          AppLogger.i('✅ Avatar uploaded successfully');
          return userWithAvatar;
        }
        
        AppLogger.d('📸 Updated user avatar_url: ${user.avatarUrl}');
        await _storageService.saveUser(user);
        AppLogger.i('✅ Avatar uploaded successfully');
        return user;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on SocketException catch (e) {
      AppLogger.networkError('uploadAvatarBase64', e);
      throw ApiError(message: 'No internet connection', statusCode: 0);
    } on ApiError catch (e) {
      AppLogger.apiError('uploadAvatarBase64', e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('uploadAvatarBase64', e);
      AppLogger.e('Failed to upload avatar', e, stackTrace);
      throw ApiError(
        message: 'Failed to upload avatar: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Delete user avatar
  Future<User> deleteAvatar() async {
    final url = ApiConfig.userAvatar;
    try {
      AppLogger.apiRequest('DELETE', url);
      AppLogger.i('🖼️ Deleting avatar');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .delete(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final user = User.fromJson(responseData['data']);
        // Update locally stored user
        await _storageService.saveUser(user);
        AppLogger.i('✅ Avatar deleted successfully');
        return user;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on SocketException catch (e) {
      AppLogger.networkError('deleteAvatar', e);
      throw ApiError(message: 'No internet connection', statusCode: 0);
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('deleteAvatar', e);
      AppLogger.e('Failed to delete avatar', e, stackTrace);
      throw ApiError(
        message: 'Failed to delete avatar: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}
