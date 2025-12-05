import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'notification_service.dart';
import 'websocket_service.dart';
import 'storage_service.dart';
import 'fcm_service.dart';
import '../utils/logger.dart';

/// Global notification manager that handles HTTP, WebSocket, and FCM notifications
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  final WebSocketService _wsService = WebSocketService();
  final FcmService _fcmService = FcmService();
  final StorageService _storageService = StorageService();
  
  bool _isInitialized = false;
  int _unreadCount = 0;
  
  // Callbacks
  Function(int)? onUnreadCountChanged;
  Function(NotificationItem)? onNewNotification;

  /// Initialize notification manager, WebSocket, and FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if user is logged in
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.d('👤 User not logged in, skipping notification setup');
        return;
      }

      // Initialize FCM (Firebase Cloud Messaging)
      try {
        await _fcmService.initialize();
        // Set up FCM notification handler
        _fcmService.onNotificationReceived = (data) {
          _handleFcmNotification(data);
        };
      } catch (e) {
        AppLogger.w('⚠️ FCM initialization failed (may not be configured): $e');
      }

      // Set up WebSocket callbacks for rental notifications
      _wsService.onRentalNotification = (notification) {
        _handleRentalNotification(notification);
      };

      // Connect WebSocket
      await _wsService.connect();
      
      // Load initial unread count
      await _refreshUnreadCount();

      _isInitialized = true;
      AppLogger.i('✅ Notification manager initialized');
    } catch (e, stackTrace) {
      AppLogger.e('❌ Failed to initialize notification manager', e, stackTrace);
    }
  }

  /// Handle FCM push notification
  void _handleFcmNotification(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String?;
      if (type == null) return;

      String title = 'Notification';
      String message = 'You have a new notification';

      switch (type) {
        case 'rental_created':
          title = 'New Rental Request';
          message = 'Someone wants to rent your product';
          break;
        case 'rental_status_changed':
          title = 'Rental Status Updated';
          message = 'Your rental status has changed';
          break;
        case 'new_message':
          title = 'New Message';
          message = 'You have a new message';
          break;
        case 'offer_received':
          title = 'New Offer';
          message = 'You have received a new offer';
          break;
        default:
          title = data['title'] as String? ?? title;
          message = data['body'] as String? ?? message;
      }

      // Show toast notification
      Fluttertoast.showToast(
        msg: message,
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );

      // Refresh unread count
      _refreshUnreadCount();

      AppLogger.i('📬 FCM notification received: $title - $message');
    } catch (e, stackTrace) {
      AppLogger.e('❌ Error handling FCM notification', e, stackTrace);
    }
  }

  /// Handle rental notification from WebSocket
  void _handleRentalNotification(Map<String, dynamic> notification) {
    try {
      final type = notification['type'] as String;
      final data = notification['data'] as Map<String, dynamic>?;

      if (data == null) return;

      String title;
      String message;

      switch (type) {
        case 'rental.created':
          title = 'New Rental Request';
          message = 'Someone wants to rent your product';
          break;
        case 'rental.status.changed':
          final newStatus = data['new_status'] as String?;
          title = 'Rental Status Updated';
          switch (newStatus) {
            case 'approved':
              message = 'Your rental request has been approved!';
              break;
            case 'active':
              message = 'Your rental is now active';
              break;
            case 'completed':
              message = 'Your rental has been completed';
              break;
            case 'cancelled':
              message = 'Your rental has been cancelled';
              break;
            default:
              message = 'Rental status has changed';
          }
          break;
        default:
          return;
      }

      // Show toast notification
      Fluttertoast.showToast(
        msg: message,
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );

      // Refresh unread count
      _refreshUnreadCount();

      AppLogger.i('📬 Rental notification received: $title - $message');
    } catch (e, stackTrace) {
      AppLogger.e('❌ Error handling rental notification', e, stackTrace);
    }
  }

  /// Refresh unread notification count
  Future<void> _refreshUnreadCount() async {
    try {
      final notifications = await _notificationService.getNotifications();
      final unread = notifications.where((n) => !n.isRead).length;
      
      if (_unreadCount != unread) {
        _unreadCount = unread;
        onUnreadCountChanged?.call(_unreadCount);
      }
    } catch (e) {
      AppLogger.e('❌ Failed to refresh unread count', e);
    }
  }

  /// Get current unread count
  int get unreadCount => _unreadCount;

  /// Refresh notifications (called when notifications screen is opened)
  Future<void> refreshNotifications() async {
    await _refreshUnreadCount();
  }

  /// Disconnect and cleanup
  void dispose() {
    _wsService.disconnect();
    _fcmService.deleteToken();
    _isInitialized = false;
    AppLogger.i('🔌 Notification manager disposed');
  }

  /// Get FCM token (for debugging or manual token management)
  String? get fcmToken => _fcmService.fcmToken;
}

