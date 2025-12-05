import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'screens/edit_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/rentals_screen.dart';
import 'screens/rental_detail_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/disputes_screen.dart';
import 'screens/dispute_detail_screen.dart';
import 'screens/my_reviews_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/products_screen.dart';
import 'providers/product_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ProductProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RENTED',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
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
        '/edit-profile': (context) => const EditProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/rentals': (context) => const RentalsScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/conversations': (context) => const ConversationsScreen(),
        '/disputes': (context) => const DisputesScreen(),
        '/my-reviews': (context) => const MyReviewsScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/products': (context) => const ProductsScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle product detail route with arguments
        if (settings.name == '/product-detail') {
          final productId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: productId),
          );
        }
        // Handle rental detail route with arguments
        if (settings.name == '/rental-detail') {
          final rentalId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => RentalDetailScreen(rentalId: rentalId),
          );
        }
        // Handle reset password route with arguments
        if (settings.name == '/reset-password') {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: args['email']!,
              token: args['token']!,
            ),
          );
        }
        // Handle chat route with arguments
        if (settings.name == '/chat') {
          final conversationId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => ChatScreen(conversationId: conversationId),
          );
        }
        // Handle dispute detail route with arguments
        if (settings.name == '/dispute-detail') {
          final disputeId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => DisputeDetailScreen(disputeId: disputeId),
          );
        }
        return null;
      },
    );
  }
}
