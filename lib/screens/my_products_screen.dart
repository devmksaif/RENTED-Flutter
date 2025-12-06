import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/product.dart';
import '../models/api_error.dart';
import '../services/product_service.dart';
import '../config/app_theme.dart';
import '../mixins/refresh_on_focus_mixin.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen>
    with WidgetsBindingObserver, RefreshOnFocusMixin, RefreshOnNavigationMixin {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  Future<void> onRefresh() async {
    // Refresh products when app comes back to foreground
    await _loadProducts();
  }

  @override
  Future<void> onNavigationRefresh() async {
    // Refresh products when screen is focused/navigated to
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getUserProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (e.statusCode == 401) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadProducts,
              color: AppTheme.primaryGreen,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return _buildProductCard(product);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No products yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first product listing',
            style: TextStyle(fontSize: 14, color: theme.hintColor),
          ),
          const SizedBox(height: 32),
          
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: product.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: theme.cardColor,
                  child: product.thumbnail.isNotEmpty
                      ? Image.network(
                          product.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported,
                            color: theme.hintColor,
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          color: theme.hintColor,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$${product.pricePerDay}/day',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: product.isAvailable
                                ? AppTheme.accentGreen
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.isAvailable ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              fontSize: 10,
                              color: product.isAvailable
                                  ? AppTheme.darkGreen
                                  : Colors.red[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_off, size: 20),
                        SizedBox(width: 8),
                        Text('Toggle Availability'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteProduct(product);
                  } else if (value == 'toggle') {
                    _toggleAvailability(product);
                  } else if (value == 'edit') {
                    // Navigate to edit product screen
                    Navigator.pushNamed(
                      context,
                      '/edit-product',
                      arguments: product.id,
                    ).then((_) => _loadProducts());
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAvailability(Product product) async {
    final newAvailability = !product.isAvailable;
    
    // Optimistically update UI immediately
    setState(() {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        // Create updated product with new availability
        _products[index] = Product(
          id: product.id,
          title: product.title,
          description: product.description,
          pricePerDay: product.pricePerDay,
          pricePerWeek: product.pricePerWeek,
          pricePerMonth: product.pricePerMonth,
          isForSale: product.isForSale,
          salePrice: product.salePrice,
          isAvailable: newAvailability,
          verificationStatus: product.verificationStatus,
          rejectionReason: product.rejectionReason,
          verifiedAt: product.verifiedAt,
          thumbnail: product.thumbnail,
          images: product.images,
          category: product.category,
          owner: product.owner,
          locationAddress: product.locationAddress,
          locationCity: product.locationCity,
          locationState: product.locationState,
          locationCountry: product.locationCountry,
          locationZip: product.locationZip,
          locationLatitude: product.locationLatitude,
          locationLongitude: product.locationLongitude,
          deliveryAvailable: product.deliveryAvailable,
          deliveryFee: product.deliveryFee,
          deliveryRadiusKm: product.deliveryRadiusKm,
          pickupAvailable: product.pickupAvailable,
          productCondition: product.productCondition,
          securityDeposit: product.securityDeposit,
          minRentalDays: product.minRentalDays,
          maxRentalDays: product.maxRentalDays,
          createdAt: product.createdAt,
          updatedAt: product.updatedAt,
        );
      }
    });

    try {
      await _productService.updateProduct(
        productId: product.id,
        isAvailable: newAvailability,
      );
      Fluttertoast.showToast(
        msg: newAvailability
            ? 'Product is now available'
            : 'Product is now unavailable',
        backgroundColor: Colors.green,
      );
      // Refresh to get latest data from server
      _loadProducts();
    } on ApiError catch (e) {
      // Revert on error
      setState(() {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product; // Revert to original
        }
      });
      Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            'Delete Product',
            style: TextStyle(color: theme.textTheme.titleLarge?.color),
          ),
          content: Text(
            'Are you sure you want to delete "${product.title}"? This action cannot be undone.',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Optimistically remove from UI
      setState(() {
        _products.removeWhere((p) => p.id == product.id);
      });

      try {
        await _productService.deleteProduct(product.id);
        Fluttertoast.showToast(
          msg: 'Product deleted successfully',
          backgroundColor: Colors.green,
        );
        // Refresh to ensure consistency
        _loadProducts();
      } on ApiError catch (e) {
        // Revert on error
        setState(() {
          _products.add(product);
          _products.sort((a, b) => b.id.compareTo(a.id)); // Keep sorted
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
      }
    }
  }
}
