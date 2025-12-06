# Firebase Setup Guide

## Overview
You have the Firebase Admin SDK JSON file. This guide will help you:
1. Set up Firebase for Flutter app (generate `firebase_options.dart`)
2. Set up Firebase Admin SDK for Laravel backend (verify Firebase ID tokens)

---

## Part 1: Flutter App Setup

### Step 1: Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### Step 2: Configure Firebase for Flutter
```bash
cd /Users/Apple/StudioProjects/RENTED
flutterfire configure
```

This will:
- Ask you to select your Firebase project (rented-73580)
- Generate `lib/firebase_options.dart`
- Configure Android and iOS automatically

### Step 3: Update main.dart
The `main.dart` already has Firebase initialization, but we need to import the options:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ... rest of code
  }
}
```

---

## Part 2: Laravel Backend Setup

### Step 1: Move Admin SDK JSON to Laravel
Move the Admin SDK JSON file to your Laravel project:

```bash
mv /Users/Apple/StudioProjects/RENTED/rented-73580-firebase-adminsdk-fbsvc-9749ae0f1a.json \
   /Users/Apple/StudioProjects/RENTED/Laravel/rented-api/storage/app/firebase-credentials.json
```

**IMPORTANT**: Add this file to `.gitignore` to keep credentials secure!

### Step 2: Install Firebase Admin SDK for PHP
```bash
cd /Users/Apple/StudioProjects/RENTED/Laravel/rented-api
composer require kreait/firebase-php
```

### Step 3: Create Firebase Service
Create a service to verify Firebase ID tokens in Laravel.

---

## Quick Start Commands

Run these commands in order:

```bash
# 1. Install FlutterFire CLI
dart pub global activate flutterfire_cli

# 2. Configure Flutter Firebase
cd /Users/Apple/StudioProjects/RENTED
flutterfire configure

# 3. Install Flutter dependencies
flutter pub get

# 4. Move Admin SDK JSON to Laravel (secure location)
mkdir -p Laravel/rented-api/storage/app
mv rented-73580-firebase-adminsdk-fbsvc-9749ae0f1a.json \
   Laravel/rented-api/storage/app/firebase-credentials.json

# 5. Install Laravel Firebase package
cd Laravel/rented-api
composer require kreait/firebase-php
```

---

## Next Steps After Setup

1. **Update Laravel `.gitignore`** to exclude the credentials file
2. **Create Firebase Service** in Laravel to verify tokens
3. **Update SocialAuthController** to use Firebase Admin SDK for token verification
4. **Test Google Sign-In** in the Flutter app
