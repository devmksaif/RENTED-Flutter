import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'models/product.dart';
import 'models/api_error.dart';
import 'services/product_service.dart';
import 'services/favorite_service.dart';
import 'services/storage_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ProductService _productService = ProductService();
  final FavoriteService _favoriteService = FavoriteService();
  List<Product> _products = [];
  List<Product> _displayedProducts = [];
  bool _isLoading = true;
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _productService.getProducts(page: 1, perPage: 20);
      final products = result['products'] as List<Product>;
      if (mounted) {
        setState(() {
          _products = products;
          _displayedProducts = products;
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
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: screenHeight * 0.5,
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
                        Image.asset(
                          'assets/home.jpeg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Container(color: Colors.green.withValues(alpha: 0.7)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
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
                                Navigator.pushNamed(context, '/add-product');
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
                                Navigator.pushNamed(context, '/notifications');
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
                              'Access thousandss of items in your neighborhood',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Container(
                              width: 400,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
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
                                    child: Text(
                                      'What are you looking for?',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      // Navigate to search or show search dialog
                                      showSearch(
                                        context: context,
                                        delegate: ProductSearchDelegate(),
                                      );
                                    },
                                    child: Text('Search'),
                                  ),
                                ],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                : _displayedProducts.isEmpty
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
                : SliverList(
                    delegate: SliverChildListDelegate([
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: _displayedProducts.map((product) {
                          return _buildProductCard(product);
                        }).toList(),
                      ),
                    ]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      width: 300,
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
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[100],
                child: product.thumbnail.isNotEmpty
                    ? Image.network(
                        product.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.grey[400],
                        size: 48,
                      ),
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${product.pricePerDay}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const Text(
                        '/day',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const Spacer(),
                      FutureBuilder<bool>(
                        future: _favoriteService.isFavorite(product.id),
                        builder: (context, snapshot) {
                          final isFavorite = snapshot.data ?? false;
                          return IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey[400],
                              size: 20,
                            ),
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
          ],
        ),
      ),
    );
  }

  void _filterByCategory(String categoryName) {
    setState(() {
      if (_selectedCategoryFilter == categoryName) {
        // If already selected, clear filter
        _selectedCategoryFilter = null;
        _displayedProducts = _products;
      } else {
        // Filter products by category name
        _selectedCategoryFilter = categoryName;
        _displayedProducts = _products.where((product) {
          return product.category.name
              .toLowerCase()
              .contains(categoryName.toLowerCase());
        }).toList();
      }
    });
  }
}

// Product Search Delegate
class ProductSearchDelegate extends SearchDelegate<String> {
  final ProductService _productService = ProductService();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _searchProducts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading results',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data ?? [];
        final displayedProducts = products;

        if (displayedProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No results found for "$query"',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: displayedProducts.length,
          itemBuilder: (context, index) {
            final product = displayedProducts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: product.thumbnail.isNotEmpty
                        ? Image.network(
                            product.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey[400],
                          ),
                  ),
                ),
                title: Text(
                  product.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '\$${product.pricePerDay}/day • ${product.category.name}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/product-detail',
                    arguments: product.id,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Product>> _searchProducts(String searchQuery) async {
    if (searchQuery.isEmpty) return [];

    try {
      // Get all products and filter by search query
      final result = await _productService.getProducts(page: 1, perPage: 50);
      final products = result['products'] as List<Product>;
      return products
          .where(
            (product) =>
                product.title.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                product.category.name.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                product.description.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? [
            'Electronics',
            'Photography',
            'Sports Equipment',
            'Music Instruments',
          ]
        : [
                'Electronics',
                'Photography',
                'Sports Equipment',
                'Music Instruments',
              ]
              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
              .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
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
