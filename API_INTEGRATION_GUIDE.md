# RENTED Flutter App - API Integration Guide

## Overview

This Flutter app is fully integrated with the Rented Marketplace API. The app includes authentication, user management, and is ready to be extended with product listings, rentals, and purchases.

## Project Structure

```
lib/
├── config/
│   └── api_config.dart          # API endpoints and configuration
├── models/
│   ├── api_error.dart           # Error handling model
│   ├── auth_response.dart       # Authentication response model
│   ├── category.dart            # Category model
│   ├── product.dart             # Product model
│   └── user.dart                # User model
├── services/
│   ├── auth_service.dart        # Authentication API calls
│   ├── product_service.dart     # Product API calls
│   └── storage_service.dart     # Secure local storage
├── login_screen.dart            # Login UI
├── register_screen.dart         # Registration UI
└── main.dart                    # App entry point
```

## Features Implemented

### ✅ Authentication
- **User Registration**: Full name, email, and password with validation
- **User Login**: Email and password authentication
- **Token Management**: Secure storage of authentication tokens
- **Auto-logout**: Token cleared on logout
- **Error Handling**: User-friendly error messages for all API errors

### ✅ User Management
- **User Profile**: Fetch current user data
- **Update Profile**: Change name, email, or password
- **Verification Status**: Track user verification state

### ✅ API Services Ready
- **Product Service**: Get products, create, update, delete (requires implementation)
- **Category Service**: Fetch all categories
- **Storage Service**: Secure token and user data storage

## API Configuration

The API base URL is configured in `lib/config/api_config.dart`:

```dart
// Production (default)
static const String productionBaseUrl = 'https://rented-backend-api-production.up.railway.app/api/v1';

// Development (for local testing)
static const String developmentBaseUrl = 'http://localhost:8000/api/v1';
```

**To switch between environments**, change the `baseUrl` constant in `api_config.dart`.

## Authentication Flow

### 1. Register
- User fills out registration form (3 steps)
- API call: `POST /api/v1/register`
- Request body:
  ```json
  {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
  ```
- Response: User data + authentication token
- Token is automatically saved to secure storage
- User redirected to home screen

### 2. Login
- User enters email and password
- API call: `POST /api/v1/login`
- Request body:
  ```json
  {
    "email": "john@example.com",
    "password": "password123"
  }
  ```
- Response: User data + authentication token
- Token is automatically saved
- User redirected to home screen

### 3. Authenticated Requests
All subsequent API calls automatically include the token:
```
Authorization: Bearer {token}
```

### 4. Logout
- API call: `POST /api/v1/logout`
- Token revoked on server
- Local storage cleared
- User redirected to login

## Using the API Services

### Example: Login
```dart
import 'services/auth_service.dart';
import 'models/api_error.dart';

final authService = AuthService();

try {
  final authResponse = await authService.login(
    email: email,
    password: password,
  );
  
  print('Welcome ${authResponse.user.name}!');
  print('Token: ${authResponse.token}');
} on ApiError catch (e) {
  print('Error: ${e.message}');
  if (e.errors != null) {
    print('Validation errors: ${e.getAllErrors()}');
  }
}
```

### Example: Get Current User
```dart
final authService = AuthService();

try {
  final user = await authService.getCurrentUser();
  print('User: ${user.name}');
  print('Email: ${user.email}');
  print('Verified: ${user.isVerified}');
} on ApiError catch (e) {
  if (e.statusCode == 401) {
    // Not authenticated, redirect to login
  }
}
```

### Example: Update Profile
```dart
final authService = AuthService();

try {
  final user = await authService.updateProfile(
    name: 'John Updated',
    email: 'newemail@example.com',
  );
  print('Profile updated!');
} on ApiError catch (e) {
  print('Error: ${e.firstError}');
}
```

### Example: Get Products
```dart
import 'services/product_service.dart';

final productService = ProductService();

try {
  final products = await productService.getProducts(page: 1, perPage: 20);
  for (var product in products) {
    print('${product.title}: \$${product.pricePerDay}/day');
  }
} on ApiError catch (e) {
  print('Error: ${e.message}');
}
```

## Error Handling

All API errors are handled through the `ApiError` model:

```dart
class ApiError {
  final String message;              // Main error message
  final Map<String, List<String>>? errors;  // Validation errors by field
  final int statusCode;              // HTTP status code
}
```

### Common Status Codes
- **200**: Success
- **201**: Created successfully
- **400**: Bad request / business logic error
- **401**: Not authenticated (redirect to login)
- **403**: Forbidden (user lacks permission)
- **404**: Resource not found
- **422**: Validation error (check `errors` map)
- **429**: Too many requests (rate limit)
- **500+**: Server error

### Error Display
```dart
try {
  // API call
} on ApiError catch (e) {
  if (e.statusCode == 422) {
    // Show all validation errors
    showDialog(context, e.getAllErrors());
  } else if (e.statusCode == 401) {
    // Redirect to login
    Navigator.pushReplacementNamed(context, '/login');
  } else {
    // Show general error
    showToast(e.message);
  }
}
```

## Next Steps: Extending the App

### 1. Home Screen with Products
```dart
// In home screen
final productService = ProductService();
final products = await productService.getProducts();

// Display in ListView/GridView
```

### 2. Product Details Screen
```dart
final product = await productService.getProduct(productId);
// Show product details, images, price, etc.
```

### 3. Create Product (for verified users)
```dart
await productService.createProduct(
  categoryId: 1,
  title: 'Camera Equipment',
  description: 'Professional DSLR camera',
  pricePerDay: 50.0,
  isForSale: true,
  salePrice: 2500.0,
  thumbnailPath: '/path/to/thumbnail.jpg',
  imagePaths: ['/path/to/image1.jpg', '/path/to/image2.jpg'],
);
```

### 4. Rental Flow
```dart
// Create rental request
POST /api/v1/rentals
{
  "product_id": 25,
  "start_date": "2025-12-10",
  "end_date": "2025-12-15",
  "notes": "Need for event"
}

// Get user's rentals
final rentals = await GET /api/v1/user/rentals
```

### 5. Purchase Flow
```dart
// Create purchase request
POST /api/v1/purchases
{
  "product_id": 25,
  "notes": "Interested in buying"
}

// Get user's purchases
final purchases = await GET /api/v1/user/purchases
```

### 6. User Verification
```dart
// Upload verification documents
POST /api/v1/verify
- id_front: file
- id_back: file

// Check verification status
final status = await GET /api/v1/verify/status
```

## Testing the Integration

### 1. Test Registration
1. Open the app
2. Click "Create one" to go to register screen
3. Fill out all 3 steps
4. Click "Sign Up"
5. Check for success toast
6. Should redirect to home screen

### 2. Test Login
1. Open the app (if not logged in)
2. Enter email and password from registration
3. Click "Sign In"
4. Check for welcome toast
5. Should redirect to home screen

### 3. Test Logout (implement in profile screen)
```dart
final authService = AuthService();
await authService.logout();
Navigator.pushReplacementNamed(context, '/login');
```

### 4. Test Token Persistence
1. Login to the app
2. Close the app completely
3. Reopen the app
4. Check if user is still logged in:
```dart
final authService = AuthService();
final isLoggedIn = await authService.isLoggedIn();
if (isLoggedIn) {
  final user = await authService.getSavedUser();
  print('Welcome back, ${user?.name}!');
}
```

## Security Best Practices

### ✅ Implemented
- Tokens stored securely using `shared_preferences`
- Passwords never stored locally
- Token included automatically in authenticated requests
- Token cleared on logout
- HTTPS used in production

### 🔒 Additional Recommendations
1. **Add token refresh**: Implement automatic token refresh before expiration
2. **Add biometric auth**: Use `local_auth` package for fingerprint/face unlock
3. **Encrypt sensitive data**: Use `flutter_secure_storage` for even more security
4. **Certificate pinning**: Prevent man-in-the-middle attacks
5. **Obfuscate code**: Use `flutter build --obfuscate` for production builds

## API Documentation

Full API documentation is available in `API_DOCUMENTATION.md` (the file you provided).

Key endpoints:
- `POST /api/v1/register` - Register new user
- `POST /api/v1/login` - Login user
- `POST /api/v1/logout` - Logout user
- `GET /api/v1/user` - Get current user
- `PUT /api/v1/user/profile` - Update profile
- `GET /api/v1/categories` - Get categories
- `GET /api/v1/products` - Get products (paginated)
- `POST /api/v1/products` - Create product (verified users only)
- `POST /api/v1/rentals` - Create rental request
- `POST /api/v1/purchases` - Create purchase request

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0                    # HTTP requests
  shared_preferences: ^2.2.2      # Secure token storage
  fluttertoast: ^8.2.2           # User notifications
  flutter_form_builder: ^9.1.1   # Form handling
  google_sign_in: ^6.1.5         # OAuth (future feature)
  google_fonts: ^6.1.0           # Typography
```

## Troubleshooting

### "Unauthenticated" Error
- Token expired or invalid
- Solution: Clear storage and login again
```dart
final storage = StorageService();
await storage.clearAll();
```

### Network Errors
- Check internet connection
- Verify API base URL in `api_config.dart`
- Check if backend server is running

### Validation Errors
- Check API documentation for required fields
- Ensure field names match API expectations
- Check password requirements (min 8 characters)

## Support

For backend API issues or questions, refer to the main API documentation or contact the backend team.

---

**Happy coding! 🚀**
