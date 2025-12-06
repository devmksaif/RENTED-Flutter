class ApiConfig {
  // Base URLs
  static const String developmentBaseUrl = 'http://167.86.87.72:8000/api/v1';
  static const String productionBaseUrl = 'http://167.86.87.72:8000/api/v1';

  // Use production by default, change to development when testing locally
  static const String baseUrl = productionBaseUrl;

  // API Endpoints
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  static const String logout = '$baseUrl/logout';
  static const String user = '$baseUrl/user';
  static const String userProfile = '$baseUrl/user/profile';
  static const String userAvatar = '$baseUrl/user/avatar';
  static const String deleteAccount = '$baseUrl/user/account';
  static const String categories = '$baseUrl/categories';
  static const String products = '$baseUrl/products';
  static const String userProducts = '$baseUrl/user/products';
  static const String verify = '$baseUrl/verify';
  static const String verifyStatus = '$baseUrl/verify/status';
  static const String verifyImage = '$baseUrl/verify/image';
  static const String rentals = '$baseUrl/rentals';
  static const String userRentals = '$baseUrl/user/rentals';
  static const String purchases = '$baseUrl/purchases';
  static const String userPurchases = '$baseUrl/user/purchases';
  static const String favourites = '$baseUrl/favourites';
  static const String favouritesToggle = '$baseUrl/favourites/toggle';
  static const String favouritesCheck = '$baseUrl/favourites/check';
  
  // Reviews
  static const String reviews = '$baseUrl/reviews';
  static const String userReviews = '$baseUrl/user/reviews';
  static const String productReviews = '$baseUrl/products'; // /{productId}/reviews
  static const String productRating = '$baseUrl/products'; // /{productId}/rating
  
  // Conversations & Messages
  static const String conversations = '$baseUrl/conversations';
  static const String messages = '$baseUrl/messages';
  static const String conversationsUnreadCount = '$baseUrl/conversations/unread/count';
  
  // Notifications
  static const String notifications = '$baseUrl/notifications';
  static const String notificationsUnread = '$baseUrl/notifications/unread';
  static const String notificationsUnreadCount = '$baseUrl/notifications/unread/count';
  
  // Offers (within conversations)
  // Note: Use string interpolation: '${ApiConfig.conversations}/$conversationId/offers'
  // For specific endpoints:
  // - Create: POST ${conversations}/{conversationId}/offers
  // - Accept: POST ${conversations}/{conversationId}/offers/{offerId}/accept
  // - Reject: POST ${conversations}/{conversationId}/offers/{offerId}/reject
  // - List: GET ${conversations}/{conversationId}/offers
  // - Get: GET ${conversations}/{conversationId}/offers/{offerId}
  
  // Disputes
  static const String disputes = '$baseUrl/disputes';
  
  // Rental Availability
  static const String productAvailability = '$baseUrl/products'; // /{productId}/availability
  static const String checkAvailability = '$baseUrl/products'; // /{productId}/check-availability
  static const String blockDates = '$baseUrl/products'; // /{productId}/block-dates
  
  // Password Reset
  static const String forgotPassword = '$baseUrl/forgot-password';
  static const String resetPassword = '$baseUrl/reset-password';
  
  // Social Auth
  static const String googleAuth = '$baseUrl/auth/google';
  static const String googleAuthCallback = '$baseUrl/auth/google/callback';
  static const String googleFirebaseAuth = '$baseUrl/auth/google/firebase';
  
  // Image Upload (New Unified API)
  static const String uploadImage = '$baseUrl/upload/image';
  static const String uploadImages = '$baseUrl/upload/images';
  static const String uploadAvatar = '$baseUrl/upload/avatar';

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
