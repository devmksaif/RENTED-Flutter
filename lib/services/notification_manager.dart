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
  GlobalKey<NavigatorState>? _navigatorKey;
  
  // Callbacks
  Function(int)? onUnreadCountChanged;
  Function(NotificationItem)? onNewNotification;
  
  /// Set navigator key for navigation handling
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

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
      // This will gracefully skip if Firebase is not configured
      try {
        await _fcmService.initialize();
        if (_fcmService.isInitialized) {
          // Set up FCM notification handler
          _fcmService.onNotificationReceived = (data) {
            _handleFcmNotification(data);
          };
          AppLogger.i('✅ FCM service initialized and ready');
        } else {
          AppLogger.w('⚠️ FCM service not initialized (Firebase may not be configured)');
          AppLogger.w('💡 To enable push notifications, run: flutterfire configure');
        }
      } catch (e, stackTrace) {
        AppLogger.w('⚠️ FCM initialization failed (may not be configured): $e');
        AppLogger.d('Stack trace: $stackTrace');
        // Continue without FCM - app will work with WebSocket notifications only
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
      String route = '/notifications'; // Default route
      dynamic routeArguments;

      switch (type) {
        case 'rental_created':
          title = 'New Rental Request';
          message = 'Someone wants to rent your product';
          route = '/my-rentals';
          break;
        case 'rental_status_changed':
          title = 'Rental Status Updated';
          message = 'Your rental status has changed';
          final rentalId = data['rental_id'] as int?;
          if (rentalId != null) {
            route = '/rental-detail';
            routeArguments = rentalId;
          } else {
            route = '/my-rentals';
          }
          break;
        case 'new_message':
          title = 'New Message';
          message = 'You have a new message';
          final conversationId = data['conversation_id'] as int?;
          if (conversationId != null) {
            route = '/chat';
            routeArguments = conversationId;
          } else {
            route = '/conversations';
          }
          break;
        case 'offer_received':
          title = 'New Offer';
          message = 'You have received a new offer';
          route = '/notifications';
          break;
        case 'product_approved':
          title = 'Product Approved';
          message = 'Your product has been approved';
          route = '/my-products';
          break;
        case 'product_rejected':
          title = 'Product Rejected';
          message = 'Your product listing was rejected';
          route = '/my-products';
          break;
        default:
          title = data['title'] as String? ?? title;
          message = data['body'] as String? ?? message;
          route = data['route'] as String? ?? '/notifications';
      }

      // Show toast notification
      Fluttertoast.showToast(
        msg: message,
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );

      // Navigate to appropriate screen if navigator is available
      // route is always assigned in switch statement, so it's never null here
      if (_navigatorKey?.currentState != null) {
        final currentRoute = route; // route is always assigned in switch statement
        Future.delayed(const Duration(milliseconds: 500), () {
          if (routeArguments != null) {
            _navigatorKey!.currentState!.pushNamed(currentRoute, arguments: routeArguments);
          } else {
            _navigatorKey!.currentState!.pushNamed(currentRoute);
          }
        });
      }

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

      String title = 'Notification';
      String message = 'Notification';
      String route = '/notifications'; // Default route
      dynamic routeArguments;

      switch (type) {
        case 'rental.created':
          title = 'New Rental Request';
          message = 'Someone wants to rent your product';
          route = '/my-rentals';
          break;
        case 'rental.status.changed':
          final newStatus = data['new_status'] as String?;
          final rentalId = data['rental_id'] as int?;
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
          if (rentalId != null) {
            route = '/rental-detail';
            routeArguments = rentalId;
          } else {
            route = '/my-rentals';
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

      // Navigate to appropriate screen if navigator is available
      // route is always assigned in switch statement, so it's never null here
      if (_navigatorKey?.currentState != null) {
        final currentRoute = route; // route is always assigned in switch statement
        Future.delayed(const Duration(milliseconds: 500), () {
          if (routeArguments != null) {
            _navigatorKey!.currentState!.pushNamed(currentRoute, arguments: routeArguments);
          } else {
            _navigatorKey!.currentState!.pushNamed(currentRoute);
          }
        });
      }

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

