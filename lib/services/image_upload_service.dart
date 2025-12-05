import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

/// Service for uploading images using the new unified image upload API
/// Supports both file uploads and base64 encoded images
class ImageUploadService {
  final StorageService _storageService = StorageService();

  /// Fixes URLs that contain localhost by replacing with the actual server URL
  String _fixImageUrl(String url) {
    if (url.contains('localhost:8000')) {
      // Replace localhost:8000 with the actual server URL
      final baseUrl = ApiConfig.baseUrl.replaceAll('/api/v1', '');
      return url.replaceAll('http://localhost:8000', baseUrl);
    }
    return url;
  }

  /// Upload a single image
  /// 
  /// [imagePath] - Path to image file (for file upload)
  /// [base64Image] - Base64 encoded image string (for base64 upload)
  /// [type] - Image type: 'avatar', 'product_thumbnail', 'product_image', 'general'
  /// [useBase64] - Whether to use base64 upload (default: false)
  /// 
  /// Returns the uploaded image path and URL
  Future<Map<String, String>> uploadImage({
    String? imagePath,
    String? base64Image,
    required String type,
    bool useBase64 = false,
  }) async {
    final url = ApiConfig.uploadImage;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('uploadImage', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      if (useBase64) {
        if (base64Image == null || base64Image.isEmpty) {
          throw ApiError(
            message: 'Base64 image is required when useBase64 is true',
            statusCode: 400,
          );
        }
        return await _uploadImageBase64(url, token, base64Image, type);
      } else {
        if (imagePath == null || imagePath.isEmpty) {
          throw ApiError(
            message: 'Image path is required when useBase64 is false',
            statusCode: 400,
          );
        }
        return await _uploadImageFile(url, token, imagePath, type);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('uploadImage', e);
      AppLogger.e('Failed to upload image', e, stackTrace);
      throw ApiError(
        message: 'Failed to upload image: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Upload multiple images at once (up to 10 images)
  /// 
  /// [imagePaths] - List of image file paths (for file upload)
  /// [base64Images] - List of base64 encoded image strings (for base64 upload)
  /// [type] - Image type: 'product_images', 'gallery', 'general'
  /// [useBase64] - Whether to use base64 upload (default: false)
  /// 
  /// Returns list of uploaded image paths and URLs
  Future<Map<String, dynamic>> uploadImages({
    List<String>? imagePaths,
    List<String>? base64Images,
    required String type,
    bool useBase64 = false,
  }) async {
    final url = ApiConfig.uploadImages;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('uploadImages', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      // Validate count
      final count = useBase64 
          ? (base64Images?.length ?? 0)
          : (imagePaths?.length ?? 0);
      
      if (count == 0) {
        throw ApiError(
          message: 'At least one image is required',
          statusCode: 400,
        );
      }
      
      if (count > 10) {
        throw ApiError(
          message: 'Maximum 10 images allowed',
          statusCode: 400,
        );
      }

      if (useBase64) {
        if (base64Images == null || base64Images.isEmpty) {
          throw ApiError(
            message: 'Base64 images are required when useBase64 is true',
            statusCode: 400,
          );
        }
        return await _uploadImagesBase64(url, token, base64Images, type);
      } else {
        if (imagePaths == null || imagePaths.isEmpty) {
          throw ApiError(
            message: 'Image paths are required when useBase64 is false',
            statusCode: 400,
          );
        }
        return await _uploadImagesFile(url, token, imagePaths, type);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('uploadImages', e);
      AppLogger.e('Failed to upload images', e, stackTrace);
      throw ApiError(
        message: 'Failed to upload images: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Upload avatar (dedicated endpoint with automatic square cropping)
  /// 
  /// [avatarPath] - Path to avatar file (for file upload)
  /// [base64Avatar] - Base64 encoded avatar string (for base64 upload)
  /// [useBase64] - Whether to use base64 upload (default: false)
  /// 
  /// Returns the uploaded avatar path and URL
  Future<Map<String, String>> uploadAvatar({
    String? avatarPath,
    String? base64Avatar,
    bool useBase64 = false,
  }) async {
    final url = ApiConfig.uploadAvatar;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('uploadAvatar', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      if (useBase64) {
        if (base64Avatar == null || base64Avatar.isEmpty) {
          throw ApiError(
            message: 'Base64 avatar is required when useBase64 is true',
            statusCode: 400,
          );
        }
        return await _uploadAvatarBase64(url, token, base64Avatar);
      } else {
        if (avatarPath == null || avatarPath.isEmpty) {
          throw ApiError(
            message: 'Avatar path is required when useBase64 is false',
            statusCode: 400,
          );
        }
        return await _uploadAvatarFile(url, token, avatarPath);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
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

  /// Delete an uploaded image
  /// 
  /// [imagePath] - Path to the image to delete (e.g., 'avatars/20251205120530_abc123.jpg')
  Future<void> deleteImage(String imagePath) async {
    final url = ApiConfig.uploadImage;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('deleteImage', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('DELETE', url, body: {'path': imagePath});
      AppLogger.i('🗑️ Deleting image: $imagePath');

      final response = await http
          .delete(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode({'path': imagePath}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        AppLogger.i('✅ Image deleted successfully');
      } else {
        AppLogger.apiError(
          url,
          response.statusCode,
          responseData['message'] ?? 'Unknown error',
          errors: responseData['errors'],
        );
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('deleteImage', e);
      AppLogger.e('Failed to delete image', e, stackTrace);
      throw ApiError(
        message: 'Failed to delete image: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // Private helper methods

  Future<Map<String, String>> _uploadImageFile(
    String url,
    String token,
    String imagePath,
    String type,
  ) async {
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw ApiError(message: 'Image file not found', statusCode: 400);
    }

    AppLogger.apiRequest('POST', url, body: {'type': type});
    AppLogger.i('📤 Uploading image file: $imagePath (type: $type)');

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(ApiConfig.getMultipartHeaders(token));
    request.fields['type'] = type;
    // base64 field not needed for file uploads - API detects file upload automatically
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamedResponse = await request.send().timeout(ApiConfig.connectionTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    final responseData = jsonDecode(response.body);
    AppLogger.apiResponse(response.statusCode, url, body: responseData);

    if (response.statusCode == 201) {
      final data = responseData['data'];
      AppLogger.i('✅ Image uploaded successfully: ${data['path']}');
      return {
        'path': data['path'],
        'url': data['url'],
      };
    } else {
      AppLogger.apiError(
        url,
        response.statusCode,
        responseData['message'] ?? 'Unknown error',
        errors: responseData['errors'],
      );
      throw ApiError.fromJson(responseData, response.statusCode);
    }
  }

  Future<Map<String, String>> _uploadImageBase64(
    String url,
    String token,
    String base64Image,
    String type,
  ) async {
    AppLogger.apiRequest('POST', url, body: {'type': type, 'base64': true});
    AppLogger.i('📤 Uploading base64 image (type: $type)');

    final response = await http
        .post(
          Uri.parse(url),
          headers: ApiConfig.getAuthHeaders(token),
          body: jsonEncode({
            'type': type,
            'image': base64Image,
            'base64': true,
          }),
        )
        .timeout(ApiConfig.connectionTimeout);

    final responseData = jsonDecode(response.body);
    AppLogger.apiResponse(response.statusCode, url, body: responseData);

    if (response.statusCode == 201) {
      final data = responseData['data'];
      AppLogger.i('✅ Image uploaded successfully: ${data['path']}');
      return {
        'path': data['path'],
        'url': data['url'],
      };
    } else {
      AppLogger.apiError(
        url,
        response.statusCode,
        responseData['message'] ?? 'Unknown error',
        errors: responseData['errors'],
      );
      throw ApiError.fromJson(responseData, response.statusCode);
    }
  }

  Future<Map<String, dynamic>> _uploadImagesFile(
    String url,
    String token,
    List<String> imagePaths,
    String type,
  ) async {
    // Validate all files exist
    for (var path in imagePaths) {
      final file = File(path);
      if (!await file.exists()) {
        throw ApiError(message: 'Image file not found: $path', statusCode: 400);
      }
    }

    AppLogger.apiRequest('POST', url, body: {'type': type, 'count': imagePaths.length});
    AppLogger.i('📤 Uploading ${imagePaths.length} images (type: $type)');

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(ApiConfig.getMultipartHeaders(token));
    request.fields['type'] = type;
    // base64 field not needed for file uploads - API detects file upload automatically

    for (var path in imagePaths) {
      request.files.add(await http.MultipartFile.fromPath('images[]', path));
    }

    final streamedResponse = await request.send().timeout(ApiConfig.connectionTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    final responseData = jsonDecode(response.body);
    AppLogger.apiResponse(response.statusCode, url, body: responseData);

    if (response.statusCode == 201) {
      final data = responseData['data'];
      AppLogger.i('✅ ${imagePaths.length} images uploaded successfully');
      return {
        'paths': List<String>.from(data['paths']),
        'urls': List<String>.from(data['urls']),
      };
    } else {
      AppLogger.apiError(
        url,
        response.statusCode,
        responseData['message'] ?? 'Unknown error',
        errors: responseData['errors'],
      );
      throw ApiError.fromJson(responseData, response.statusCode);
    }
  }

  Future<Map<String, dynamic>> _uploadImagesBase64(
    String url,
    String token,
    List<String> base64Images,
    String type,
  ) async {
    AppLogger.apiRequest('POST', url, body: {'type': type, 'base64': true, 'count': base64Images.length});
    AppLogger.i('📤 Uploading ${base64Images.length} base64 images (type: $type)');

    final response = await http
        .post(
          Uri.parse(url),
          headers: ApiConfig.getAuthHeaders(token),
          body: jsonEncode({
            'type': type,
            'images': base64Images,
            'base64': true,
          }),
        )
        .timeout(ApiConfig.connectionTimeout);

    final responseData = jsonDecode(response.body);
    AppLogger.apiResponse(response.statusCode, url, body: responseData);

    if (response.statusCode == 201) {
      final data = responseData['data'];
      AppLogger.i('✅ ${base64Images.length} images uploaded successfully');
      return {
        'paths': List<String>.from(data['paths']),
        'urls': List<String>.from(data['urls']),
      };
    } else {
      AppLogger.apiError(
        url,
        response.statusCode,
        responseData['message'] ?? 'Unknown error',
        errors: responseData['errors'],
      );
      throw ApiError.fromJson(responseData, response.statusCode);
    }
  }

  Future<Map<String, String>> _uploadAvatarFile(
    String url,
    String token,
    String avatarPath,
  ) async {
    final avatarFile = File(avatarPath);
    if (!await avatarFile.exists()) {
      throw ApiError(message: 'Avatar file not found', statusCode: 400);
    }

    AppLogger.apiRequest('POST', url);
    AppLogger.i('📤 Uploading avatar file: $avatarPath');

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(ApiConfig.getMultipartHeaders(token));
    // base64 field not needed for file uploads - API detects file upload automatically
    request.files.add(await http.MultipartFile.fromPath('avatar', avatarPath));

    final streamedResponse = await request.send().timeout(ApiConfig.connectionTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    final responseData = jsonDecode(response.body);
    AppLogger.apiResponse(response.statusCode, url, body: responseData);

    if (response.statusCode == 201) {
      final data = responseData['data'];
      final fixedUrl = _fixImageUrl(data['url']);
      AppLogger.i('✅ Avatar uploaded successfully: ${data['path']}');
      return {
        'path': data['path'],
        'url': fixedUrl,
      };
    } else {
      AppLogger.apiError(
        url,
        response.statusCode,
        responseData['message'] ?? 'Unknown error',
        errors: responseData['errors'],
      );
      throw ApiError.fromJson(responseData, response.statusCode);
    }
  }

  Future<Map<String, String>> _uploadAvatarBase64(
    String url,
    String token,
    String base64Avatar,
  ) async {
    AppLogger.apiRequest('POST', url, body: {'base64': true});
    AppLogger.i('📤 Uploading base64 avatar');

    final response = await http
        .post(
          Uri.parse(url),
          headers: ApiConfig.getAuthHeaders(token),
          body: jsonEncode({
            'avatar': base64Avatar,
            'base64': true,
          }),
        )
        .timeout(ApiConfig.connectionTimeout);

    final responseData = jsonDecode(response.body);
    AppLogger.apiResponse(response.statusCode, url, body: responseData);

    if (response.statusCode == 201) {
      final data = responseData['data'];
      final fixedUrl = _fixImageUrl(data['url']);
      AppLogger.i('✅ Avatar uploaded successfully: ${data['path']}');
      return {
        'path': data['path'],
        'url': fixedUrl,
      };
    } else {
      AppLogger.apiError(
        url,
        response.statusCode,
        responseData['message'] ?? 'Unknown error',
        errors: responseData['errors'],
      );
      throw ApiError.fromJson(responseData, response.statusCode);
    }
  }
}

