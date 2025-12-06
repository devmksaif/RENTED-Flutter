import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/conversation_service.dart';
import '../models/api_error.dart';
import '../widgets/avatar_image.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ConversationService _conversationService = ConversationService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _loadUnreadCount();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conversations = await _conversationService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _conversationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      // Silently fail for unread count
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(fontSize: responsive.fontSize(20)),
        ),
        actions: [
          IconButton(
            icon: _unreadCount > 0
                ? Badge(
                    label: Text(
                      '$_unreadCount',
                      style: TextStyle(fontSize: responsive.fontSize(12)),
                    ),
                    child: Icon(Icons.notifications, size: responsive.iconSize(24)),
                  )
                : Icon(Icons.notifications, size: responsive.iconSize(24)),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Padding(
                    padding: responsive.responsivePadding(mobile: 24, tablet: 32, desktop: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: responsive.iconSize(64),
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: responsive.fontSize(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadConversations();
                    await _loadUnreadCount();
                  },
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      final otherUser = conversation['other_user'] ?? {};
                      final lastMessage = conversation['last_message'];
                      final hasUnread = lastMessage != null &&
                          lastMessage['sender_id'] !=
                              (conversation['current_user_id'] ?? 0) &&
                          !(lastMessage['is_read'] ?? false);

                      return ListTile(
                        leading: AvatarImage(
                          imageUrl: otherUser['avatar_url'],
                          name: otherUser['name'] ?? 'Unknown User',
                          radius: responsive.responsive(mobile: 25, tablet: 30, desktop: 35),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                        title: Text(
                          otherUser['name'] ?? 'Unknown User',
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            fontSize: responsive.fontSize(16),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (conversation['product'] != null)
                              Text(
                                conversation['product']['title'] ?? '',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12),
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (lastMessage != null)
                              Text(
                                lastMessage['content'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: hasUnread
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  fontSize: responsive.fontSize(14),
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (lastMessage != null)
                              Text(
                                _formatTime(lastMessage['created_at']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (hasUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: conversation['id'],
                          ).then((_) {
                            _loadConversations();
                            _loadUnreadCount();
                          });
                        },
                      );
                    },
                  ),
                ),
    );
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}

