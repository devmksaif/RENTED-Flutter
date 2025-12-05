import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class WebSocketService {
  final StorageService _storageService = StorageService();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  String? _currentConversationId;
  String? _currentUserId;

  // Callbacks (for backward compatibility with existing chat screen)
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onUserTyping;
  Function(Map<String, dynamic>)? onMessageRead;
  Function(Map<String, dynamic>)? onRentalNotification;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  // New callbacks (alternative naming)
  Function(Map<String, dynamic>)? onMessage;
  Function(Map<String, dynamic>)? onTyping;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnected && _channel != null) {
      AppLogger.i('🔌 WebSocket already connected');
      return;
    }

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.e('❌ No authentication token found');
        throw Exception('Not authenticated');
      }

      final user = await _storageService.getUser();
      _currentUserId = user?.id.toString();

      // Get WebSocket URL from API config
      // Reverb typically runs on ws://host:port/app/{app_key}
      final wsHost = ApiConfig.baseUrl
          .replaceAll('http://', '')
          .replaceAll('https://', '')
          .split(':')[0];
      final wsPort = '8080'; // Default Reverb port
      final wsScheme = ApiConfig.baseUrl.startsWith('https') ? 'wss' : 'ws';
      
      // For Reverb, we need to use the proper format
      // ws://host:port/app/{app_key}?protocol=7&client=js&version=8.4.0&flash=false
      final wsUrl = '$wsScheme://$wsHost:$wsPort/app/reverb-app-key?protocol=7&client=flutter&version=1.0.0';

      AppLogger.i('🔌 Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _subscription = _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          AppLogger.e('❌ WebSocket error', error);
          _isConnected = false;
          onError?.call(error);
        },
        onDone: () {
          AppLogger.w('⚠️ WebSocket connection closed');
          _isConnected = false;
          onDisconnected?.call();
        },
        cancelOnError: false,
      );

      _isConnected = true;
      onConnected?.call();
      AppLogger.i('✅ WebSocket connected successfully');

      // Subscribe to user notifications channel
      _subscribeToUserNotifications();
    } catch (e, stackTrace) {
      AppLogger.e('❌ Failed to connect WebSocket', e, stackTrace);
      _isConnected = false;
      onError?.call(e);
      rethrow;
    }
  }

  /// Subscribe to a conversation channel (alias for joinConversation)
  Future<void> subscribeToConversation(int conversationId) async {
    await joinConversation(conversationId);
  }

  /// Join a conversation channel
  Future<void> joinConversation(int conversationId) async {
    if (!_isConnected || _channel == null) {
      await connect();
    }

    _currentConversationId = conversationId.toString();

    try {
      // Subscribe to presence channel: conversation.{id}
      final subscribeMessage = {
        'event': 'pusher:subscribe',
        'data': {
          'channel': 'presence-conversation.$conversationId',
        },
      };

      _channel?.sink.add(jsonEncode(subscribeMessage));
      AppLogger.i('📡 Subscribed to conversation $conversationId');
    } catch (e, stackTrace) {
      AppLogger.e('❌ Failed to subscribe to conversation', e, stackTrace);
      rethrow;
    }
  }

  /// Unsubscribe from current conversation
  void unsubscribeFromConversation() {
    if (_currentConversationId != null && _channel != null) {
      try {
        final unsubscribeMessage = {
          'event': 'pusher:unsubscribe',
          'data': {
            'channel': 'presence-conversation.$_currentConversationId',
          },
        };

        _channel!.sink.add(jsonEncode(unsubscribeMessage));
        AppLogger.i('📡 Unsubscribed from conversation $_currentConversationId');
      } catch (e) {
        AppLogger.e('❌ Failed to unsubscribe from conversation', e);
      }
    }
    _currentConversationId = null;
  }

  /// Subscribe to user notifications channel
  void _subscribeToUserNotifications() {
    if (_currentUserId == null) return;

    try {
      final subscribeMessage = {
        'event': 'pusher:subscribe',
        'data': {
          'channel': 'private-user.$_currentUserId',
        },
      };

      _channel?.sink.add(jsonEncode(subscribeMessage));
      AppLogger.i('📡 Subscribed to user notifications');
    } catch (e) {
      AppLogger.e('❌ Failed to subscribe to notifications', e);
    }
  }

  /// Send typing indicator (alias for sendTyping)
  void sendTypingIndicator(int conversationId, bool isTyping) {
    sendTyping(conversationId, isTyping);
  }

  /// Send typing indicator
  void sendTyping(int conversationId, bool isTyping) {
    // Send via HTTP API instead of WebSocket client events
    // This is more reliable for typing indicators
    // The API endpoint will broadcast the event
    // Implementation can be added if needed, or use HTTP API directly
  }

  /// Update user presence
  void updatePresence(String status) {
    // Presence is automatically managed by Reverb when joining presence channels
    AppLogger.d('👤 Presence updated: $status');
  }

  /// Send message via WebSocket (if needed, otherwise use HTTP API)
  void sendMessage(int conversationId, String content) {
    // Messages should be sent via HTTP API, not WebSocket
    // This method is kept for compatibility but should not be used
    AppLogger.w('⚠️ sendMessage via WebSocket is not recommended. Use HTTP API instead.');
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      final event = data['event'] as String?;
      final channel = data['channel'] as String?;
      final eventData = data['data'];

      if (event == null) return;

      AppLogger.d('📨 WebSocket event: $event on channel: $channel');

      switch (event) {
        case 'pusher:connection_established':
          AppLogger.i('✅ WebSocket connection established');
          break;

        case 'pusher:subscription_succeeded':
          AppLogger.i('✅ Subscribed to channel: $channel');
          break;

        case 'message.sent':
          if (eventData != null) {
            final messageData = Map<String, dynamic>.from(eventData);
            onMessage?.call(messageData);
            onMessageReceived?.call({'message': messageData, 'conversation_id': messageData['conversation_id']});
          }
          break;

        case 'message.read':
          if (eventData != null) {
            final readData = Map<String, dynamic>.from(eventData);
            AppLogger.d('📖 Message read: ${readData['id']}');
            onMessageRead?.call({
              'conversation_id': readData['conversation_id'],
              'message_ids': [readData['id']],
            });
          }
          break;

        case 'user.typing':
          if (eventData != null) {
            final typingData = Map<String, dynamic>.from(eventData);
            onTyping?.call(typingData);
            onUserTyping?.call({
              'conversation_id': _currentConversationId,
              'is_typing': typingData['is_typing'],
              'user_id': typingData['user_id'],
            });
          }
          break;

        case 'rental.created':
        case 'rental.status.changed':
          if (eventData != null) {
            onRentalNotification?.call({
              'type': event,
              'data': eventData,
            });
          }
          break;

        default:
          AppLogger.d('📨 Unhandled WebSocket event: $event');
      }
    } catch (e, stackTrace) {
      AppLogger.e('❌ Error handling WebSocket message', e, stackTrace);
    }
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    unsubscribeFromConversation();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _currentConversationId = null;
    AppLogger.i('🔌 WebSocket disconnected');
  }

  /// Check if connected
  bool get isConnected => _isConnected;
}
