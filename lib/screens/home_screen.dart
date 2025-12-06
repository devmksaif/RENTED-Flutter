import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/user.dart';
import '../models/api_error.dart';
import '../models/pagination_response.dart';
import '../services/product_service.dart';
import '../services/favorite_service.dart';
import '../services/storage_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/logger.dart';
import '../mixins/refresh_on_focus_mixin.dart';
import '../config/app_theme.dart';
import '../widgets/avatar_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RefreshOnFocusMixin {
  final ProductService _productService = ProductService();
  final FavoriteService _favoriteService = FavoriteService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  int _totalProducts = 0;
  User? _currentUser;

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
    _loadCurrentUser();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _storageService.getUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      // Handle error silently
    }
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
        setState(() {
          _products = products;
          _currentPage = 1;
          if (pagination != null) {
            _hasMore = pagination.hasMore;
            _totalProducts = pagination.total;
          } else {
            _hasMore = products.length >= 20; // Assume more if we got a full page
          }
          _applyFilters();
          _isLoading = false;
        });
        // Debug: Log filtering results
        AppLogger.d('📊 Total products: ${_totalProducts}, Loaded: ${_products.length}, Filtered: ${_filteredProducts.length}');
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
            backgroundColor: AppTheme.errorRed,
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
          backgroundColor: AppTheme.errorRed,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
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
          setState(() {
            _products.addAll(products);
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
        final theme = Theme.of(context);
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: responsive.screenHeight * 0.85,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                                  selectedColor: AppTheme.primaryGreen,
                                  labelStyle: TextStyle(
                                    color: _selectedCategory == null
                                        ? Colors.white
                                        : theme.textTheme.bodyLarge?.color,
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
                                    selectedColor: AppTheme.primaryGreen,
                                    labelStyle: TextStyle(
                                      color:
                                          _selectedCategory?.id == category.id
                                          ? Colors.white
                                          : theme.textTheme.bodyLarge?.color,
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
                                    activeColor: AppTheme.primaryGreen,
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
                                          selectedColor: AppTheme.primaryGreen,
                                          labelStyle: TextStyle(
                                            color: _selectedLocation == location
                                                ? Colors.white
                                                : theme.textTheme.bodyLarge?.color,
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
                                      selectedColor: AppTheme.primaryGreen,
                                      labelStyle: TextStyle(
                                        color: _minRating == rating
                                            ? Colors.white
                                            : theme.textTheme.bodyLarge?.color,
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
                                      side: BorderSide(
                                        color: AppTheme.primaryGreen,
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
                                      backgroundColor: AppTheme.primaryGreen,
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
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        top: false, // Allow content to go under status bar for header image
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: responsive.responsive(
                mobile: responsive.screenHeight * 0.5,
                tablet: responsive.screenHeight * 0.45,
                desktop: responsive.screenHeight * 0.4,
              ),
              floating: false,
              pinned: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
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
                                  color: theme.cardColor,
                                  child: Icon(
                                    Icons.home,
                                    size: 100,
                                    color: theme.hintColor,
                                  ),
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: theme.cardColor,
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
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.black.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.95),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing(16),
                              vertical: responsive.spacing(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Left side - List Item button
                                Flexible(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      // Check if user is verified
                                      final storageService = StorageService();
                                      final currentUser = await storageService.getUser();
                                      if (currentUser == null) {
                                        Fluttertoast.showToast(
                                          msg: 'You must be logged in to create a product',
                                          backgroundColor: Colors.red,
                                        );
                                        return;
                                      }
                                      if (!currentUser.isVerified) {
                                        Fluttertoast.showToast(
                                          msg: 'You must be verified to create products. Please complete your verification first.',
                                          backgroundColor: Colors.orange,
                                          toastLength: Toast.LENGTH_LONG,
                                        );
                                        return;
                                      }
                                      Navigator.pushNamed(
                                        context,
                                        '/add-product',
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: responsive.spacing(16),
                                        vertical: responsive.spacing(10),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: Icon(
                                      Icons.add,
                                      size: responsive.iconSize(20),
                                    ),
                                    label: Text(
                                      'List Item',
                                      style: TextStyle(fontSize: responsive.fontSize(14)),
                                    ),
                                  ),
                                ),
                                SizedBox(width: responsive.spacing(12)),
                                // Right side - Notifications and Avatar
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.notifications_outlined,
                                        color: theme.brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black87,
                                        size: responsive.iconSize(24),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/notifications',
                                        );
                                      },
                                      tooltip: 'Notifications',
                                    ),
                                    SizedBox(width: responsive.spacing(4)),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/profile');
                                      },
                                      child: _currentUser != null
                                          ? AvatarImage(
                                              imageUrl: _currentUser!.avatarUrl,
                                              name: _currentUser!.name,
                                              radius: responsive.responsive(mobile: 20, tablet: 24, desktop: 28),
                                              backgroundColor: AppTheme.primaryGreen,
                                              textColor: Colors.white,
                                            )
                                          : CircleAvatar(
                                              radius: responsive.responsive(mobile: 20, tablet: 24, desktop: 28),
                                              backgroundColor: AppTheme.primaryGreen,
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: responsive.iconSize(20),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Spacer(),
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Rent Anything You Need',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(32),
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: responsive.spacing(12)),
                                Text(
                                  'Access thousands of items in your neighborhood',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(18),
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: responsive.spacing(32)),
                                Hero(
                                  tag: 'searchBar',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      width: responsive.responsive(
                                        mobile: responsive.screenWidth * 0.9,
                                        tablet: 500,
                                        desktop: 600,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: responsive.spacing(16),
                                        vertical: responsive.spacing(4),
                                      ),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.12),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.search,
                                          color: theme.hintColor,
                                          size: responsive.iconSize(24),
                                        ),
                                        SizedBox(width: responsive.spacing(8)),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            style: TextStyle(fontSize: responsive.fontSize(16)),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'What are you looking for?',
                                              hintStyle: TextStyle(
                                                color: theme.hintColor,
                                                fontSize: responsive.fontSize(16),
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: responsive.spacing(8),
                                                  ),
                                            ),
                                            onChanged: (value) =>
                                                _applyFilters(),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.tune,
                                            color: Color(0xFF4CAF50),
                                            size: responsive.iconSize(24),
                                          ),
                                          onPressed: _showFilterDialog,
                                          tooltip: 'Filters',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: responsive.spacing(24)),
                             
                              ],
                            ),
                          ),
                        ),
                        Spacer(),
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
                                color: AppTheme.primaryGreen,
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
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildListDelegate([
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                          itemCount: _filteredProducts.length >= 10
                              ? 10
                              : _filteredProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(_filteredProducts[index]);
                          },
                        ),
                        // Show All Products Button
                        if (_filteredProducts.length >= 10)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/products');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.grid_view),
                                label: Text(
                                  _totalProducts > 0
                                      ? 'Show All Products ($_totalProducts)'
                                      : 'Show All Products (${_filteredProducts.length})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ]),
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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: theme.cardColor,
                    child: product.thumbnail.isNotEmpty
                        ? Image.network(
                            product.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_not_supported,
                              color: theme.hintColor,
                              size: cardWidth * 0.25,
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            color: theme.hintColor,
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
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: cardWidth * 0.02),
                        Text(
                          product.category.name,
                          style: TextStyle(
                            fontSize: cardWidth * 0.06,
                            color: theme.hintColor,
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
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  Text(
                                    'per day',
                                    style: TextStyle(
                                      fontSize: cardWidth * 0.055,
                                      color: theme.hintColor,
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
                                        : theme.hintColor,
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
    final responsive = ResponsiveUtils(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: responsive.spacing(4)),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(12),
          vertical: responsive.spacing(6),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: responsive.fontSize(14),
          ),
        ),
      ),
    );
  }
}
