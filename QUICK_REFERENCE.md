# RENTED API - Quick Reference

## 🔑 Authentication

### Register
```dart
final authService = AuthService();
final response = await authService.register(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'password123',
  passwordConfirmation: 'password123',
);
// Token auto-saved, user logged in
```

### Login
```dart
final authService = AuthService();
final response = await authService.login(
  email: 'john@example.com',
  password: 'password123',
);
// Token auto-saved, user logged in
```

### Logout
```dart
final authService = AuthService();
await authService.logout();
// Token cleared, user logged out
```

### Get Current User
```dart
final authService = AuthService();
final user = await authService.getCurrentUser();
print(user.name); // John Doe
print(user.isVerified); // true/false
```

### Update Profile
```dart
final authService = AuthService();
final user = await authService.updateProfile(
  name: 'Jane Doe',
  email: 'jane@example.com',
  currentPassword: 'oldpass',
  password: 'newpass',
  passwordConfirmation: 'newpass',
);
```

## 📦 Products

### Get All Products
```dart
final productService = ProductService();
final products = await productService.getProducts(
  page: 1,
  perPage: 20,
);
```

### Get Single Product
```dart
final productService = ProductService();
final product = await productService.getProduct(productId);
```

### Get Categories
```dart
final productService = ProductService();
final categories = await productService.getCategories();
```

### Create Product (Verified Users Only)
```dart
final productService = ProductService();
final product = await productService.createProduct(
  categoryId: 1,
  title: 'Canon Camera',
  description: 'Professional camera',
  pricePerDay: 50.0,
  isForSale: true,
  salePrice: 2500.0,
  thumbnailPath: '/path/to/thumb.jpg',
  imagePaths: ['/path/to/img1.jpg', '/path/to/img2.jpg'],
);
```

### Update Product
```dart
final productService = ProductService();
final product = await productService.updateProduct(
  productId: 25,
  title: 'Updated Title',
  pricePerDay: 55.0,
  isAvailable: true,
);
```

### Delete Product
```dart
final productService = ProductService();
await productService.deleteProduct(productId);
```

## 🏠 Storage

### Check if Logged In
```dart
final authService = AuthService();
final isLoggedIn = await authService.isLoggedIn();
```

### Get Saved User
```dart
final authService = AuthService();
final user = await authService.getSavedUser();
if (user != null) {
  print('Welcome back, ${user.name}!');
}
```

### Clear Storage
```dart
final storage = StorageService();
await storage.clearAll();
```

## ❌ Error Handling

```dart
try {
  await authService.login(...);
} on ApiError catch (e) {
  if (e.statusCode == 401) {
    // Invalid credentials
  } else if (e.statusCode == 422) {
    // Validation error
    print(e.getAllErrors());
  } else if (e.statusCode == 0) {
    // Network error
  } else {
    // Other error
    print(e.message);
  }
}
```

## 🔧 Configuration

### Change API URL
In `lib/config/api_config.dart`:
```dart
// Use production
static const String baseUrl = productionBaseUrl;

// Use development
static const String baseUrl = developmentBaseUrl;
```

## 📱 Common Patterns

### Show Loading State
```dart
setState(() => _isLoading = true);
try {
  await apiCall();
} finally {
  setState(() => _isLoading = false);
}
```

### Show Toast Message
```dart
Fluttertoast.showToast(
  msg: "Success!",
  backgroundColor: Colors.green,
  textColor: Colors.white,
);
```

### Navigate After Login
```dart
final response = await authService.login(...);
Navigator.pushReplacementNamed(context, '/');
```

### Protect Screens (Auth Required)
```dart
@override
void initState() {
  super.initState();
  _checkAuth();
}

Future<void> _checkAuth() async {
  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();
  if (!isLoggedIn) {
    Navigator.pushReplacementNamed(context, '/login');
  }
}
```

## 🎯 User Verification Status

```dart
if (user.isVerified) {
  // User can create products
} else if (user.isPending) {
  // Verification in progress
} else if (user.isRejected) {
  // Verification rejected
}
```

## 📊 Models

### User
```dart
user.id            // int
user.name          // String
user.email         // String
user.verificationStatus  // 'pending', 'approved', 'rejected'
user.verifiedAt    // DateTime?
user.isVerified    // bool
user.isPending     // bool
user.isRejected    // bool
```

### Product
```dart
product.id              // int
product.title           // String
product.description     // String
product.pricePerDay     // String
product.isForSale       // bool
product.salePrice       // String?
product.isAvailable     // bool
product.thumbnail       // String (URL)
product.images          // List<String>
product.category        // Category
product.owner           // User?
```

### Category
```dart
category.id          // int
category.name        // String
category.slug        // String
category.description // String?
category.isActive    // bool
```

## 🚀 Quick Start

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure API URL** (if needed)
   Edit `lib/config/api_config.dart`

3. **Run the app**
   ```bash
   flutter run
   ```

4. **Test registration**
   - Open app → Create account
   - Fill form → Sign up
   - Should redirect to home

5. **Test login**
   - Reopen app → Login
   - Enter credentials
   - Should redirect to home

---

**Need help?** Check `API_INTEGRATION_GUIDE.md` for detailed documentation.
