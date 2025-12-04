class ApiConfig {
  // Base URLs
  static const String developmentBaseUrl = 'http://167.86.87.72:8000/api/v1';
  static const String productionBaseUrl =
      'http://167.86.87.72:8000/api/v1';

  // Use production by default, change to development when testing locally
  static const String baseUrl = productionBaseUrl;

  // API Endpoints
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  static const String logout = '$baseUrl/logout';
  static const String user = '$baseUrl/user';
  static const String userProfile = '$baseUrl/user/profile';
  static const String categories = '$baseUrl/categories';
  static const String products = '$baseUrl/products';
  static const String userProducts = '$baseUrl/user/products';
  static const String verify = '$baseUrl/verify';
  static const String verifyStatus = '$baseUrl/verify/status';
  static const String rentals = '$baseUrl/rentals';
  static const String userRentals = '$baseUrl/user/rentals';
  static const String purchases = '$baseUrl/purchases';
  static const String userPurchases = '$baseUrl/user/purchases';

  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Common headers
  static Map<String, String> get headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> getMultipartHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
