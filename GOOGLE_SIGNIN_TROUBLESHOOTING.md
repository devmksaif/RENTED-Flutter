# Google Sign-In Troubleshooting Guide

## Error: "Unauthenticated" (401) when signing in with Google

### Issue
The app shows a 401 error when trying to sign in with Google, and the connection is lost.

### Root Causes

1. **Firebase credentials file not in Laravel**
   - The backend needs the Firebase Admin SDK JSON file to verify tokens
   - File should be at: `Laravel/rented-api/storage/app/firebase-credentials.json`

2. **Backend failing to verify Firebase token**
   - If FirebaseService can't initialize, it falls back to using provided data
   - But if there's an error, it might return 401

3. **Token not being saved properly**
   - The token might not be saved before navigation

---

## ✅ Solution Steps

### Step 1: Move Firebase Credentials to Laravel

```bash
# Make sure the credentials file is in the right place
mkdir -p Laravel/rented-api/storage/app
cp rented-73580-firebase-adminsdk-fbsvc-9749ae0f1a.json \
   Laravel/rented-api/storage/app/firebase-credentials.json

# Set proper permissions
chmod 644 Laravel/rented-api/storage/app/firebase-credentials.json
```

### Step 2: Install Laravel Firebase Package

```bash
cd Laravel/rented-api
composer require kreait/firebase-php
```

### Step 3: Test Backend Endpoint

Test the endpoint directly:

```bash
curl -X POST http://167.86.87.72:8000/api/v1/auth/google/firebase \
  -H "Content-Type: application/json" \
  -d '{
    "id_token": "test_token",
    "email": "test@example.com",
    "name": "Test User"
  }'
```

### Step 4: Check Laravel Logs

```bash
tail -f Laravel/rented-api/storage/logs/laravel.log
```

Look for:
- "Firebase credentials file not found"
- "Firebase token verification failed"
- Any other errors

---

## How It Works Now

### With Firebase Credentials (Recommended)

1. Flutter app gets Firebase ID token
2. Sends token to Laravel backend
3. Laravel verifies token using Firebase Admin SDK
4. Creates/logs in user
5. Returns Laravel Sanctum token
6. App saves token and navigates

### Without Firebase Credentials (Fallback)

1. Flutter app gets Firebase ID token
2. Sends token + email/name to Laravel backend
3. Laravel uses provided data (no verification)
4. Creates/logs in user
5. Returns Laravel Sanctum token
6. App saves token and navigates

---

## Debugging

### Check Flutter Logs

Look for these log messages:
- `🔐 Starting Google Sign-In with Firebase`
- `✅ Firebase Google Sign-In successful`
- `🔐 Authenticating with backend using Firebase token`
- `✅ Backend authentication successful`

### Check Laravel Logs

Look for:
- `Firebase token verified` - Token was verified successfully
- `Firebase token verification failed` - Token verification failed (but continues)
- `Firebase credentials file not found` - Credentials file missing

### Common Issues

1. **"Firebase credentials file not found"**
   - **Fix**: Move the JSON file to `Laravel/rented-api/storage/app/firebase-credentials.json`

2. **"Invalid Firebase token"**
   - **Fix**: Make sure Firebase is properly configured in Flutter
   - Check `firebase_options.dart` exists and is correct

3. **"Unauthenticated" error**
   - **Fix**: Check if the backend endpoint is working
   - Verify the route is registered in `api.php`
   - Check Laravel logs for detailed error

4. **Connection lost / App crashes**
   - **Fix**: Check for unhandled exceptions
   - Make sure all errors are caught and logged

---

## Testing

### Test Firebase Sign-In Flow

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Tap "Sign in with Google"**

3. **Check logs for:**
   - Firebase authentication success
   - Backend authentication success
   - Token saved

4. **If it fails, check:**
   - Laravel logs for backend errors
   - Flutter logs for client errors
   - Firebase credentials file location

---

## Quick Fix Checklist

- [ ] Firebase credentials file moved to Laravel
- [ ] `composer require kreait/firebase-php` installed
- [ ] File permissions set correctly (644)
- [ ] Laravel logs checked for errors
- [ ] Flutter logs checked for errors
- [ ] Backend endpoint tested directly
- [ ] Firebase properly configured in Flutter

---

## Current Status

✅ **Fixed Issues:**
- FirebaseService now uses lazy initialization (won't crash if file missing)
- Better error handling in backend
- Improved error logging in Flutter
- Token saved before navigation

🔧 **Next Steps:**
1. Move Firebase credentials file to Laravel
2. Install Firebase PHP package
3. Test Google Sign-In again
