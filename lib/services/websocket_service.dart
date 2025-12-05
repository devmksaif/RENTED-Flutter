import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/messaging_config.dart';
import '../models/api_error.dart';
import 'storage_service.dart';

/// WebSocket service for real-time messaging
/// This service handles WebSocket connections to the messaging microservice
class WebSocketService {
  final StorageService _storageService = StorageService();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  
  // Callbacks
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onMessageSent;
  Function(Map<String, dynamic>)? onUserTyping;
  Function(Map<String, dynamic>)? onMessageRead;
  Function(Map<String, dynamic>)? onUserPresence;
  Function(Map<String, dynamic>)? onConversationUpdated;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnected && _channel != null) {
      return;
    }

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      // Build WebSocket URL with authentication
      final wsUrl = '${MessagingConfig.messagingWsUrl}?token=$token';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Authenticate after connection
      _channel!.sink.add(jsonEncode({
        'event': MessagingConfig.wsAuthenticate,
        'data': {'token': token}
      }));

      // Listen to messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      onConnected?.call();
    } catch (e) {
      _handleError(e);
      _scheduleReconnect();
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _subscription = null;
    _isConnected = false;
    onDisconnected?.call();
  }

  /// Join a conversation room
  void joinConversation(int conversationId) {
    if (!_isConnected || _channel == null) return;
    
    _channel!.sink.add(jsonEncode({
      'event': MessagingConfig.wsJoinConversation,
      'data': {'conversation_id': conversationId}
    }));
  }

  /// Leave a conversation room
  void leaveConversation(int conversationId) {
    // Implementation depends on microservice API
    // For now, just disconnect if needed
  }

  /// Send a message via WebSocket
  void sendMessage({
    required int conversationId,
    required String content,
    String type = 'text',
  }) {
    if (!_isConnected || _channel == null) return;
    
    _channel!.sink.add(jsonEncode({
      'event': MessagingConfig.wsSendMessage,
      'data': {
        'conversation_id': conversationId,
        'content': content,
        'type': type,
      }
    }));
  }

  /// Send typing indicator
  void sendTyping(int conversationId, bool isTyping) {
    if (!_isConnected || _channel == null) return;
    
    _channel!.sink.add(jsonEncode({
      'event': MessagingConfig.wsTyping,
      'data': {
        'conversation_id': conversationId,
        'is_typing': isTyping,
      }
    }));
  }

  /// Mark messages as read
  void markRead(int conversationId, List<int> messageIds) {
    if (!_isConnected || _channel == null) return;
    
    _channel!.sink.add(jsonEncode({
      'event': MessagingConfig.wsMarkRead,
      'data': {
        'conversation_id': conversationId,
        'message_ids': messageIds,
      }
    }));
  }

  /// Update user presence
  void updatePresence(String status) {
    if (!_isConnected || _channel == null) return;
    
    _channel!.sink.add(jsonEncode({
      'event': MessagingConfig.wsPresenceUpdate,
      'data': {'status': status}
    }));
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      final event = data['event'] ?? data['type'];
      final payload = data['data'] ?? data;

      switch (event) {
        case MessagingConfig.wsMessageReceived:
          onMessageReceived?.call(payload);
          break;
        case MessagingConfig.wsMessageSent:
          onMessageSent?.call(payload);
          break;
        case MessagingConfig.wsUserTyping:
          onUserTyping?.call(payload);
          break;
        case MessagingConfig.wsMessageRead:
          onMessageRead?.call(payload);
          break;
        case MessagingConfig.wsUserPresence:
          onUserPresence?.call(payload);
          break;
        case MessagingConfig.wsConversationUpdated:
          onConversationUpdated?.call(payload);
          break;
        case MessagingConfig.wsError:
          onError?.call(payload['message'] ?? 'Unknown error');
          break;
        default:
          // Handle unknown events
          break;
      }
    } catch (e) {
      onError?.call('Failed to parse message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    _isConnected = false;
    onError?.call(error.toString());
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    _isConnected = false;
    onDisconnected?.call();
    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= MessagingConfig.wsMaxReconnectAttempts) {
      onError?.call('Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      MessagingConfig.wsReconnectDelay * (_reconnectAttempts + 1),
      () {
        _reconnectAttempts++;
        connect();
      },
    );
  }

  /// Check if connected
  bool get isConnected => _isConnected;
}

