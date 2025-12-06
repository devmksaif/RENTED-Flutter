import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'my_products_screen.dart';
import 'profile_screen.dart';
import 'conversations_screen.dart';
import '../services/storage_service.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Use GlobalKey to access FavoritesScreen state
  final GlobalKey<FavoritesScreenState> _favoritesKey = GlobalKey<FavoritesScreenState>();

  late final List<Widget> _screens = [
    const HomeScreen(),
    FavoritesScreen(key: _favoritesKey),
    const ConversationsScreen(),
    const MyProductsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Refresh favorites screen when tab is selected
            if (index == 1 && _favoritesKey.currentState != null) {
              _favoritesKey.currentState!.loadFavorites();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.cardColor,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: theme.hintColor,
          selectedFontSize: responsive.fontSize(12),
          unselectedFontSize: responsive.fontSize(12),
          elevation: 0,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          iconSize: responsive.iconSize(24),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: responsive.iconSize(24)),
              activeIcon: Icon(Icons.home, size: responsive.iconSize(24)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline, size: responsive.iconSize(24)),
              activeIcon: Icon(Icons.favorite, size: responsive.iconSize(24)),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: responsive.iconSize(24)),
              activeIcon: Icon(Icons.chat_bubble, size: responsive.iconSize(24)),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined, size: responsive.iconSize(24)),
              activeIcon: Icon(Icons.inventory_2, size: responsive.iconSize(24)),
              label: 'My Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: responsive.iconSize(24)),
              activeIcon: Icon(Icons.person, size: responsive.iconSize(24)),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 3
          ? FloatingActionButton.extended(
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
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              icon: Icon(Icons.add, size: responsive.iconSize(24)),
              label: Text(
                'Add Product',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.fontSize(14),
                ),
              ),
              elevation: 4,
            )
          : null,
    );
  }
}
