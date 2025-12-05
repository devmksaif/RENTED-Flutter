import 'package:logger/logger.dart';

/// Global logger instance for the app
/// Provides structured logging with different levels
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    level: Level.debug, // Change to Level.warning in production
  );

  /// Log debug messages (development only)
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info messages
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal errors
  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log API requests
  static void apiRequest(String method, String url, {Map<String, dynamic>? body, Map<String, String>? headers}) {
    _logger.d('🌐 API Request: $method $url');
    if (body != null) {
      _logger.d('📦 Request Body: $body');
    }
    if (headers != null && headers.containsKey('Authorization')) {
      final authHeader = headers['Authorization'];
      _logger.d('🔑 Auth: ${authHeader?.substring(0, 20)}...');
    }
  }

  /// Log API responses
  static void apiResponse(int statusCode, String url, {dynamic body}) {
    if (statusCode >= 200 && statusCode < 300) {
      _logger.i('✅ API Response: $statusCode $url');
    } else if (statusCode >= 400 && statusCode < 500) {
      _logger.w('⚠️ API Response: $statusCode $url');
    } else {
      _logger.e('❌ API Response: $statusCode $url');
    }
    if (body != null) {
      _logger.d('📥 Response Body: $body');
    }
  }

  /// Log API errors
  static void apiError(String url, int statusCode, String message, {Map<String, dynamic>? errors}) {
    _logger.e('❌ API Error: $statusCode $url');
    _logger.e('💬 Message: $message');
    if (errors != null) {
      _logger.e('📋 Errors: $errors');
    }
  }

  /// Log network errors
  static void networkError(String operation, dynamic error) {
    _logger.e('🌐 Network Error in $operation');
    _logger.e('💥 Error: $error');
  }

  /// Log authentication errors
  static void authError(String operation, String message) {
    _logger.w('🔐 Auth Error in $operation: $message');
  }

  /// Log validation errors
  static void validationError(String field, String message) {
    _logger.w('✏️ Validation Error: $field - $message');
  }
}

