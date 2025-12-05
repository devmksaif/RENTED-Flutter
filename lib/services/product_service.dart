import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import 'image_upload_service.dart';

class ProductService {
  final StorageService _storageService = StorageService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  /// Get all products (paginated)
  Future<List<Product>> getProducts({int page = 1, int perPage = 15}) async {
    final url = '${ApiConfig.products}?page=$page&per_page=$perPage';
    
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('📦 Fetching products (page $page, $perPage per page)');

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = responseData['data'];
        final products = productsJson.map((json) => Product.fromJson(json)).toList();
        AppLogger.i('✅ Retrieved ${products.length} products');
        
        // Debug: Log verification status of products
        final statusCounts = <String, int>{};
        for (var product in products) {
          final status = product.verificationStatus ?? 'null';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
        AppLogger.d('📊 Product verification status breakdown: $statusCounts');
        
        return products;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on SocketException catch (e, stackTrace) {
      AppLogger.networkError('getProducts', e);
      AppLogger.e('No internet connection', e, stackTrace);
      throw ApiError(
        message: 'No internet connection. Please check your network.',
        statusCode: 0,
      );
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.networkError('getProducts', e);
      AppLogger.e('Request timed out', e, stackTrace);
      throw ApiError(
        message: 'Request timed out. Please try again.',
        statusCode: 0,
      );
    } on FormatException catch (e, stackTrace) {
      AppLogger.e('Invalid JSON response', e, stackTrace);
      throw ApiError(message: 'Invalid response from server.', statusCode: 0);
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getProducts', e);
      AppLogger.e('Failed to load products', e, stackTrace);
      throw ApiError(
        message: 'Failed to load products: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Get single product
  Future<Product> getProduct(int id) async {
    final url = '${ApiConfig.products}/$id';
    
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('📦 Fetching product $id');

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final product = Product.fromJson(responseData['data']);
        AppLogger.i('✅ Retrieved product: ${product.title}');
        return product;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getProduct', e);
      AppLogger.e('Failed to load product $id', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get all categories
  Future<List<Category>> getCategories() async {
    final url = ApiConfig.categories;
    
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('📂 Fetching categories');

      final response = await http
          .get(Uri.parse(url), headers: ApiConfig.headers)
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final List<dynamic> categoriesJson = responseData['data'];
        final categories = categoriesJson.map((json) => Category.fromJson(json)).toList();
        AppLogger.i('✅ Retrieved ${categories.length} categories');
        return categories;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getCategories', e);
      AppLogger.e('Failed to load categories', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get user's products
  Future<List<Product>> getUserProducts() async {
    final url = ApiConfig.userProducts;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('getUserProducts', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('GET', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('📦 Fetching user products');

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = responseData['data'];
        final products = productsJson.map((json) => Product.fromJson(json)).toList();
        AppLogger.i('✅ Retrieved ${products.length} user products');
        return products;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getUserProducts', e);
      AppLogger.e('Failed to load user products', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Create product using new image upload API
  /// Images are uploaded first, then product is created with image paths
  /// API accepts 1-10 images. First image becomes thumbnail.
  Future<Product> createProduct({
    required int categoryId,
    required String title,
    required String description,
    required double pricePerDay,
    bool isForSale = false,
    double? salePrice,
    double? pricePerWeek,
    double? pricePerMonth,
    double? securityDeposit,
    int? minRentalDays,
    int? maxRentalDays,
    String? locationAddress,
    String? locationCity,
    String? locationState,
    String? locationCountry,
    String? locationZip,
    double? locationLatitude,
    double? locationLongitude,
    bool? deliveryAvailable,
    double? deliveryFee,
    double? deliveryRadiusKm,
    bool? pickupAvailable,
    String? productCondition,
    required List<String> imagePaths, // File paths to upload (1-10 images)
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      // Validate images
      if (imagePaths.isEmpty) {
        AppLogger.validationError('images', 'At least one image is required');
        throw ApiError(
          message: 'At least one image is required',
          statusCode: 400,
        );
      }

      if (imagePaths.length > 10) {
        AppLogger.validationError('images', 'Maximum 10 images allowed');
        throw ApiError(message: 'Maximum 10 images allowed', statusCode: 400);
      }

      AppLogger.i('📤 Creating product: $title');
      AppLogger.d('Product details: category=$categoryId, price=\$$pricePerDay, images=${imagePaths.length}');

      // Step 1: Upload images first using new upload API
      AppLogger.i('📤 Step 1: Uploading ${imagePaths.length} product images...');
      final uploadResult = await _imageUploadService.uploadImages(
        imagePaths: imagePaths,
        type: 'product_images',
        useBase64: false,
      );

      final uploadedImagePaths = uploadResult['paths'] as List<String>;
      AppLogger.i('✅ Images uploaded: ${uploadedImagePaths.length} images');

      // Step 2: Create product with uploaded image paths
      AppLogger.i('📤 Step 2: Creating product with image paths...');
      final productData = {
        'category_id': categoryId,
        'title': title,
        'description': description,
        'price_per_day': pricePerDay,
        'is_for_sale': isForSale ? 1 : 0,
        'thumbnail': uploadedImagePaths[0], // First image is thumbnail
        'images': uploadedImagePaths, // All images
        if (salePrice != null) 'sale_price': salePrice,
        if (pricePerWeek != null) 'price_per_week': pricePerWeek,
        if (pricePerMonth != null) 'price_per_month': pricePerMonth,
        if (securityDeposit != null) 'security_deposit': securityDeposit,
        if (minRentalDays != null) 'min_rental_days': minRentalDays,
        if (maxRentalDays != null) 'max_rental_days': maxRentalDays,
        if (locationAddress != null && locationAddress.isNotEmpty) 'location_address': locationAddress,
        if (locationCity != null && locationCity.isNotEmpty) 'location_city': locationCity,
        if (locationState != null && locationState.isNotEmpty) 'location_state': locationState,
        if (locationCountry != null && locationCountry.isNotEmpty) 'location_country': locationCountry,
        if (locationZip != null && locationZip.isNotEmpty) 'location_zip': locationZip,
        if (locationLatitude != null) 'location_latitude': locationLatitude,
        if (locationLongitude != null) 'location_longitude': locationLongitude,
        if (deliveryAvailable != null) 'delivery_available': deliveryAvailable ? 1 : 0,
        if (deliveryFee != null) 'delivery_fee': deliveryFee,
        if (deliveryRadiusKm != null) 'delivery_radius_km': deliveryRadiusKm,
        if (pickupAvailable != null) 'pickup_available': pickupAvailable ? 1 : 0,
        if (productCondition != null && productCondition.isNotEmpty) 'product_condition': productCondition,
      };

      AppLogger.apiRequest('POST', ApiConfig.products, body: {
        'category_id': categoryId,
        'title': title,
        'price_per_day': pricePerDay,
        'images_count': uploadedImagePaths.length,
      }, headers: ApiConfig.getAuthHeaders(token));

      final response = await http
          .post(
            Uri.parse(ApiConfig.products),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode(productData),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, ApiConfig.products, body: responseData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final product = Product.fromJson(responseData['data']);
        AppLogger.i('✅ Product created successfully: ID ${product.id} - ${product.title}');
        return product;
      } else {
        // If product creation fails, we should ideally delete the uploaded images
        // But for now, just log the error
        AppLogger.w('⚠️ Product creation failed, but images were already uploaded');
        AppLogger.apiError(ApiConfig.products, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on http.ClientException catch (e, stackTrace) {
      AppLogger.networkError('createProduct', e);
      AppLogger.e('Connection failed', e, stackTrace);
      throw ApiError(
        message: 'Connection failed. Check your internet.',
        statusCode: 0,
      );
    } on SocketException catch (e, stackTrace) {
      AppLogger.networkError('createProduct', e);
      AppLogger.e('No internet connection', e, stackTrace);
      throw ApiError(message: 'No internet connection', statusCode: 0);
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.networkError('createProduct', e);
      AppLogger.e('Request timed out', e, stackTrace);
      throw ApiError(
        message: 'Request timed out. Please try again.',
        statusCode: 0,
      );
    } on ApiError catch (e) {
      AppLogger.apiError(ApiConfig.products, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('createProduct', e);
      AppLogger.e('Failed to create product', e, stackTrace);
      throw ApiError(
        message: 'Failed to create product: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Update product
  /// For images: API replaces ALL images when new ones are provided
  Future<Product> updateProduct({
    required int productId,
    int? categoryId,
    String? title,
    String? description,
    double? pricePerDay,
    bool? isForSale,
    double? salePrice,
    bool? isAvailable,
    List<String>? newImagePaths, // If provided, replaces all existing images
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.i('✏️ Updating product $productId');

      // If no images, use simple JSON update
      if (newImagePaths == null || newImagePaths.isEmpty) {
        final body = <String, dynamic>{};
        if (categoryId != null) body['category_id'] = categoryId;
        if (title != null) body['title'] = title;
        if (description != null) body['description'] = description;
        if (pricePerDay != null) body['price_per_day'] = pricePerDay;
        if (isForSale != null) body['is_for_sale'] = isForSale;
        if (salePrice != null) body['sale_price'] = salePrice;
        if (isAvailable != null) body['is_available'] = isAvailable;

        final url = '${ApiConfig.products}/$productId';
        AppLogger.apiRequest('PUT', url, body: body, headers: ApiConfig.getAuthHeaders(token));

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
          final product = Product.fromJson(responseData['data']);
          AppLogger.i('✅ Product updated successfully: ID $productId');
          return product;
        } else {
          AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
          throw ApiError.fromJson(responseData, response.statusCode);
        }
      }

      // Update with images - use multipart with _method=PUT
      if (newImagePaths.length > 5) {
        AppLogger.validationError('images', 'Maximum 5 images allowed');
        throw ApiError(message: 'Maximum 5 images allowed', statusCode: 400);
      }

      AppLogger.d('Updating product with ${newImagePaths.length} new images');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.products}/$productId'),
      );

      request.headers.addAll(ApiConfig.getMultipartHeaders(token));
      request.fields['_method'] = 'PUT';

      // Add fields
      if (categoryId != null) {
        request.fields['category_id'] = categoryId.toString();
      }
      if (title != null) request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (pricePerDay != null) {
        request.fields['price_per_day'] = pricePerDay.toString();
      }
      if (isForSale != null) {
        request.fields['is_for_sale'] = isForSale ? '1' : '0';
      }
      if (salePrice != null) {
        request.fields['sale_price'] = salePrice.toString();
      }
      if (isAvailable != null) {
        request.fields['is_available'] = isAvailable ? '1' : '0';
      }

      // Add new images (replaces all old images)
      for (int i = 0; i < newImagePaths.length; i++) {
        final imageFile = File(newImagePaths[i]);
        if (await imageFile.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('images[]', newImagePaths[i]),
          );
        }
      }

      final url = '${ApiConfig.products}/$productId';
      AppLogger.apiRequest('POST', url, body: {
        'category_id': categoryId,
        'title': title,
        '_method': 'PUT',
        'images_count': newImagePaths.length,
      }, headers: ApiConfig.getMultipartHeaders(token));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final product = Product.fromJson(responseData['data']);
        AppLogger.i('✅ Product updated successfully: ID $productId');
        return product;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError('${ApiConfig.products}/$productId', e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('updateProduct', e);
      AppLogger.e('Failed to update product $productId', e, stackTrace);
      throw ApiError(
        message: 'Failed to update product: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Delete product
  Future<void> deleteProduct(int productId) async {
    final url = '${ApiConfig.products}/$productId';
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('deleteProduct', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('DELETE', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('🗑️ Deleting product $productId');

      final response = await http
          .delete(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      AppLogger.apiResponse(response.statusCode, url);

      if (response.statusCode == 204 || response.statusCode == 200) {
        AppLogger.i('✅ Product deleted successfully: ID $productId');
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
      AppLogger.networkError('deleteProduct', e);
      AppLogger.e('Failed to delete product $productId', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}
