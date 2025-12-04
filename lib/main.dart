import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/profile_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/my_products_screen.dart';
import 'screens/my_rentals_screen.dart';
import 'screens/my_purchases_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/favorites_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RENTED',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigation(),
        '/profile': (context) => const ProfileScreen(),
        '/add-product': (context) => const AddProductScreen(),
        '/my-products': (context) => const MyProductsScreen(),
        '/my-rentals': (context) => const MyRentalsScreen(),
        '/my-purchases': (context) => const MyPurchasesScreen(),
        '/verification': (context) => const VerificationScreen(),
        '/favorites': (context) => const FavoritesScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle product detail route with arguments
        if (settings.name == '/product-detail') {
          final productId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: productId),
          );
        }
        return null;
      },
    );
  }
}
