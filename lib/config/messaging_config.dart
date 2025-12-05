class MessagingConfig {
  // Messaging Microservice Configuration
  // Update these URLs when the microservice is deployed
  
  // Development
  static const String developmentMessagingUrl = 'http://localhost:3001';
  static const String developmentMessagingWsUrl = 'ws://localhost:3001';
  
  // Production
  static const String productionMessagingUrl = 'http://167.86.87.72:3001';
  static const String productionMessagingWsUrl = 'ws://167.86.87.72:3001';
  
  // Use production by default, change to development when testing locally
  static const String messagingBaseUrl = productionMessagingUrl;
  static const String messagingWsUrl = productionMessagingWsUrl;
  
  // API Endpoints
  static const String conversations = '$messagingBaseUrl/api/conversations';
  static const String messages = '$messagingBaseUrl/api/messages';
  static const String conversationsUnreadCount = '$messagingBaseUrl/api/conversations/unread/count';
  
  // WebSocket Events
  static const String wsAuthenticate = 'authenticate';
  static const String wsJoinConversation = 'join_conversation';
  static const String wsSendMessage = 'send_message';
  static const String wsTyping = 'typing';
  static const String wsMarkRead = 'mark_read';
  static const String wsPresenceUpdate = 'presence_update';
  
  // WebSocket Listeners
  static const String wsMessageReceived = 'message_received';
  static const String wsMessageSent = 'message_sent';
  static const String wsUserTyping = 'user_typing';
  static const String wsMessageRead = 'message_read';
  static const String wsUserPresence = 'user_presence';
  static const String wsConversationUpdated = 'conversation_updated';
  static const String wsError = 'error';
  
  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration wsReconnectDelay = Duration(seconds: 3);
  static const int wsMaxReconnectAttempts = 5;
}

