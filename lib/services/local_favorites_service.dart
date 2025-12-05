import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local favorites service using SharedPreferences
/// Stores favorite product IDs locally without API calls
class LocalFavoritesService {
  static const String _favoritesKey = 'local_favorites';

  /// Get all favorite product IDs
  Future<List<int>> getFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);

      if (favoritesJson == null || favoritesJson.isEmpty) {
        return [];
      }

      final List<dynamic> favoritesList = jsonDecode(favoritesJson);
      return favoritesList.cast<int>();
    } catch (e) {
      return [];
    }
  }

  /// Add product to favorites
  Future<void> addFavorite(int productId) async {
    try {
      final favorites = await getFavoriteIds();

      // Don't add if already exists
      if (favorites.contains(productId)) {
        return;
      }

      favorites.add(productId);
      await _saveFavorites(favorites);
    } catch (e) {
      rethrow;
    }
  }

  /// Remove product from favorites
  Future<void> removeFavorite(int productId) async {
    try {
      final favorites = await getFavoriteIds();
      favorites.remove(productId);
      await _saveFavorites(favorites);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if product is in favorites
  Future<bool> isFavorite(int productId) async {
    try {
      final favorites = await getFavoriteIds();
      return favorites.contains(productId);
    } catch (e) {
      return false;
    }
  }

  /// Toggle favorite status (add if not favorite, remove if favorite)
  Future<bool> toggleFavorite(int productId) async {
    try {
      final isFav = await isFavorite(productId);

      if (isFav) {
        await removeFavorite(productId);
        return false;
      } else {
        await addFavorite(productId);
        return true;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all favorites
  Future<void> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
    } catch (e) {
      rethrow;
    }
  }

  /// Get count of favorite products
  Future<int> getFavoritesCount() async {
    try {
      final favorites = await getFavoriteIds();
      return favorites.length;
    } catch (e) {
      return 0;
    }
  }

  /// Save favorites to SharedPreferences
  Future<void> _saveFavorites(List<int> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = jsonEncode(favorites);
      await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      rethrow;
    }
  }
}
