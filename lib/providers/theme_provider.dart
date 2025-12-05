import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  ThemeData get theme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isDarkMode = await _settingsService.getDarkMode();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isDarkMode = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _settingsService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    await _settingsService.setDarkMode(_isDarkMode);
    notifyListeners();
  }
}
