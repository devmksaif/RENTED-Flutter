import 'package:shared_preferences/shared_preferences.dart';

/// Settings service for storing user preferences locally
class SettingsService {
  // Keys
  static const String _pushNotificationsKey = 'settings_push_notifications';
  static const String _emailNotificationsKey = 'settings_email_notifications';
  static const String _smsNotificationsKey = 'settings_sms_notifications';
  static const String _darkModeKey = 'settings_dark_mode';
  static const String _languageKey = 'settings_language';
  static const String _currencyKey = 'settings_currency';

  // Notification Settings
  Future<bool> getPushNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pushNotificationsKey) ?? true;
  }

  Future<void> setPushNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushNotificationsKey, value);
  }

  Future<bool> getEmailNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_emailNotificationsKey) ?? true;
  }

  Future<void> setEmailNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailNotificationsKey, value);
  }

  Future<bool> getSmsNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_smsNotificationsKey) ?? false;
  }

  Future<void> setSmsNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smsNotificationsKey, value);
  }

  // Appearance Settings
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  // Preference Settings
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'English';
  }

  Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
  }

  Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? 'USD';
  }

  Future<void> setCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, value);
  }

  // Load all settings at once
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'pushNotifications': await getPushNotifications(),
      'emailNotifications': await getEmailNotifications(),
      'smsNotifications': await getSmsNotifications(),
      'darkMode': await getDarkMode(),
      'language': await getLanguage(),
      'currency': await getCurrency(),
    };
  }

  // Clear all settings (reset to defaults)
  Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pushNotificationsKey);
    await prefs.remove(_emailNotificationsKey);
    await prefs.remove(_smsNotificationsKey);
    await prefs.remove(_darkModeKey);
    await prefs.remove(_languageKey);
    await prefs.remove(_currencyKey);
  }
}
