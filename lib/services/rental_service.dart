import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/rental.dart';
import '../models/product.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import 'product_service.dart';

class RentalService {
  final StorageService _storageService = StorageService();

  /// Create a rental request
  Future<Rental> createRental({
    required int productId,
    required String startDate,
    required String endDate,
    String? notes,
  }) async {
    final url = ApiConfig.rentals;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('createRental', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      // Get current user to check if they're the product owner
      final currentUser = await _storageService.getUser();
      if (currentUser == null) {
        AppLogger.authError('createRental', 'No user data found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      // Check if user is verified before allowing rental
      if (!currentUser.isVerified) {
        AppLogger.validationError('user', 'User must be verified to create rentals');
        throw ApiError(
          message: 'You must be verified to rent products. Please complete your verification first.',
          statusCode: 403,
        );
      }

      // Get product details to verify ownership and status
      final productService = ProductService();
      Product product;
      try {
        product = await productService.getProduct(productId);
      } catch (e) {
        AppLogger.e('Failed to fetch product for rental validation', e);
        throw ApiError(
          message: 'Product not found or unavailable',
          statusCode: 404,
        );
      }

      // Prevent owners from renting their own products
      if (product.owner != null && product.owner!.id == currentUser.id) {
        AppLogger.validationError('product_id', 'You cannot rent your own product');
        throw ApiError(
          message: 'You cannot rent your own product',
          statusCode: 403,
        );
      }

      // Only allow rental for approved products
      if (product.verificationStatus != 'approved') {
        AppLogger.validationError('product_id', 'Product is not approved for rental');
        throw ApiError(
          message: 'This product is not available for rental yet',
          statusCode: 400,
        );
      }

      // Only allow rental for available products
      if (!product.isAvailable) {
        AppLogger.validationError('product_id', 'Product is not available');
        throw ApiError(
          message: 'This product is not available for rental',
          statusCode: 400,
        );
      }

      // Validate date format (YYYY-MM-DD)
      final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (!dateRegex.hasMatch(startDate) || !dateRegex.hasMatch(endDate)) {
        AppLogger.validationError('dates', 'Invalid date format. Use YYYY-MM-DD');
        throw ApiError(
          message: 'Invalid date format. Use YYYY-MM-DD',
          statusCode: 400,
        );
      }

      // Validate dates
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);

      if (end.isBefore(start)) {
        AppLogger.validationError('end_date', 'End date must be after start date');
        throw ApiError(
          message: 'End date must be after start date',
          statusCode: 400,
        );
      }

      if (start.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        AppLogger.validationError('start_date', 'Start date cannot be in the past');
        throw ApiError(
          message: 'Start date cannot be in the past',
          statusCode: 400,
        );
      }

      final requestBody = {
        'product_id': productId,
        'start_date': startDate,
        'end_date': endDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      AppLogger.apiRequest('POST', url, body: requestBody, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('📅 Creating rental for product $productId: $startDate to $endDate');

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode(requestBody),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final rental = Rental.fromJson(responseData['data']);
        AppLogger.i('✅ Rental created successfully: ID ${rental.id}');
        return rental;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('createRental', e);
      AppLogger.e('Failed to create rental', e, stackTrace);
      throw ApiError(message: 'Network error: ${e.toString()}', statusCode: 0);
    }
  }

  /// Get user's rentals
  Future<List<Rental>> getUserRentals() async {
    final url = ApiConfig.userRentals;
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('getUserRentals', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('GET', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('📅 Fetching user rentals');

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final List<dynamic> rentalsJson = responseData['data'];
        final rentals = rentalsJson.map((json) => Rental.fromJson(json)).toList();
        AppLogger.i('✅ Retrieved ${rentals.length} user rentals');
        return rentals;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getUserRentals', e);
      AppLogger.e('Failed to load user rentals', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get rentals for a specific product
  Future<List<Rental>> getProductRentals(int productId) async {
    final url = '${ApiConfig.products}/$productId/rentals';
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('getProductRentals', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('GET', url, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('📅 Fetching rentals for product $productId');

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final List<dynamic> rentalsJson = responseData['data'];
        final rentals = rentalsJson.map((json) => Rental.fromJson(json)).toList();
        AppLogger.i('✅ Retrieved ${rentals.length} rentals for product $productId');
        return rentals;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getProductRentals', e);
      AppLogger.e('Failed to load product rentals', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Update rental status (product owner only)
  Future<Rental> updateRentalStatus({
    required int rentalId,
    required String status,
    String? notes,
  }) async {
    final url = '${ApiConfig.rentals}/$rentalId';
    final body = {
      'status': status,
      if (notes != null) 'notes': notes,
    };
    
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.authError('updateRentalStatus', 'No authentication token found');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      AppLogger.apiRequest('PUT', url, body: body, headers: ApiConfig.getAuthHeaders(token));
      AppLogger.i('✏️ Updating rental $rentalId status to $status');

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
        final rental = Rental.fromJson(responseData['data']);
        AppLogger.i('✅ Rental status updated successfully: ID $rentalId -> $status');
        return rental;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('updateRentalStatus', e);
      AppLogger.e('Failed to update rental status', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}
