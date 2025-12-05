# Firebase Cloud Messaging (FCM) Integration Guide

## Overview
This guide will help you integrate Firebase Cloud Messaging for push notifications in your Flutter app.

## Prerequisites
1. Firebase account (free tier is sufficient)
2. Firebase project created at https://console.firebase.google.com
3. Android and iOS apps registered in Firebase Console

---

## Step 1: Firebase Console Setup

### 1.1 Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Enter project name: "Rented" (or your preferred name)
4. Follow the setup wizard

### 1.2 Add Android App
1. In Firebase Console, click "Add app" → Android
2. Package name: `com.example.rented` (check your `android/app/build.gradle`)
3. Download `google-services.json`
4. Place it in `android/app/`

### 1.3 Add iOS App
1. In Firebase Console, click "Add app" → iOS
2. Bundle ID: Check your `ios/Runner.xcodeproj` or `ios/Runner/Info.plist`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`

### 1.4 Get Server Key
1. Go to Project Settings → Cloud Messaging
2. Copy the "Server key" (you'll need this for Laravel backend)

---

## Step 2: Flutter Setup

### 2.1 Add Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.1  # For local notifications
```

### 2.2 Android Configuration

#### Update `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

#### Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        // Add this
        minSdkVersion 21
    }
}
```

#### Update `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <!-- Add this for notification channels -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="rented_notifications" />
    </application>
</manifest>
```

### 2.3 iOS Configuration

#### Update `ios/Podfile`:
```ruby
platform :ios, '12.0'
```

#### Update `ios/Runner/Info.plist`:
Add these permissions:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

#### In Xcode:
1. Open `ios/Runner.xcworkspace`
2. Go to Signing & Capabilities
3. Add "Push Notifications" capability
4. Add "Background Modes" → Enable "Remote notifications"

---

## Step 3: Flutter Code Implementation

### 3.1 Initialize Firebase
Update `lib/main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Will be generated

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### 3.2 Generate Firebase Options
Run:
```bash
flutter pub add firebase_core
flutter pub add firebase_messaging
dart pub global activate flutterfire_cli
flutterfire configure
```

This will generate `lib/firebase_options.dart`

---

## Step 4: Backend Integration (Laravel)

### 4.1 Install Laravel FCM Package
```bash
composer require laravel-notification-channels/fcm
```

### 4.2 Configure FCM
Add to `.env`:
```
FCM_SERVER_KEY=your_server_key_from_firebase_console
```

### 4.3 Create FCM Notification Channel
```php
// app/Notifications/RentalNotification.php
use Illuminate\Notifications\Notification;
use NotificationChannels\Fcm\FcmChannel;
use NotificationChannels\Fcm\FcmMessage;

class RentalNotification extends Notification
{
    public function via($notifiable)
    {
        return [FcmChannel::class];
    }

    public function toFcm($notifiable)
    {
        return FcmMessage::create()
            ->setData([
                'type' => 'rental_created',
                'rental_id' => $this->rental->id,
            ])
            ->setNotification(\NotificationChannels\Fcm\Resources\Notification::create()
                ->setTitle('New Rental Request')
                ->setBody('Someone wants to rent your product')
            );
    }
}
```

### 4.4 Store FCM Tokens
Add migration:
```php
Schema::table('users', function (Blueprint $table) {
    $table->string('fcm_token')->nullable();
});
```

### 4.5 API Endpoint to Update Token
```php
// routes/api.php
Route::post('/fcm/token', [FcmController::class, 'updateToken']);

// app/Http/Controllers/Api/FcmController.php
public function updateToken(Request $request)
{
    $request->validate(['token' => 'required|string']);
    
    auth()->user()->update([
        'fcm_token' => $request->token
    ]);
    
    return response()->json(['message' => 'Token updated']);
}
```

---

## Step 5: Testing

### 5.1 Test from Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Enter FCM token from your app
4. Send notification

### 5.2 Test from Laravel
```php
$user = User::find(1);
$user->notify(new RentalNotification($rental));
```

---

## Troubleshooting

### Android Issues
- Ensure `google-services.json` is in `android/app/`
- Check that `minSdkVersion` is 21+
- Verify internet permission is set

### iOS Issues
- Ensure `GoogleService-Info.plist` is in `ios/Runner/`
- Check Push Notifications capability is enabled
- Verify APNs certificates are set up in Firebase Console

### Common Errors
- "MissingPluginException": Run `flutter clean && flutter pub get`
- "Token not received": Check device permissions
- "Notifications not showing": Verify notification channel (Android) or APNs (iOS)

---

## Next Steps
1. Implement the FCM service in Flutter (see `lib/services/fcm_service.dart`)
2. Integrate with existing `NotificationManager`
3. Update backend to send FCM notifications
4. Add notification actions (tap to open specific screens)
5. Handle notification data payloads

