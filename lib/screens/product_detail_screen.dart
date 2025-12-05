import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/product.dart';
import '../models/api_error.dart';
import '../services/product_service.dart';
import '../services/rental_service.dart';
import '../services/purchase_service.dart';
import '../services/review_service.dart';
import '../services/rental_availability_service.dart';
import '../services/message_service.dart';
import '../services/storage_service.dart';
import '../widgets/availability_calendar.dart';
import '../utils/logger.dart';
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
  final ReviewService _reviewService = ReviewService();
  final RentalAvailabilityService _availabilityService = RentalAvailabilityService();
  final MessageService _messageService = MessageService();
  final StorageService _storageService = StorageService();

  Product? _product;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _ratingStats;
  bool _loadingReviews = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadProduct();
    _loadReviews();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final user = await _storageService.getUser();
      if (mounted) {
        setState(() {
          _currentUserId = user?.id;
        });
      }
    } catch (e) {
      // Silently fail
    }
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

  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
    });

    try {
      AppLogger.i('📖 Loading reviews for product ${widget.productId}');
      final reviews = await _reviewService.getProductReviews(widget.productId);
      final rating = await _reviewService.getProductRating(widget.productId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _ratingStats = rating;
          _loadingReviews = false;
        });
        AppLogger.i('✅ Loaded ${reviews.length} reviews and rating stats');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to load reviews for product ${widget.productId}', e, stackTrace);
      if (mounted) {
        setState(() {
          _loadingReviews = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false, // Allow images to go under status bar
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _product == null
            ? const Center(child: Text('Product not found'))
            : _buildProductDetail(),
      ),
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
                                : Colors.white.withValues(alpha: 0.5),
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
                        backgroundImage: product.owner!.avatarUrl != null && product.owner!.avatarUrl!.isNotEmpty
                            ? NetworkImage(product.owner!.avatarUrl!)
                            : null,
                        child: product.owner!.avatarUrl == null || product.owner!.avatarUrl!.isEmpty
                            ? Text(
                                product.owner!.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      title: Text(product.owner!.name),
                      subtitle: Text(product.owner!.email),
                      trailing: product.owner!.isVerified
                          ? const Icon(Icons.verified, color: Colors.blue)
                          : null,
                    ),
                  ),
                const SizedBox(height: 24),
                // Availability Calendar (if owner)
                if (_product!.owner != null &&
                    _currentUserId == _product!.owner!.id)
                  _buildAvailabilitySection(),
                const SizedBox(height: 24),
                // Reviews Section
                _buildReviewsSection(),
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contact Owner button
            if (product.owner != null && _currentUserId != product.owner!.id)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _contactOwner(),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contact Owner'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
            if (product.owner != null && _currentUserId != product.owner!.id)
              const SizedBox(height: 12),
            // Show message if product is not available for rental/purchase
            if (product.owner != null && _currentUserId == product.owner!.id)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is your product. You cannot rent or purchase your own items.',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (product.verificationStatus != 'approved')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.verificationStatus == 'pending'
                            ? 'This product is pending approval and not available for rental yet.'
                            : 'This product is not available for rental.',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (!product.isAvailable)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This product is currently not available for rental.',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  // Only show Rent button if user is not the owner and product is approved and available
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
          ],
        ),
      ),
    );
  }

  void _showRentalDialog() {
    DateTime? startDate;
    DateTime? endDate;
    bool checkingAvailability = false;
    bool isAvailable = true;
    String? availabilityError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rent Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(
                  startDate != null
                      ? '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'
                      : 'Select start date',
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryGreen,
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppTheme.primaryGreen,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setDialogState(() {
                      startDate = picked;
                      // Reset end date if it's before the new start date
                      if (endDate != null && endDate!.isBefore(picked)) {
                        endDate = null;
                      }
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
                trailing: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryGreen,
                ),
                onTap: startDate == null
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate!.add(const Duration(days: 1)),
                          firstDate: startDate!.add(const Duration(days: 1)),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primaryGreen,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endDate = picked;
                          });
                        }
                      },
                enabled: startDate != null,
              ),
              if (startDate != null && endDate != null) ...[
                const SizedBox(height: 16),
                if (checkingAvailability)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else if (!isAvailable)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            availabilityError ?? 'Product not available for selected dates',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Duration:'),
                            Text(
                              '${endDate!.difference(startDate!).inDays + 1} days',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:'),
                            Text(
                              '\$${(double.parse(_product!.pricePerDay) * (endDate!.difference(startDate!).inDays + 1)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: checkingAvailability
                      ? null
                      : () async {
                          setDialogState(() {
                            checkingAvailability = true;
                            isAvailable = true;
                            availabilityError = null;
                          });
                          try {
                            final startDateStr = startDate!.toIso8601String().split('T')[0];
                            final endDateStr = endDate!.toIso8601String().split('T')[0];
                            final result = await _availabilityService.checkAvailability(
                              productId: widget.productId,
                              startDate: startDateStr,
                              endDate: endDateStr,
                            );
                            setDialogState(() {
                              checkingAvailability = false;
                              isAvailable = result['available'] ?? false;
                              availabilityError = result['message'];
                            });
                          } catch (e) {
                            setDialogState(() {
                              checkingAvailability = false;
                              isAvailable = false;
                              availabilityError = e.toString();
                            });
                          }
                        },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Check Availability'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: startDate != null && endDate != null && isAvailable && !checkingAvailability
                  ? () {
                      final startDateStr = startDate!.toIso8601String().split(
                        'T',
                      )[0];
                      final endDateStr = endDate!.toIso8601String().split(
                        'T',
                      )[0];
                      Navigator.pop(context);
                      _createRental(startDateStr, endDateStr);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
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

  Future<void> _contactOwner() async {
    if (_product == null || _product!.owner == null) return;

    try {
      // Send an initial message to create conversation
      final result = await _messageService.sendMessage(
        receiverId: _product!.owner!.id,
        productId: _product!.id,
        content: 'Hi! I\'m interested in "${_product!.title}"',
      );

      // Navigate to chat screen with the conversation ID
      if (mounted && result['conversation_id'] != null) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: result['conversation_id'],
        );
      } else if (mounted && result['conversation'] != null) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: result['conversation']['id'],
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to start conversation',
          backgroundColor: Colors.red,
        );
      }
    } on ApiError catch (e) {
      Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
    }
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              children: [
                if (_ratingStats != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_ratingStats!['average_rating'].toStringAsFixed(1)} (${_ratingStats!['review_count']})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => _showReviewDialog(),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Write Review'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No reviews yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          ..._reviews.map((review) {
            final isOwnReview = _currentUserId != null &&
                review['user']?['id'] == _currentUserId;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    (review['user']?['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(review['user']?['name'] ?? 'Anonymous'),
                          const SizedBox(width: 8),
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < (review['rating'] as int? ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwnReview)
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, size: 18),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                            onTap: () {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () => _showEditReviewDialog(review),
                              );
                            },
                          ),
                          PopupMenuItem(
                            child: const Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                            onTap: () {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () => _showDeleteReviewDialog(review),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (review['comment'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(review['comment']),
                      ),
                    if (review['created_at'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatDate(review['created_at']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showReviewDialog() {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rating'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Share your experience...',
                  ),
                  maxLines: 4,
                  maxLength: 1000,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  AppLogger.i('📝 Submitting review for product ${widget.productId}');
                  await _reviewService.createReview(
                    productId: widget.productId,
                    rating: selectedRating,
                    comment: commentController.text.trim().isEmpty
                        ? null
                        : commentController.text.trim(),
                  );
                  if (mounted) {
                    AppLogger.i('✅ Review submitted successfully');
                    Fluttertoast.showToast(
                      msg: 'Review submitted successfully',
                      backgroundColor: Colors.green,
                    );
                    _loadReviews();
                  }
                } on ApiError catch (e) {
                  AppLogger.e('Failed to submit review: ${e.message}', e);
                  Fluttertoast.showToast(
                    msg: e.message,
                    backgroundColor: Colors.red,
                  );
                } catch (e, stackTrace) {
                  AppLogger.e('Unexpected error submitting review', e, stackTrace);
                  Fluttertoast.showToast(
                    msg: 'An unexpected error occurred',
                    backgroundColor: Colors.red,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReviewDialog(Map<String, dynamic> review) {
    int selectedRating = review['rating'] as int? ?? 5;
    final commentController = TextEditingController(
      text: review['comment'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rating'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Share your experience...',
                  ),
                  maxLines: 4,
                  maxLength: 1000,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final reviewId = review['id'] as int;
                  AppLogger.i('✏️ Updating review $reviewId');
                  await _reviewService.updateReview(
                    reviewId: reviewId,
                    rating: selectedRating,
                    comment: commentController.text.trim().isEmpty
                        ? null
                        : commentController.text.trim(),
                  );
                  if (mounted) {
                    AppLogger.i('✅ Review updated successfully');
                    Fluttertoast.showToast(
                      msg: 'Review updated successfully',
                      backgroundColor: Colors.green,
                    );
                    _loadReviews();
                  }
                } on ApiError catch (e) {
                  AppLogger.e('Failed to update review: ${e.message}', e);
                  Fluttertoast.showToast(
                    msg: e.message,
                    backgroundColor: Colors.red,
                  );
                } catch (e, stackTrace) {
                  AppLogger.e('Unexpected error updating review', e, stackTrace);
                  Fluttertoast.showToast(
                    msg: 'An unexpected error occurred',
                    backgroundColor: Colors.red,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteReviewDialog(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final reviewId = review['id'] as int;
                AppLogger.i('🗑️ Deleting review $reviewId');
                await _reviewService.deleteReview(reviewId);
                if (mounted) {
                  AppLogger.i('✅ Review deleted successfully');
                  Fluttertoast.showToast(
                    msg: 'Review deleted successfully',
                    backgroundColor: Colors.green,
                  );
                  _loadReviews();
                }
              } on ApiError catch (e) {
                AppLogger.e('Failed to delete review: ${e.message}', e);
                Fluttertoast.showToast(
                  msg: e.message,
                  backgroundColor: Colors.red,
                );
              } catch (e, stackTrace) {
                AppLogger.e('Unexpected error deleting review', e, stackTrace);
                Fluttertoast.showToast(
                  msg: 'An unexpected error occurred',
                  backgroundColor: Colors.red,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Manage Availability',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ElevatedButton.icon(
              onPressed: () => _showBlockDatesDialog(),
              icon: const Icon(Icons.block, size: 18),
              label: const Text('Block Dates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AvailabilityCalendar(
          productId: widget.productId,
          isOwner: true,
        ),
      ],
    );
  }

  void _showBlockDatesDialog() {
    final selectedDates = <String>[];
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Block Dates for Maintenance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Camera maintenance scheduled',
                  ),
                  maxLines: 2,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select dates to block (tap dates on calendar)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                AvailabilityCalendar(
                  productId: widget.productId,
                  isOwner: true,
                  onDatesSelected: (dates) {
                    setDialogState(() {
                      selectedDates.clear();
                      selectedDates.addAll(dates);
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedDates.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(context);
                      try {
                        await _availabilityService.blockDatesForMaintenance(
                          productId: widget.productId,
                          dates: selectedDates,
                          notes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                        );
                        if (mounted) {
                          Fluttertoast.showToast(
                            msg: 'Dates blocked successfully',
                            backgroundColor: Colors.green,
                          );
                        }
                      } on ApiError catch (e) {
                        Fluttertoast.showToast(
                          msg: e.message,
                          backgroundColor: Colors.red,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Block ${selectedDates.length} Date(s)'),
            ),
          ],
        ),
      ),
    );
  }
}
