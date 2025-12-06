import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/api_error.dart';
import '../models/pagination_response.dart';
import '../services/product_service.dart';
import '../services/favorite_service.dart';
import '../utils/responsive_utils.dart';
import '../config/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  final FavoriteService _favoriteService = FavoriteService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  int _totalProducts = 0;
  Set<int> _favoriteProductIds = {}; // Track favorite product IDs

  // Filter variables
  Category? _selectedCategory;
  double _minPrice = 0;
  double _maxPrice = 1000;
  String _sortBy = 'newest'; // newest, price_low, price_high, rating
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await _productService.getProducts(page: 1, perPage: 20);
      final products = result['products'] as List<Product>;
      final pagination = result['pagination'] as PaginationResponse?;

      if (mounted) {
        // Load favorite status for all products
        await _loadFavoriteStatuses(products);
        
        setState(() {
          _allProducts = products;
          _currentPage = 1;
          if (pagination != null) {
            _hasMore = pagination.hasMore;
            _totalProducts = pagination.total;
          } else {
            _hasMore = products.length >= 20;
          }
          _applyFilters();
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: e.message,
          backgroundColor: AppTheme.errorRed,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Error loading products',
          backgroundColor: AppTheme.errorRed,
        );
      }
    }
  }

  /// Load favorite statuses for a list of products
  Future<void> _loadFavoriteStatuses(List<Product> products) async {
    final favoriteIds = <int>{..._favoriteProductIds}; // Keep existing favorites
    for (final product in products) {
      try {
        final isFavorite = await _favoriteService.isFavorite(product.id);
        if (isFavorite) {
          favoriteIds.add(product.id);
        } else {
          favoriteIds.remove(product.id); // Remove if not favorite
        }
      } catch (e) {
        // If check fails, continue with next product
        continue;
      }
    }
    setState(() {
      _favoriteProductIds = favoriteIds;
    });
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await _productService.getProducts(page: nextPage, perPage: 20);
      final products = result['products'] as List<Product>;
      final pagination = result['pagination'] as PaginationResponse?;

      if (mounted) {
        if (products.isEmpty) {
          setState(() {
            _hasMore = false;
            _isLoadingMore = false;
          });
        } else {
          // Load favorite statuses for newly loaded products
          await _loadFavoriteStatuses(products);
          
          setState(() {
            _allProducts.addAll(products);
            _currentPage = nextPage;
            if (pagination != null) {
              _hasMore = pagination.hasMore;
              _totalProducts = pagination.total;
            } else {
              _hasMore = products.length >= 20;
            }
            _applyFilters();
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // Only show approved products
        // If verification_status is null, assume backend is filtering and allow it
        // If verification_status is set, only allow 'approved'
        final status = product.verificationStatus;
        if (status != null && status != 'approved') {
          return false;
        }

        // Only show available products
        if (!product.isAvailable) {
          return false;
        }

        // Search filter
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          if (!product.title.toLowerCase().contains(searchLower) &&
              !product.description.toLowerCase().contains(searchLower) &&
              !product.category.name.toLowerCase().contains(searchLower)) {
            return false;
          }
        }

        // Category filter
        if (_selectedCategory != null &&
            product.category.id != _selectedCategory!.id) {
          return false;
        }

        // Price filter
        final price = double.tryParse(product.pricePerDay) ?? 0;
        if (price < _minPrice || price > _maxPrice) {
          return false;
        }

        return true;
      }).toList();

      // Apply sorting
      _sortProducts();
    });
  }

  void _sortProducts() {
    switch (_sortBy) {
      case 'price_low':
        _filteredProducts.sort((a, b) {
          final priceA = double.tryParse(a.pricePerDay) ?? 0;
          final priceB = double.tryParse(b.pricePerDay) ?? 0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_high':
        _filteredProducts.sort((a, b) {
          final priceA = double.tryParse(a.pricePerDay) ?? 0;
          final priceB = double.tryParse(b.pricePerDay) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'newest':
      default:
        _filteredProducts.sort((a, b) {
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _minPrice = 0;
      _maxPrice = 1000;
      _sortBy = 'newest';
      _searchController.clear();
      _applyFilters();
    });
  }

  Future<void> _toggleFavorite(Product product) async {
    try {
      final newFavoriteStatus = await _favoriteService.toggleFavorite(product.id);
      
      // Update favorite status in the set
      setState(() {
        if (newFavoriteStatus) {
          _favoriteProductIds.add(product.id);
        } else {
          _favoriteProductIds.remove(product.id);
        }
      });
      
      Fluttertoast.showToast(
        msg: newFavoriteStatus
            ? 'Added to favorites'
            : 'Removed from favorites',
        backgroundColor: newFavoriteStatus ? Colors.green : Colors.orange,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to update favorite',
        backgroundColor: AppTheme.errorRed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final hasActiveFilters = _selectedCategory != null ||
        _minPrice > 0 ||
        _maxPrice < 1000 ||
        _sortBy != 'newest' ||
        _searchController.text.isNotEmpty;

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Products',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_totalProducts > 0)
              Text(
                '$_totalProducts products',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: theme.hintColor,
                ),
              ),
          ],
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: hasActiveFilters ? AppTheme.primaryGreen : theme.hintColor,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: theme.cardColor,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
              ),
            ),
          ),
          // Filters Panel
          if (_showFilters) _buildFiltersPanel(),
          // Active Filters Chips
          if (hasActiveFilters) _buildActiveFiltersChips(),
          // Products Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: theme.hintColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                color: theme.hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadProducts(refresh: true),
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: responsive.gridColumns(
                              mobile: 2,
                              tablet: 3,
                              desktop: 4,
                            ),
                            childAspectRatio: responsive.cardAspectRatio,
                            crossAxisSpacing: responsive.spacing(10),
                            mainAxisSpacing: responsive.spacing(10),
                          ),
                          itemCount: _filteredProducts.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _filteredProducts.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildProductCard(_filteredProducts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    final theme = Theme.of(context);
    return Container(
      color: theme.cardColor,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Category Filter
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = null;
                    _applyFilters();
                  });
                },
                selectedColor: AppTheme.primaryGreen,
                labelStyle: TextStyle(
                  color: _selectedCategory == null ? Colors.white : theme.textTheme.bodyLarge?.color,
                ),
              ),
              ..._categories.map(
                (category) => FilterChip(
                  label: Text(category.name),
                  selected: _selectedCategory?.id == category.id,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                      _applyFilters();
                    });
                  },
                  selectedColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    color: _selectedCategory?.id == category.id
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Price Range
          const Text(
            'Price Range (per day)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('\$${_minPrice.toInt()}'),
              Expanded(
                child: RangeSlider(
                  values: RangeValues(_minPrice, _maxPrice),
                  min: 0,
                  max: 1000,
                  divisions: 100,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (values) {
                    setState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                      _applyFilters();
                    });
                  },
                ),
              ),
              Text('\$${_maxPrice.toInt()}'),
            ],
          ),
          const SizedBox(height: 20),
          // Sort By
          const Text(
            'Sort By',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip('newest', 'Newest'),
              _buildSortChip('price_low', 'Price: Low to High'),
              _buildSortChip('price_high', 'Price: High to Low'),
            ],
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String value, String label) {
    final theme = Theme.of(context);
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _sortBy = value;
          _applyFilters();
        });
      },
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    final theme = Theme.of(context);
    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_selectedCategory != null)
              Chip(
                label: Text(_selectedCategory!.name),
                onDeleted: () {
                  setState(() {
                    _selectedCategory = null;
                    _applyFilters();
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 18),
              ),
            if (_minPrice > 0 || _maxPrice < 1000)
              Chip(
                label: Text(
                  '\$${_minPrice.toInt()} - \$${_maxPrice.toInt()}',
                ),
                onDeleted: () {
                  setState(() {
                    _minPrice = 0;
                    _maxPrice = 1000;
                    _applyFilters();
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 18),
              ),
            if (_sortBy != 'newest')
              Chip(
                label: Text(_sortBy == 'price_low'
                    ? 'Price: Low to High'
                    : 'Price: High to Low'),
                onDeleted: () {
                  setState(() {
                    _sortBy = 'newest';
                    _applyFilters();
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      product.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.cardColor,
                        child: Icon(Icons.image_not_supported, color: theme.hintColor),
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
                        onTap: () => _toggleFavorite(product),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _favoriteProductIds.contains(product.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: _favoriteProductIds.contains(product.id)
                                ? Colors.red
                                : theme.hintColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Category badge
                  if (product.category.name != 'Unknown')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.9),
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
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${product.pricePerDay}',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
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
    );
  }
}

