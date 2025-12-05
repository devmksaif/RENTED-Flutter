import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/api_error.dart';
import '../services/product_service.dart';
import '../services/favorite_service.dart';
import '../utils/responsive_utils.dart';
import '../mixins/refresh_on_focus_mixin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RefreshOnFocusMixin {
  final ProductService _productService = ProductService();
  final FavoriteService _favoriteService = FavoriteService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  // Filter variables
  Category? _selectedCategory;
  double _minPrice = 0;
  double _maxPrice = 1000;
  String _selectedLocation = 'All';
  double _minRating = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> onRefresh() async {
    // Silently refresh data when screen comes into focus
    await _loadProducts();
    await _loadCategories();
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

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getProducts(page: 1, perPage: 50);

      if (mounted) {
        setState(() {
          _products = products;
          _applyFilters();
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
          Fluttertoast.showToast(
            msg: e.message,
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Error loading products: ${e.toString()}',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  void _filterByCategory(String categoryName) {
    final category = _categories.firstWhere(
      (cat) => cat.name.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => _categories.firstWhere(
        (cat) => cat.name.toLowerCase().contains(categoryName.toLowerCase()),
        orElse: () => Category(id: 0, name: categoryName, slug: '', isActive: true),
      ),
    );
    setState(() {
      _selectedCategory = category.id != 0 ? category : null;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _products.where((product) {
        // Search filter
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          if (!product.title.toLowerCase().contains(searchLower) &&
              !product.description.toLowerCase().contains(searchLower)) {
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
    });
  }

  void _showFilterDialog() {
    final responsive = ResponsiveUtils(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: responsive.screenHeight * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: EdgeInsets.only(
                  bottom: responsive.keyboardHeight + responsive.spacing(20),
                  left: responsive.spacing(20),
                  right: responsive.spacing(20),
                  top: responsive.spacing(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                    setModalState(
                                      () => _selectedCategory = null,
                                    );
                                    setState(() => _selectedCategory = null);
                                  },
                                  selectedColor: const Color(0xFF4CAF50),
                                  labelStyle: TextStyle(
                                    color: _selectedCategory == null
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                ..._categories.map(
                                  (category) => FilterChip(
                                    label: Text(category.name),
                                    selected:
                                        _selectedCategory?.id == category.id,
                                    onSelected: (selected) {
                                      setModalState(
                                        () => _selectedCategory = selected
                                            ? category
                                            : null,
                                      );
                                      setState(
                                        () => _selectedCategory = selected
                                            ? category
                                            : null,
                                      );
                                    },
                                    selectedColor: const Color(0xFF4CAF50),
                                    labelStyle: TextStyle(
                                      color:
                                          _selectedCategory?.id == category.id
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
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
                                    activeColor: const Color(0xFF4CAF50),
                                    onChanged: (values) {
                                      setModalState(() {
                                        _minPrice = values.start;
                                        _maxPrice = values.end;
                                      });
                                      setState(() {
                                        _minPrice = values.start;
                                        _maxPrice = values.end;
                                      });
                                    },
                                  ),
                                ),
                                Text('\$${_maxPrice.toInt()}'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  [
                                        'All',
                                        'Downtown',
                                        'Suburbs',
                                        'North',
                                        'South',
                                        'East',
                                        'West',
                                      ]
                                      .map(
                                        (location) => FilterChip(
                                          label: Text(location),
                                          selected:
                                              _selectedLocation == location,
                                          onSelected: (selected) {
                                            setModalState(
                                              () =>
                                                  _selectedLocation = location,
                                            );
                                            setState(
                                              () =>
                                                  _selectedLocation = location,
                                            );
                                          },
                                          selectedColor: const Color(
                                            0xFF4CAF50,
                                          ),
                                          labelStyle: TextStyle(
                                            color: _selectedLocation == location
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Minimum Rating',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(5, (index) {
                                  final rating = index + 1.0;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                          Text(' $rating'),
                                        ],
                                      ),
                                      selected: _minRating == rating,
                                      onSelected: (selected) {
                                        setModalState(
                                          () => _minRating = selected
                                              ? rating
                                              : 0,
                                        );
                                        setState(
                                          () => _minRating = selected
                                              ? rating
                                              : 0,
                                        );
                                      },
                                      selectedColor: const Color(0xFF4CAF50),
                                      labelStyle: TextStyle(
                                        color: _minRating == rating
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setModalState(() {
                                        _selectedCategory = null;
                                        _minPrice = 0;
                                        _maxPrice = 1000;
                                        _selectedLocation = 'All';
                                        _minRating = 0;
                                      });
                                      setState(() {
                                        _selectedCategory = null;
                                        _minPrice = 0;
                                        _maxPrice = 1000;
                                        _selectedLocation = 'All';
                                        _minRating = 0;
                                        _applyFilters();
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                    child: const Text('Reset'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _applyFilters();
                                      Navigator.pop(context);
                                      Fluttertoast.showToast(
                                        msg: 'Filters applied',
                                        backgroundColor: Colors.green,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Apply Filters'),
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
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      body: SafeArea(
        top: false, // Allow content to go under status bar for header image
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: responsive.screenHeight * 0.5,
              floating: false,
              pinned: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Positioned.fill(
                      child: Stack(
                        children: [
                          Image.network(
                            'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=1200',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.home,
                                    size: 100,
                                    color: Colors.grey[400],
                                  ),
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(color: Colors.green.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        SafeArea(
                          bottom: false,
                          child: Container(
                            color: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing(24),
                              vertical: responsive.spacing(16),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'RENTED',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4CAF50),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 5),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                Spacer(),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/add-product',
                                    );
                                  },
                                  child: Text('+  List Item'),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: Icon(
                                    Icons.notifications,
                                    color: Colors.grey,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/notifications',
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.account_circle),
                                  color: Color(0xFF4CAF50),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/profile');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rent Anything You Need',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Access thousands of items in your neighborhood',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Hero(
                                tag: 'searchBar',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: 400,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.search, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'What are you looking for?',
                                              hintStyle: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                            ),
                                            onChanged: (value) =>
                                                _applyFilters(),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.tune,
                                            color: Color(0xFF4CAF50),
                                          ),
                                          onPressed: _showFilterDialog,
                                          tooltip: 'Filters',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Popular tags
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Popular:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _PopularTag(
                                    text: 'Cameras',
                                    onTap: () => _filterByCategory('Cameras'),
                                  ),
                                  _PopularTag(
                                    text: 'Bikes',
                                    onTap: () => _filterByCategory('Bikes'),
                                  ),
                                  _PopularTag(
                                    text: 'Tools',
                                    onTap: () => _filterByCategory('Tools'),
                                  ),
                                  _PopularTag(
                                    text: 'Furniture',
                                    onTap: () => _filterByCategory('Furniture'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Scrollable listed items
            SliverPadding(
              padding: responsive.responsivePadding(mobile: 16),
              sliver: _isLoading
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    )
                  : _filteredProducts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No products available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverGrid(
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
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _buildProductCard(_filteredProducts[index]);
                      }, childCount: _filteredProducts.length),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final imageHeight = cardWidth * 0.75; // Responsive image height

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: product.thumbnail.isNotEmpty
                        ? Image.network(
                            product.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                              size: cardWidth * 0.25,
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey[400],
                            size: cardWidth * 0.25,
                          ),
                  ),
                ),
                // Product Info
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.all(cardWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.title,
                          style: TextStyle(
                            fontSize: cardWidth * 0.08,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: cardWidth * 0.02),
                        Text(
                          product.category.name,
                          style: TextStyle(
                            fontSize: cardWidth * 0.06,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: cardWidth * 0.03),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${product.pricePerDay}',
                                    style: TextStyle(
                                      fontSize: cardWidth * 0.09,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                  ),
                                  Text(
                                    'per day',
                                    style: TextStyle(
                                      fontSize: cardWidth * 0.055,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FutureBuilder<bool>(
                              future: _favoriteService.isFavorite(product.id),
                              builder: (context, snapshot) {
                                final isFavorite = snapshot.data ?? false;
                                return IconButton(
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite
                                        ? Colors.red
                                        : Colors.grey[400],
                                    size: cardWidth * 0.1,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    try {
                                      final newFavoriteStatus =
                                          await _favoriteService.toggleFavorite(
                                        product.id,
                                      );
                                      setState(() {}); // Refresh UI
                                      Fluttertoast.showToast(
                                        msg: newFavoriteStatus
                                            ? 'Added to favorites'
                                            : 'Removed from favorites',
                                        backgroundColor: newFavoriteStatus
                                            ? Colors.green
                                            : Colors.orange,
                                      );
                                    } catch (e) {
                                      Fluttertoast.showToast(
                                        msg: 'Failed to update favorite',
                                        backgroundColor: Colors.red,
                                      );
                                    }
                                  },
                                );
                              },
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
      },
    );
  }
}

class _PopularTag extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _PopularTag({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
