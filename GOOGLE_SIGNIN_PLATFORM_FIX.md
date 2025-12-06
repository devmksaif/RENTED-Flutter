# Google Sign-In Platform Crash Fix

## 🐛 Issue
App crashes immediately after "Starting Google Sign-In with Firebase" - the crash happens during the platform channel call to Google Sign-In.

## ✅ Fix Applied

### 1. Added PlatformException Handling
- Wrapped `_googleSignIn.signIn()` in try-catch
- Specifically catches `PlatformException` which is thrown by platform channels
- Provides user-friendly error messages for different error codes

### 2. Enhanced Logging
- Added logging before and after platform calls
- Better error tracking for debugging

---

## 🔧 Platform Configuration Required

### Android Configuration

#### Step 1: Get SHA-1 Fingerprint

```bash
# For debug keystore
cd android
./gradlew signingReport

# Or manually
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `rented-73580`
3. Go to **Project Settings** → **Your apps** → **Android app**
4. Click **Add fingerprint**
5. Paste your SHA-1 fingerprint
6. Download the updated `google-services.json`
7. Replace `android/app/google-services.json` with the new file

#### Step 3: Verify google-services.json

Make sure `android/app/google-services.json` exists and contains:
- `client` array with OAuth client IDs
- `oauth_client` entries for Google Sign-In

---

### iOS Configuration

#### Step 1: Add URL Scheme to Info.plist

Add this to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

**To find YOUR-CLIENT-ID:**
1. Open `ios/Runner/GoogleService-Info.plist`
2. Find `REVERSED_CLIENT_ID` value
3. Use that value in the URL scheme above

#### Step 2: Verify GoogleService-Info.plist

Make sure `ios/Runner/GoogleService-Info.plist` exists and contains:
- `CLIENT_ID` for OAuth
- `REVERSED_CLIENT_ID` for URL scheme

---

## 🧪 Testing After Configuration

1. **Clean build:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Rebuild:**
   ```bash
   flutter run
   ```

3. **Test Google Sign-In:**
   - Tap "Sign in with Google"
   - Should see Google account picker
   - Should NOT crash

---

## 🐛 Debugging Platform Errors

### Check Android Logs
```bash
adb logcat | grep -i "google\|signin\|auth"
```

### Check iOS Logs
- Open Xcode
- Run app from Xcode
- Check Console for errors

### Common Platform Errors

#### Error: "sign_in_failed"
**Cause**: Missing SHA-1 fingerprint or incorrect OAuth client ID
**Fix**: Add SHA-1 to Firebase Console and download new `google-services.json`

#### Error: "network_error"
**Cause**: No internet connection or Firebase project not active
**Fix**: Check internet connection and Firebase project status

#### Error: "sign_in_canceled"
**Cause**: User cancelled the sign-in
**Fix**: This is normal, no action needed

#### Error: PlatformException with no code
**Cause**: Google Sign-In plugin not properly configured
**Fix**: 
1. Verify `google-services.json` / `GoogleService-Info.plist` exist
2. Clean and rebuild
3. Check Firebase project is active

---

## 📋 Configuration Checklist

### Android
- [ ] `google-services.json` in `android/app/`
- [ ] SHA-1 fingerprint added to Firebase Console
- [ ] `google-services.json` downloaded after adding SHA-1
- [ ] Google Services plugin in `build.gradle.kts`
- [ ] OAuth client ID exists in Firebase Console

### iOS
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] URL scheme added to `Info.plist`
- [ ] Bundle ID matches Firebase project
- [ ] OAuth client ID exists in Firebase Console

### General
- [ ] Firebase project is active
- [ ] Google Sign-In enabled in Firebase Console
- [ ] `firebase_options.dart` exists
- [ ] Firebase initialized in `main.dart`

---

## 🚨 If Still Crashing

1. **Check the exact error in logs:**
   ```bash
   flutter run --verbose
   ```

2. **Check platform-specific logs:**
   - Android: `adb logcat`
   - iOS: Xcode Console

3. **Verify Firebase Console:**
   - Project is active
   - Authentication → Sign-in method → Google is enabled
   - OAuth client IDs are configured

4. **Try these steps:**
   ```bash
   # Clean everything
   flutter clean
   cd android && ./gradlew clean && cd ..
   cd ios && pod deintegrate && pod install && cd ..
   
   # Rebuild
   flutter pub get
   flutter run
   ```

---

## ✅ Expected Behavior After Fix

1. User taps "Sign in with Google"
2. Log shows: `🔐 Calling Google Sign-In platform method...`
3. Google account picker appears (or error message if misconfigured)
4. User selects account
5. Log shows: `✅ Google Sign-In platform call completed`
6. Authentication continues...

**The app should NOT crash** - it will show an error message instead.

---

## 📝 Next Steps

1. **Add SHA-1 fingerprint** (Android) - Most common cause of crashes
2. **Add URL scheme** (iOS) - Required for iOS
3. **Test again** - Should work or show clear error message
4. **Check logs** - Enhanced logging will show exactly where it fails

The PlatformException handling will now catch the crash and show a user-friendly error message instead of crashing the app.
