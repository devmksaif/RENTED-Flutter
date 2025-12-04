import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/api_error.dart';
import 'storage_service.dart';

class ProductService {
  final StorageService _storageService = StorageService();

  /// Get all products (paginated)
  Future<List<Product>> getProducts({int page = 1, int perPage = 15}) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.products}?page=$page&per_page=$perPage'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = responseData['data'];
        return productsJson.map((json) => Product.fromJson(json)).toList();
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

  /// Get single product
  Future<Product> getProduct(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.products}/$id'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Product.fromJson(responseData['data']);
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

  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.categories), headers: ApiConfig.headers)
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> categoriesJson = responseData['data'];
        return categoriesJson.map((json) => Category.fromJson(json)).toList();
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

  /// Get user's products
  Future<List<Product>> getUserProducts() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.userProducts),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = responseData['data'];
        return productsJson.map((json) => Product.fromJson(json)).toList();
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

  /// Create product (requires multipart for files)
  Future<Product> createProduct({
    required int categoryId,
    required String title,
    required String description,
    required double pricePerDay,
    bool isForSale = false,
    double? salePrice,
    required String thumbnailPath,
    List<String>? imagePaths,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.products),
      );

      // Add headers
      request.headers.addAll(ApiConfig.getMultipartHeaders(token));

      // Add fields
      request.fields['category_id'] = categoryId.toString();
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price_per_day'] = pricePerDay.toString();
      request.fields['is_for_sale'] = isForSale.toString();
      if (salePrice != null) {
        request.fields['sale_price'] = salePrice.toString();
      }

      // Add thumbnail file
      request.files.add(
        await http.MultipartFile.fromPath('thumbnail', thumbnailPath),
      );

      // Add additional images if provided
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (int i = 0; i < imagePaths.length; i++) {
          request.files.add(
            await http.MultipartFile.fromPath('images[$i]', imagePaths[i]),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return Product.fromJson(responseData['data']);
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

  /// Update product
  Future<Product> updateProduct({
    required int productId,
    int? categoryId,
    String? title,
    String? description,
    double? pricePerDay,
    bool? isForSale,
    double? salePrice,
    bool? isAvailable,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final body = <String, dynamic>{};
      if (categoryId != null) body['category_id'] = categoryId;
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (pricePerDay != null) body['price_per_day'] = pricePerDay;
      if (isForSale != null) body['is_for_sale'] = isForSale;
      if (salePrice != null) body['sale_price'] = salePrice;
      if (isAvailable != null) body['is_available'] = isAvailable;

      final response = await http
          .put(
            Uri.parse('${ApiConfig.products}/$productId'),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Product.fromJson(responseData['data']);
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

  /// Delete product
  Future<void> deleteProduct(int productId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .delete(
            Uri.parse('${ApiConfig.products}/$productId'),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode != 204) {
        final responseData = jsonDecode(response.body);
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
