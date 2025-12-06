# FlutterFire Configuration Steps

## ✅ You've installed Firebase CLI - Now run:

```bash
cd /Users/Apple/StudioProjects/RENTED
flutterfire configure
```

## What will happen:

1. **Select Firebase Project**: Choose `rented-73580` (your project)
2. **Select Platforms**: 
   - ✅ Android (already configured)
   - ✅ iOS (if you need it)
   - ✅ Web (optional)
   - ✅ macOS (optional)

3. **Files Generated**:
   - `lib/firebase_options.dart` - Firebase configuration for all platforms

## After running `flutterfire configure`:

### Step 1: Uncomment Firebase Options in main.dart

The code is already prepared! Just uncomment these lines in `lib/main.dart`:

**Line 41** - Uncomment:
```dart
import 'firebase_options.dart';  // Remove the // comment
```

**Line 53** - Uncomment:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,  // Remove the // comment
);
```

### Step 2: Test Firebase

```bash
flutter run
```

The app should now initialize Firebase successfully!

## ✅ What's Ready:

- ✅ `main.dart` prepared with commented Firebase options
- ✅ `SocialAuthService` ready for Google Sign-In
- ✅ Laravel backend ready to verify Firebase tokens
- ✅ All dependencies in `pubspec.yaml`

## 🎯 Next Steps After Configuration:

1. Run `flutterfire configure` (you're doing this now!)
2. Uncomment the two lines in `main.dart`
3. Test Google Sign-In in the app
4. Move the Admin SDK JSON to Laravel (if not done yet)
