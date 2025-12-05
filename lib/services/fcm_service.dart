import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import '../models/api_error.dart';

/// Firebase Cloud Messaging Service
/// Handles push notifications from Firebase
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final StorageService _storageService = StorageService();

  String? _fcmToken;
  bool _isInitialized = false;

  // Callbacks
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function(String)? onTokenRefreshed;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.i('✅ FCM: User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        AppLogger.i('⚠️ FCM: User granted provisional notification permission');
      } else {
        AppLogger.w('❌ FCM: User denied notification permission');
        return;
      }

      // Initialize local notifications (for foreground notifications)
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFcmToken();

      // Set up message handlers
      _setupMessageHandlers();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _updateTokenOnServer(newToken);
        onTokenRefreshed?.call(newToken);
        AppLogger.i('🔄 FCM: Token refreshed: $newToken');
      });

      _isInitialized = true;
      AppLogger.i('✅ FCM service initialized');
    } catch (e, stackTrace) {
      AppLogger.e('❌ Failed to initialize FCM service', e, stackTrace);
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'rented_notifications',
      'Rented Notifications',
      description: 'Notifications for rentals, messages, and updates',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Get FCM token and send to server
  Future<void> _getFcmToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        AppLogger.i('📱 FCM Token: $_fcmToken');
        await _updateTokenOnServer(_fcmToken!);
      }
    } catch (e) {
      AppLogger.e('❌ Failed to get FCM token', e);
    }
  }

  /// Update FCM token on server
  Future<void> _updateTokenOnServer(String token) async {
    try {
      final userToken = await _storageService.getToken();
      if (userToken == null) {
        AppLogger.d('👤 User not logged in, skipping token update');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fcm/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        AppLogger.i('✅ FCM token updated on server');
      } else {
        AppLogger.w('⚠️ Failed to update FCM token on server: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.e('❌ Error updating FCM token on server', e);
    }
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages (when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.i('📬 FCM: Foreground message received');
      _handleForegroundMessage(message);
    });

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.i('📬 FCM: Notification tapped (app in background)');
      _handleNotificationTap(message);
    });

    // Handle notification when app is opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        AppLogger.i('📬 FCM: App opened from notification');
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle foreground message (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Show local notification
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'rented_notifications',
            'Rented Notifications',
            channelDescription: 'Notifications for rentals, messages, and updates',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(data),
      );

      // Call callback
      onNotificationReceived?.call(data);
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    onNotificationReceived?.call(data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        onNotificationReceived?.call(data);
      } catch (e) {
        AppLogger.e('❌ Error parsing notification payload', e);
      }
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if FCM is initialized
  bool get isInitialized => _isInitialized;

  /// Delete FCM token (on logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      AppLogger.i('🗑️ FCM token deleted');
    } catch (e) {
      AppLogger.e('❌ Failed to delete FCM token', e);
    }
  }
}

/// Top-level function for background message handler
/// Must be top-level (not a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.i('📬 FCM: Background message received: ${message.messageId}');
  // Handle background message if needed
}

