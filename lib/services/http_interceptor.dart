import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'storage_service.dart';

/// HTTP Interceptor Service for handling authenticated requests
/// Automatically adds auth headers and handles token expiration
class HttpInterceptor {
  final StorageService _storageService = StorageService();

  /// Make an authenticated GET request
  Future<http.Response> get(String endpoint) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    return await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: ApiConfig.getAuthHeaders(token),
        )
        .timeout(ApiConfig.connectionTimeout);
  }

  /// Make an authenticated POST request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    return await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: ApiConfig.getAuthHeaders(token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.connectionTimeout);
  }

  /// Make an authenticated PUT request
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    return await http
        .put(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: ApiConfig.getAuthHeaders(token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.connectionTimeout);
  }

  /// Make an authenticated DELETE request
  Future<http.Response> delete(String endpoint) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    return await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: ApiConfig.getAuthHeaders(token),
        )
        .timeout(ApiConfig.connectionTimeout);
  }

  /// Make an authenticated multipart request (for file uploads)
  Future<http.StreamedResponse> multipart(
    String method,
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final request = http.MultipartRequest(
      method,
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
    );

    // Add auth headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add files
    if (files != null) {
      request.files.addAll(files);
    }

    return await request.send();
  }

  /// Check if response indicates token expiration
  bool isTokenExpired(http.Response response) {
    return response.statusCode == 401;
  }

  /// Handle response and check for token expiration
  Future<http.Response> handleResponse(
    http.Response response, {
    Function? onTokenExpired,
  }) async {
    if (isTokenExpired(response)) {
      // Clear local storage
      await _storageService.clearAll();

      // Call callback if provided
      if (onTokenExpired != null) {
        onTokenExpired();
      }
    }
    return response;
  }
}
