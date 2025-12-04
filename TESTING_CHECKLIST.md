# Testing Checklist for API Integration

## ✅ Pre-Testing Setup

- [ ] Run `flutter pub get` to install dependencies
- [ ] Check API base URL in `lib/config/api_config.dart`
- [ ] Ensure backend API is running and accessible
- [ ] Have a test device/emulator ready

## 🧪 Test Cases

### 1. Registration Flow

#### Happy Path
- [ ] Open app, navigate to register screen
- [ ] **Step 1**: Select account type (Buyer/Seller) - works
- [ ] **Step 2**: Enter full name - accepts input
- [ ] **Step 2**: Enter valid email - accepts input
- [ ] **Step 3**: Enter password (8+ characters) - accepts input
- [ ] **Step 3**: Enter matching confirmation password - accepts input
- [ ] Click "Sign Up" button
- [ ] **Expected**: Loading indicator appears
- [ ] **Expected**: Green success toast: "Registration successful! Welcome to RENTED, {name}."
- [ ] **Expected**: Redirected to home screen (MyHomePage)
- [ ] **Expected**: Token saved (check with login persistence test)

#### Error Cases
- [ ] Submit with empty name → "Full name is required"
- [ ] Submit with empty email → "Email is required"
- [ ] Submit with invalid email (no @) → "Please enter a valid email"
- [ ] Submit with short password (< 8 chars) → "Password must be at least 8 characters"
- [ ] Submit with non-matching passwords → Red toast: "Passwords do not match."
- [ ] Submit with existing email → Red toast with validation error
- [ ] Disconnect internet, submit → Red toast: "Network error. Please check your internet connection."

#### UI Tests
- [ ] Loading indicator shows during registration
- [ ] Button disabled during loading
- [ ] Form fields validate on submit
- [ ] Navigation between steps works
- [ ] Back button works on each step

### 2. Login Flow

#### Happy Path
- [ ] Open app (after logout or fresh install)
- [ ] Enter registered email
- [ ] Enter correct password
- [ ] Click "Sign In" button
- [ ] **Expected**: Loading indicator appears
- [ ] **Expected**: Green success toast: "Login successful! Welcome back, {name}."
- [ ] **Expected**: Redirected to home screen
- [ ] **Expected**: Token saved (check with login persistence test)

#### Error Cases
- [ ] Submit with empty email → "Email is required"
- [ ] Submit with invalid email format → "Please enter a valid email"
- [ ] Submit with empty password → "This field is required"
- [ ] Submit with wrong email → Red toast: "Invalid email or password. Please try again."
- [ ] Submit with wrong password → Red toast: "Invalid email or password. Please try again."
- [ ] Disconnect internet, submit → Red toast: "Network error. Please check your internet connection."

#### UI Tests
- [ ] Loading indicator shows during login
- [ ] Button disabled during loading
- [ ] Email field validates format
- [ ] Password field hides characters
- [ ] "Create one" link navigates to register screen

### 3. Token Persistence

#### Test Saved Token
- [ ] Login successfully
- [ ] Close app completely (swipe away from recent apps)
- [ ] Reopen app
- [ ] Check in code/debug:
  ```dart
  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();
  print('Logged in: $isLoggedIn'); // Should be true
  ```
- [ ] **Expected**: Token still exists
- [ ] **Expected**: User data retrievable

#### Test Token Cleared on Logout
- [ ] Login successfully
- [ ] Call logout:
  ```dart
  await authService.logout();
  ```
- [ ] Check in code/debug:
  ```dart
  final isLoggedIn = await authService.isLoggedIn();
  print('Logged in: $isLoggedIn'); // Should be false
  ```
- [ ] **Expected**: Token cleared
- [ ] **Expected**: User data cleared

### 4. API Service Tests

#### Auth Service
- [ ] Test `isLoggedIn()` - returns correct boolean
- [ ] Test `getSavedUser()` - returns User object when logged in
- [ ] Test `getSavedUser()` - returns null when not logged in
- [ ] Test `getCurrentUser()` - fetches fresh user data from API
- [ ] Test `updateProfile()` with name change - updates successfully
- [ ] Test `updateProfile()` with email change - updates successfully
- [ ] Test `logout()` - clears token and storage

#### Product Service (Optional - if implementing products)
- [ ] Test `getProducts()` - returns list of products
- [ ] Test `getProduct(id)` - returns single product
- [ ] Test `getCategories()` - returns list of categories
- [ ] Test `getUserProducts()` - returns user's products (requires auth)

### 5. Error Handling

#### Network Errors
- [ ] Disconnect internet
- [ ] Attempt login
- [ ] **Expected**: Red toast: "Network error. Please check your internet connection."

#### Validation Errors (422)
- [ ] Submit invalid data (e.g., email already exists)
- [ ] **Expected**: Red toast with specific validation errors

#### Authentication Errors (401)
- [ ] Use invalid credentials
- [ ] **Expected**: Red toast: "Invalid email or password. Please try again."

#### Server Errors (500+)
- [ ] Simulate server error (stop backend)
- [ ] Attempt API call
- [ ] **Expected**: Red toast: "Server error. Please try again later."

### 6. Edge Cases

#### Rapid Clicks
- [ ] Click "Sign In" button multiple times rapidly
- [ ] **Expected**: Button disabled after first click
- [ ] **Expected**: Only one API call made

#### App State
- [ ] Login, minimize app, reopen
- [ ] **Expected**: Still logged in
- [ ] Login, force close app, reopen
- [ ] **Expected**: Still logged in

#### Long Responses
- [ ] Simulate slow network (developer tools)
- [ ] Attempt login
- [ ] **Expected**: Loading indicator continues until response
- [ ] **Expected**: Timeout after 30 seconds (configured)

### 7. Security Tests

#### Token Storage
- [ ] Login successfully
- [ ] Check device storage (SharedPreferences)
- [ ] **Expected**: Token is stored
- [ ] **Expected**: Password is NOT stored

#### Token in Requests
- [ ] Login successfully
- [ ] Make authenticated API call (e.g., get current user)
- [ ] Inspect network request (Charles Proxy/Wireshark)
- [ ] **Expected**: Header includes `Authorization: Bearer {token}`

#### HTTPS
- [ ] Check API config
- [ ] **Expected**: Production URL uses HTTPS
- [ ] Make API call in production
- [ ] **Expected**: Connection is secure (padlock icon in inspector)

## 🐛 Debugging Tips

### Check Token
```dart
final storage = StorageService();
final token = await storage.getToken();
print('Token: $token');
```

### Check User Data
```dart
final storage = StorageService();
final user = await storage.getUser();
print('User: ${user?.toJson()}');
```

### Clear Storage (Reset)
```dart
final storage = StorageService();
await storage.clearAll();
print('Storage cleared');
```

### Check API Response
```dart
try {
  final response = await authService.login(...);
  print('Response: ${response.toJson()}');
} on ApiError catch (e) {
  print('Error: ${e.message}');
  print('Status: ${e.statusCode}');
  print('Errors: ${e.errors}');
}
```

### Test Backend Connection
```bash
curl -X GET "https://rented-backend-api-production.up.railway.app/api/v1/" \
  -H "Accept: application/json"
```
Expected response:
```json
{
  "status": "success",
  "message": "API is working",
  "version": "v1",
  "timestamp": "2025-12-03T14:30:45.000000Z"
}
```

## 📊 Test Results Template

### Registration Test Results
- Date tested: ___________
- Device/Emulator: ___________
- Happy path: ☐ Pass ☐ Fail
- Error cases: ☐ Pass ☐ Fail
- UI responsiveness: ☐ Pass ☐ Fail
- Notes: ___________

### Login Test Results
- Date tested: ___________
- Device/Emulator: ___________
- Happy path: ☐ Pass ☐ Fail
- Error cases: ☐ Pass ☐ Fail
- UI responsiveness: ☐ Pass ☐ Fail
- Notes: ___________

### Token Persistence Test Results
- Date tested: ___________
- Token saved: ☐ Pass ☐ Fail
- Token persists after restart: ☐ Pass ☐ Fail
- Token cleared on logout: ☐ Pass ☐ Fail
- Notes: ___________

## ✅ Sign-off

- [ ] All tests passed
- [ ] No critical issues found
- [ ] Documentation reviewed
- [ ] Code formatted
- [ ] Ready for development

**Tester**: ___________
**Date**: ___________
**Signature**: ___________

---

**Good luck with testing! 🧪**
