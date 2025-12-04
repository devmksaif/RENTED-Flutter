import 'user_model.dart';

class ChatMessage {
  final String id;
  final String text;
  final DateTime time;
  final bool isOwn;

  ChatMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.isOwn,
  });
}

class Chat {
  final String id;
  final User user;
  final String lastMessage;
  final DateTime time;
  final bool unread;
  final List<ChatMessage> messages;

  Chat({
    required this.id,
    required this.user,
    required this.lastMessage,
    required this.time,
    required this.unread,
    this.messages = const [],
  });
}
