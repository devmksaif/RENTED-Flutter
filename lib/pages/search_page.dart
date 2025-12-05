import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/product_model.dart';
import '../components/product_card.dart';
import '../config/app_theme.dart';
import 'product_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController searchController;
  String selectedCategory = 'All';
  String selectedSort = 'Relevant';
  late List<Product> filteredProducts;

  final List<String> categories = [
    'All',
    'Tools & Equipment',
    'Sports & Outdoors',
    'Electronics',
    'Home & Garden',
  ];
  final List<String> sortOptions = [
    'Relevant',
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
    'Most Popular',
  ];

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    filteredProducts = List.from(mockProducts);
  }

  void filterProducts() {
    setState(() {
      filteredProducts = mockProducts.where((product) {
        bool matchesSearch =
            product.title.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ) ||
            product.description.toLowerCase().contains(
              searchController.text.toLowerCase(),
            );
        bool matchesCategory =
            selectedCategory == 'All' || product.category == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();

      // Apply sorting
      if (selectedSort == 'Newest') {
        filteredProducts.sort((a, b) => b.id.compareTo(a.id));
      } else if (selectedSort == 'Price: Low to High') {
        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
      } else if (selectedSort == 'Price: High to Low') {
        filteredProducts.sort((a, b) => b.price.compareTo(a.price));
      } else if (selectedSort == 'Most Popular') {
        filteredProducts.sort((a, b) => b.reviews.compareTo(a.reviews));
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (_) => filterProducts(),
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search, color: theme.hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Filter and Sort Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Category Filter
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCategory = value);
                        filterProducts();
                      }
                    },
                    items: categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                  ),
                ),
                SizedBox(width: 16),
                // Sort
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedSort,
                    isExpanded: true,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedSort = value);
                        filterProducts();
                      }
                    },
                    items: sortOptions.map((sort) {
                      return DropdownMenuItem(
                        value: sort,
                        child: Text(
                          sort,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Results
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: theme.hintColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: filteredProducts.map((product) {
                        return ProductCard(
                          product: product,
                          onViewDetails: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailsPage(product: product),
                              ),
                            );
                          },
                          onRent: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${product.title} added to cart!',
                                ),
                              ),
                            );
                          },
                          onFavoriteChanged: (isFav) {
                            setState(() {
                              product.isFavorite = isFav;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
