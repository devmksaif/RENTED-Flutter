import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Session Manager - Manages user session state across the app
class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isAuthenticated = false;
  DateTime? _loginTime;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  DateTime? get loginTime => _loginTime;

  /// Initialize session from storage
  Future<void> initSession() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _authService.getSavedUser();
        _loginTime = await _authService.getLoginTime();
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      await clearSession();
    }
  }

  /// Update session with new user data
  Future<void> updateSession(User user) async {
    _currentUser = user;
    _isAuthenticated = true;
    _loginTime = await _authService.getLoginTime();
    notifyListeners();
  }

  /// Clear session data
  Future<void> clearSession() async {
    _currentUser = null;
    _isAuthenticated = false;
    _loginTime = null;
    await _authService.forceLogout();
    notifyListeners();
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      await updateSession(user);
    } catch (e) {
      // If refresh fails, user might be logged out
      await clearSession();
    }
  }

  /// Check if session is still valid
  Future<bool> validateSession() async {
    try {
      final isValid = await _authService.validateToken();
      if (!isValid) {
        await clearSession();
      }
      return isValid;
    } catch (e) {
      await clearSession();
      return false;
    }
  }

  /// Get session duration
  Duration? getSessionDuration() {
    if (_loginTime == null) return null;
    return DateTime.now().difference(_loginTime!);
  }
}
