import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/conversation_service.dart';
import '../services/message_service.dart';
import '../services/websocket_service.dart';
import '../services/offer_service.dart';
import '../models/api_error.dart';
import '../config/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ConversationService _conversationService = ConversationService();
  final MessageService _messageService = MessageService();
  final OfferService _offerService = OfferService();
  final WebSocketService _wsService = WebSocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  Map<String, dynamic>? _conversation;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _setupWebSocket();
    _loadConversation();
    _loadMessages();
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _wsService.disconnect();
    super.dispose();
  }

  void _setupWebSocket() {
    // Set up WebSocket callbacks
    _wsService.onMessageReceived = (data) {
      if (mounted && data['conversation_id'] == widget.conversationId) {
        setState(() {
          _messages.insert(0, data['message']);
        });
        _scrollToBottom();
      }
    };

    _wsService.onUserTyping = (data) {
      if (mounted && data['conversation_id'] == widget.conversationId) {
        setState(() {
          _otherUserTyping = data['is_typing'] ?? false;
        });
      }
    };

    _wsService.onMessageRead = (data) {
      if (mounted && data['conversation_id'] == widget.conversationId) {
        // Update read status for messages
        setState(() {
          for (var messageId in data['message_ids'] ?? []) {
            final index = _messages.indexWhere((m) => m['id'] == messageId);
            if (index != -1) {
              _messages[index]['is_read'] = true;
              _messages[index]['read_at'] = DateTime.now().toIso8601String();
            }
          }
        });
      }
    };

    _wsService.onError = (error) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Connection error: $error',
          backgroundColor: Colors.orange,
        );
      }
    };

    // Connect and join conversation
    _wsService.connect().then((_) {
      _wsService.joinConversation(widget.conversationId);
      _wsService.updatePresence('online');
    });
  }

  void _onMessageChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      setState(() {
        _isTyping = true;
      });
      _wsService.sendTyping(widget.conversationId, true);
      
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
          _wsService.sendTyping(widget.conversationId, false);
        }
      });
    }
  }

  Future<void> _loadConversation() async {
    try {
      final conversation = await _conversationService.getConversation(
        widget.conversationId,
      );
      if (mounted) {
        setState(() {
          _conversation = conversation;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _conversationService.getConversationMessages(
        widget.conversationId,
      );
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        // Mark as read
        await _conversationService.markConversationAsRead(widget.conversationId);
        // Scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();
    _typingTimer?.cancel();
    _isTyping = false;
    _wsService.sendTyping(widget.conversationId, false);

    setState(() {
      _isSending = true;
    });

    try {
      // Try WebSocket first if connected, otherwise fallback to REST
      if (_wsService.isConnected) {
        _wsService.sendMessage(
          conversationId: widget.conversationId,
          content: content,
        );
        setState(() {
          _isSending = false;
        });
      } else {
        await _messageService.sendMessage(
          conversationId: widget.conversationId,
          content: content,
        );
        if (mounted) {
          setState(() {
            _isSending = false;
          });
          await _loadMessages();
        }
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = _conversation?['other_user'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              backgroundImage: otherUser['avatar_url'] != null
                  ? NetworkImage(otherUser['avatar_url'])
                  : null,
              child: otherUser['avatar_url'] == null
                  ? Text(
                      (otherUser['name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherUser['name'] ?? 'Unknown User'),
                  if (_conversation?['product'] != null)
                    Text(
                      _conversation!['product']['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Product card at top (Fiverr style)
          if (_conversation?['product'] != null) _buildProductCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              reverse: true,
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                          final message = _messages[_messages.length - 1 - index];
                          final isMe = message['sender']?['id'] ==
                              (_conversation?['current_user_id'] ?? 0);

                          // Check if message has an offer
                          if (message['offer'] != null) {
                            return _buildOfferMessage(message, isMe);
                          }

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppTheme.primaryGreen
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['content'] ?? '',
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(message['created_at']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                              },
                            ),
                          ),
                          // Typing indicator
                          if (_otherUserTyping)
                            Container(
                              padding: const EdgeInsets.all(8),
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Typing...',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        color: AppTheme.primaryGreen,
                      ),
                    ],
                  ),
                  // Make Offer button
                  if (_conversation?['product'] != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showMakeOfferDialog(),
                        icon: const Icon(Icons.local_offer, size: 18),
                        label: const Text('Make an Offer'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildProductCard() {
    final product = _conversation!['product'];
    final productImages = product['images'] as List<dynamic>?;
    final firstImage = productImages != null && productImages.isNotEmpty
        ? productImages[0]['url'] ?? productImages[0]
        : null;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: product['id'],
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: firstImage != null
                    ? Image.network(
                        firstImage.toString(),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['title'] ?? 'Product',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product['price_per_day']?.toString() ?? '0'}/day',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferMessage(Map<String, dynamic> message, bool isMe) {
    final offer = message['offer'] as Map<String, dynamic>;
    final offerStatus = offer['status'] ?? 'pending'; // pending, accepted, rejected
    final offerType = offer['offer_type'] ?? 'rental'; // rental or purchase
    final canRespond = !isMe && offerStatus == 'pending';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Card(
          elevation: 2,
          color: isMe ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: offerStatus == 'accepted'
                  ? Colors.green
                  : offerStatus == 'rejected'
                      ? Colors.red
                      : AppTheme.primaryGreen,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Offer header
                Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      offerType == 'rental' ? 'Rental Offer' : 'Purchase Offer',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (offerStatus == 'accepted')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Accepted',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (offerStatus == 'rejected')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Rejected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Offer amount
                Text(
                  'Offer Amount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${offer['amount']?.toString() ?? '0'}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                // Rental dates if applicable
                if (offerType == 'rental' && offer['start_date'] != null && offer['end_date'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${offer['start_date']} - ${offer['end_date']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                // Offer message
                if (offer['message'] != null && offer['message'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    offer['message'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                // Action buttons
                if (canRespond) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleRejectOffer(offer['id']),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleAcceptOffer(offer['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatTime(message['created_at']),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMakeOfferDialog() {
    final product = _conversation?['product'];
    if (product == null) return;

    final amountController = TextEditingController();
    final messageController = TextEditingController();
    String offerType = 'rental'; // Default to rental
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Make an Offer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Offer type selection
                const Text('Offer Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Rental'),
                        selected: offerType == 'rental',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              offerType = 'rental';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Purchase'),
                        selected: offerType == 'purchase',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              offerType = 'purchase';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Amount
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Offer Amount (\$)',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                // Rental dates
                if (offerType == 'rental') ...[
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(
                      startDate != null
                          ? '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'
                          : 'Select start date',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startDate = picked;
                          if (endDate != null && endDate!.isBefore(picked)) {
                            endDate = null;
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(
                      endDate != null
                          ? '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'
                          : 'Select end date',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          endDate = picked;
                        });
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                // Message
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Add a message to your offer...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty) {
                  Fluttertoast.showToast(
                    msg: 'Please enter an offer amount',
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  Fluttertoast.showToast(
                    msg: 'Please enter a valid amount',
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                if (offerType == 'rental' && (startDate == null || endDate == null)) {
                  Fluttertoast.showToast(
                    msg: 'Please select rental dates',
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  await _offerService.createOffer(
                    conversationId: widget.conversationId,
                    amount: amount,
                    message: messageController.text.trim().isEmpty
                        ? null
                        : messageController.text.trim(),
                    offerType: offerType,
                    startDate: startDate != null
                        ? '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'
                        : null,
                    endDate: endDate != null
                        ? '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'
                        : null,
                  );

                  if (mounted) {
                    Fluttertoast.showToast(
                      msg: 'Offer sent successfully',
                      backgroundColor: Colors.green,
                    );
                    await _loadMessages();
                  }
                } on ApiError catch (e) {
                  Fluttertoast.showToast(
                    msg: e.message,
                    backgroundColor: Colors.red,
                  );
                }
              },
              child: const Text('Send Offer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAcceptOffer(int offerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Offer'),
        content: const Text('Are you sure you want to accept this offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _offerService.acceptOffer(
          conversationId: widget.conversationId,
          offerId: offerId,
        );

        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Offer accepted successfully',
            backgroundColor: Colors.green,
          );
          await _loadMessages();
        }
      } on ApiError catch (e) {
        Fluttertoast.showToast(
          msg: e.message,
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _handleRejectOffer(int offerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Offer'),
        content: const Text('Are you sure you want to reject this offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _offerService.rejectOffer(
          conversationId: widget.conversationId,
          offerId: offerId,
        );

        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Offer rejected',
            backgroundColor: Colors.orange,
          );
          await _loadMessages();
        }
      } on ApiError catch (e) {
        Fluttertoast.showToast(
          msg: e.message,
          backgroundColor: Colors.red,
        );
      }
    }
  }
}

