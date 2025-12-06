# Firebase Setup Instructions

## ✅ What You Have
- Firebase Admin SDK JSON file: `rented-73580-firebase-adminsdk-fbsvc-9749ae0f1a.json`
- Firebase Project ID: `rented-73580`

## 🚀 Quick Setup Steps

### Step 1: Configure Flutter Firebase (Generate firebase_options.dart)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Navigate to project root
cd /Users/Apple/StudioProjects/RENTED

# Configure Firebase (will ask you to select project: rented-73580)
flutterfire configure

# Install dependencies
flutter pub get
```

**What this does:**
- Generates `lib/firebase_options.dart`
- Configures Android (`google-services.json` already exists)
- Configures iOS (if needed)

### Step 2: Move Admin SDK JSON to Laravel

```bash
# Create storage directory if it doesn't exist
mkdir -p Laravel/rented-api/storage/app

# Move the credentials file
mv rented-73580-firebase-adminsdk-fbsvc-9749ae0f1a.json \
   Laravel/rented-api/storage/app/firebase-credentials.json
```

**Security Note:** The file is already added to `.gitignore` ✅

### Step 3: Install Laravel Firebase Package

```bash
cd Laravel/rented-api
composer require kreait/firebase-php
```

### Step 4: Uncomment Firebase Options in main.dart

After `flutterfire configure` completes, uncomment these lines in `lib/main.dart`:

```dart
import 'firebase_options.dart';  // Uncomment this

// In main() function:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,  // Uncomment this
);
```

## ✅ What's Already Done

1. ✅ **Flutter Code**: Firebase Auth integration in `SocialAuthService`
2. ✅ **Laravel Code**: `FirebaseService` created to verify tokens
3. ✅ **Laravel Controller**: `handleFirebaseAuth` method updated to verify tokens
4. ✅ **Security**: Credentials file added to `.gitignore`
5. ✅ **API Route**: `POST /auth/google/firebase` endpoint ready

## 🧪 Testing

After setup:

1. **Test Flutter App:**
   ```bash
   flutter run
   ```
   - Go to login screen
   - Tap "Sign in with Google"
   - Should authenticate and navigate to home

2. **Check Laravel Logs:**
   ```bash
   tail -f Laravel/rented-api/storage/logs/laravel.log
   ```
   - Should see "Firebase token verified" messages

## 📝 Notes

- **Flutter**: Uses Firebase Auth SDK for Google Sign-In
- **Laravel**: Uses Firebase Admin SDK to verify ID tokens
- **Security**: Tokens are verified server-side before creating/logging in users
- **Fallback**: If Firebase verification fails, it falls back to using provided data (for development)

## 🔧 Troubleshooting

### Flutter: "firebase_options.dart not found"
- Run `flutterfire configure` again
- Make sure you select the correct project (rented-73580)

### Laravel: "Firebase credentials file not found"
- Check file exists: `Laravel/rented-api/storage/app/firebase-credentials.json`
- Check file permissions: `chmod 644 storage/app/firebase-credentials.json`

### Laravel: "Class FirebaseService not found"
- Run `composer dump-autoload`
- Check `app/Services/FirebaseService.php` exists
