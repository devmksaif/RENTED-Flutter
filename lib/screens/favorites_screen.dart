import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/favorite_service.dart';
import '../models/product.dart';
import '../models/api_error.dart';
import '../mixins/refresh_on_focus_mixin.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen>
    with WidgetsBindingObserver, RefreshOnFocusMixin, AutomaticKeepAliveClientMixin {
  final FavoriteService _favoriteService = FavoriteService();
  List<Product> _favoriteProducts = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  @override
  Future<void> onRefresh() async {
    // Refresh favorites when screen comes into focus
    await loadFavorites();
  }

  // Public method to load favorites (can be called from MainNavigation)
  Future<void> loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final favorites = await _favoriteService.getFavorites();

      if (mounted) {
        setState(() {
          _favoriteProducts = favorites;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (e.statusCode == 401) {
          Fluttertoast.showToast(
            msg: 'Please login to view favorites',
            backgroundColor: Colors.orange,
          );
        } else {
          Fluttertoast.showToast(
            msg: e.message,
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Failed to load favorites',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _removeFavorite(int productId) async {
    // Optimistic update - remove immediately from UI
    final removedProduct = _favoriteProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => _favoriteProducts.first,
    );
    setState(() {
      _favoriteProducts.removeWhere((p) => p.id == productId);
    });

    try {
      await _favoriteService.removeFromFavorites(productId);
      Fluttertoast.showToast(
        msg: 'Removed from favorites',
        backgroundColor: Colors.orange,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        if (!_favoriteProducts.any((p) => p.id == productId)) {
          _favoriteProducts.add(removedProduct);
        }
      });
      Fluttertoast.showToast(
        msg: 'Failed to remove favorite',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: responsive.fontSize(20),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteProducts.isEmpty
          ? Center(
              child: Padding(
                padding: responsive.responsivePadding(mobile: 24, tablet: 32, desktop: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(responsive.spacing(24)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_outline,
                        size: responsive.iconSize(64),
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(24)),
                    Text(
                      'No favorites yet',
                      style: TextStyle(
                        fontSize: responsive.fontSize(22),
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(8)),
                    Text(
                      'Save your favorite products here',
                      style: TextStyle(fontSize: 14, color: theme.hintColor),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.search),
                      label: const Text(
                        'Browse Products',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadFavorites,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive grid: 1 column on small screens, 2 on medium, 3 on large
                  final crossAxisCount = constraints.maxWidth > 600
                      ? (constraints.maxWidth > 900 ? 3 : 2)
                      : 2;
                  final spacing = constraints.maxWidth > 600 ? 16.0 : 12.0;
                  
                  return GridView.builder(
                    padding: EdgeInsets.all(spacing),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    itemCount: _favoriteProducts.length,
                    itemBuilder: (context, index) {
                      final product = _favoriteProducts[index];
                      return _buildProductCard(product);
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            await Navigator.pushNamed(
              context,
              '/product-detail',
              arguments: product.id,
            );
            // Reload favorites after returning to ensure instant updates
            if (mounted) {
              await loadFavorites();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with gradient overlay
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.network(
                          product.thumbnail,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: theme.cardColor,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: theme.cardColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: theme.hintColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No Image',
                                style: TextStyle(
                                  color: theme.hintColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ),
                    ),
                    // Gradient overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _removeFavorite(product.id),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Category badge (if available)
                    if (product.category.name != null &&
                        product.category.name != 'Unknown')
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.category.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Product Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.3,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Price and availability
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\$${product.pricePerDay}',
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '/day',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Availability indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: product.isAvailable
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: product.isAvailable
                                        ? Colors.green
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.isAvailable ? 'Available' : 'Unavailable',
                                  style: TextStyle(
                                    color: product.isAvailable
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
