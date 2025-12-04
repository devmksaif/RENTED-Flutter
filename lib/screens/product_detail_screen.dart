import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/product.dart';
import '../models/api_error.dart';
import '../services/product_service.dart';
import '../services/rental_service.dart';
import '../services/purchase_service.dart';
import '../config/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final RentalService _rentalService = RentalService();
  final PurchaseService _purchaseService = PurchaseService();

  Product? _product;
  bool _isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final product = await _productService.getProduct(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
          ? const Center(child: Text('Product not found'))
          : _buildProductDetail(),
      bottomSheet: _isLoading || _product == null ? null : _buildBottomSheet(),
    );
  }

  Widget _buildProductDetail() {
    final product = _product!;
    final images = product.images.isNotEmpty
        ? product.images
        : [product.thumbnail];

    return CustomScrollView(
      slivers: [
        // App Bar with Images
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Image Carousel
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return images[index].isNotEmpty
                        ? Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 64,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.inventory_2, size: 64),
                          );
                  },
                ),
                // Image Indicators
                if (images.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Category
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(product.category.name),
                  backgroundColor: AppTheme.accentGreen,
                ),
                const SizedBox(height: 16),
                // Pricing
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 20,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rental Price',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${product.pricePerDay}/day',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        if (product.isForSale) ...[
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(
                                Icons.shopping_cart,
                                size: 20,
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sale Price',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${product.salePrice}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                // Owner Info
                if (product.owner != null)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen,
                        child: Text(
                          product.owner!.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(product.owner!.name),
                      subtitle: Text(product.owner!.email),
                      trailing: product.owner!.isVerified
                          ? const Icon(Icons.verified, color: Colors.blue)
                          : null,
                    ),
                  ),
                const SizedBox(height: 80), // Space for bottom buttons
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomSheet() {
    final product = _product;
    if (product == null) return null;

    if (!product.isAvailable) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red[100],
        child: const SafeArea(
          child: Center(
            child: Text(
              'This product is currently unavailable',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showRentalDialog(),
                icon: const Icon(Icons.access_time),
                label: const Text('Rent'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (product.isForSale) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _purchaseProduct(),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Buy'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.darkGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRentalDialog() {
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rent Product'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(
                    startDate != null
                        ? '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'
                        : 'Select start date',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        startDate = picked;
                        startDateController.text = picked
                            .toIso8601String()
                            .split('T')[0];
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(
                    endDate != null
                        ? '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'
                        : 'Select end date',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        endDate = picked;
                        endDateController.text = picked.toIso8601String().split(
                          'T',
                        )[0];
                      });
                    }
                  },
                ),
                if (startDate != null && endDate != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Total: \$${(double.parse(_product!.pricePerDay) * (endDate!.difference(startDate!).inDays + 1)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: startDate != null && endDate != null
                ? () {
                    Navigator.pop(context);
                    _createRental(
                      startDateController.text,
                      endDateController.text,
                    );
                  }
                : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _createRental(String startDate, String endDate) async {
    try {
      await _rentalService.createRental(
        productId: _product!.id,
        startDate: startDate,
        endDate: endDate,
      );
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Rental request submitted successfully',
          backgroundColor: Colors.green,
        );
      }
    } on ApiError catch (e) {
      Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
    }
  }

  Future<void> _purchaseProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Product'),
        content: Text(
          'Do you want to purchase "${_product!.title}" for \$${_product!.salePrice}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _purchaseService.createPurchase(productId: _product!.id);
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Purchase completed successfully',
            backgroundColor: Colors.green,
          );
        }
      } on ApiError catch (e) {
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
      }
    }
  }
}
