import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../data/mock_data.dart';
import '../components/product_card.dart';
import '../config/app_theme.dart';
import 'product_details_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late List<Product> favoriteProducts;

  @override
  void initState() {
    super.initState();
    favoriteProducts = mockProducts.where((p) => p.isFavorite).toList();
  }

  void removeFavorite(Product product) {
    setState(() {
      product.isFavorite = false;
      favoriteProducts.removeWhere((p) => p.id == product.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: favoriteProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: theme.hintColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add items to your favorites to see them here',
                    style: TextStyle(color: theme.hintColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: favoriteProducts.map((product) {
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
                          content: Text('${product.title} added to cart!'),
                        ),
                      );
                    },
                    onFavoriteChanged: (isFav) {
                      if (!isFav) {
                        removeFavorite(product);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
    );
  }
}
