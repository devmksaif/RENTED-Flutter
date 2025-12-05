import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as cat;
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<cat.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<cat.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load products with optimistic update support
  Future<void> loadProducts({int page = 1, int perPage = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final products = await _productService.getProducts(
        page: page,
        perPage: perPage,
      );
      _products = products;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _productService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Create product with optimistic update
  /// Immediately adds product to UI, then updates with real data from server
  Future<Product?> createProduct({
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
    required List<String> imagePaths,
  }) async {
    // Find category for optimistic product
    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => cat.Category(
        id: categoryId,
        name: 'Unknown',
        slug: 'unknown',
        description: null,
        isActive: true,
      ),
    );

    // Create temporary optimistic product with local image paths
    final optimisticProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      title: title,
      description: description,
      pricePerDay: pricePerDay.toString(),
      pricePerWeek: pricePerWeek?.toString(),
      pricePerMonth: pricePerMonth?.toString(),
      isForSale: isForSale,
      salePrice: salePrice?.toString(),
      isAvailable: true,
      thumbnail: imagePaths.isNotEmpty ? imagePaths[0] : '',
      images: imagePaths,
      category: category,
      owner: null,
      locationAddress: locationAddress,
      locationCity: locationCity,
      locationState: locationState,
      locationCountry: locationCountry,
      locationZip: locationZip,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      deliveryAvailable: deliveryAvailable,
      deliveryFee: deliveryFee?.toString(),
      deliveryRadiusKm: deliveryRadiusKm,
      pickupAvailable: pickupAvailable,
      productCondition: productCondition,
      securityDeposit: securityDeposit?.toString(),
      minRentalDays: minRentalDays,
      maxRentalDays: maxRentalDays,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add optimistically to the list (at the beginning)
    _products.insert(0, optimisticProduct);
    notifyListeners();

    try {
      // Create on server
      final createdProduct = await _productService.createProduct(
        categoryId: categoryId,
        title: title,
        description: description,
        pricePerDay: pricePerDay,
        isForSale: isForSale,
        salePrice: salePrice,
        pricePerWeek: pricePerWeek,
        pricePerMonth: pricePerMonth,
        securityDeposit: securityDeposit,
        minRentalDays: minRentalDays,
        maxRentalDays: maxRentalDays,
        locationAddress: locationAddress,
        locationCity: locationCity,
        locationState: locationState,
        locationCountry: locationCountry,
        locationZip: locationZip,
        locationLatitude: locationLatitude,
        locationLongitude: locationLongitude,
        deliveryAvailable: deliveryAvailable,
        deliveryFee: deliveryFee,
        deliveryRadiusKm: deliveryRadiusKm,
        pickupAvailable: pickupAvailable,
        productCondition: productCondition,
        imagePaths: imagePaths,
      );

      // Replace optimistic product with real one
      final index = _products.indexWhere((p) => p.id == optimisticProduct.id);
      if (index != -1) {
        _products[index] = createdProduct;
        notifyListeners();
      }

      return createdProduct;
    } catch (e) {
      // Remove optimistic product on error
      _products.removeWhere((p) => p.id == optimisticProduct.id);
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update product with optimistic update
  Future<Product?> updateProduct({
    required int productId,
    int? categoryId,
    String? title,
    String? description,
    double? pricePerDay,
    bool? isForSale,
    double? salePrice,
    bool? isAvailable,
    List<String>? newImagePaths,
  }) async {
    // Find existing product
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return null;

    final oldProduct = _products[index];

    // Create optimistic updated product
    final optimisticProduct = Product(
      id: oldProduct.id,
      title: title ?? oldProduct.title,
      description: description ?? oldProduct.description,
      pricePerDay: pricePerDay?.toString() ?? oldProduct.pricePerDay,
      isForSale: isForSale ?? oldProduct.isForSale,
      salePrice: salePrice?.toString() ?? oldProduct.salePrice,
      isAvailable: isAvailable ?? oldProduct.isAvailable,
      thumbnail: newImagePaths != null && newImagePaths.isNotEmpty
          ? newImagePaths[0]
          : oldProduct.thumbnail,
      images: newImagePaths ?? oldProduct.images,
      category: oldProduct.category,
      owner: oldProduct.owner,
      createdAt: oldProduct.createdAt,
      updatedAt: DateTime.now(),
    );

    // Update optimistically
    _products[index] = optimisticProduct;
    notifyListeners();

    try {
      // Update on server
      final updatedProduct = await _productService.updateProduct(
        productId: productId,
        categoryId: categoryId,
        title: title,
        description: description,
        pricePerDay: pricePerDay,
        isForSale: isForSale,
        salePrice: salePrice,
        isAvailable: isAvailable,
        newImagePaths: newImagePaths,
      );

      // Replace with real data
      _products[index] = updatedProduct;
      notifyListeners();

      return updatedProduct;
    } catch (e) {
      // Rollback on error
      _products[index] = oldProduct;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete product with optimistic update
  Future<void> deleteProduct(int productId) async {
    // Find and remove optimistically
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    final removedProduct = _products[index];
    _products.removeAt(index);
    notifyListeners();

    try {
      // Delete on server
      await _productService.deleteProduct(productId);
    } catch (e) {
      // Rollback on error
      _products.insert(index, removedProduct);
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get single product by ID
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
