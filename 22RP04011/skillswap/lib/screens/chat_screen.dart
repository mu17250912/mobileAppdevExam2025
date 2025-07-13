import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session_model.dart';
import '../services/app_service.dart';
import 'schedule_session_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? initialMessage;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  String? _typingUser;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }
    _setupTypingListener();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      // Mark all messages from this user as read
      final querySnapshot = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: widget.receiverId)
          .where('receiverId', isEqualTo: _auth.currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  void _setupTypingListener() {
    // Listen for typing indicators
    _firestore
        .collection('typing')
        .doc('${widget.receiverId}_${_auth.currentUser!.uid}')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data();
        if (data != null && data['isTyping'] == true) {
          setState(() {
            _isTyping = true;
            _typingUser = data['userName'];
          });
        } else {
          setState(() {
            _isTyping = false;
            _typingUser = null;
          });
        }
      }
    });
  }

  void _updateTypingStatus(bool isTyping) {
    _firestore
        .collection('typing')
        .doc('${_auth.currentUser!.uid}_${widget.receiverId}')
        .set({
      'isTyping': isTyping,
      'userId': _auth.currentUser!.uid,
      'userName': _auth.currentUser!.displayName ?? 'User',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();
    _updateTypingStatus(false);

    try {
      await _firestore.collection('messages').add({
        'senderId': _auth.currentUser!.uid,
        'receiverId': widget.receiverId,
        'content': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'text',
      });

      // Send notification to receiver
      await _sendNotification(message);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendNotification(String message) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('notifications').add({
        'userId': widget.receiverId,
        'title': 'New Message',
        'message': '${currentUser.displayName ?? 'Someone'} sent you a message',
        'type': 'message',
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'User',
        'senderPhotoUrl': currentUser.photoURL,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'chatId': '${currentUser.uid}_${widget.receiverId}',
          'message': message,
        },
      });
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }

  Future<void> _requestSession() async {
    try {
      // Navigate to schedule session screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ScheduleSessionScreen(),
        ),
      );

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            if (_isTyping)
              Text(
                '$_typingUser is typing...',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: _requestSession,
            tooltip: 'Request Session',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .where('senderId',
                      whereIn: [_auth.currentUser!.uid, widget.receiverId])
                  .where('receiverId',
                      whereIn: [_auth.currentUser!.uid, widget.receiverId])
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                List<Widget> messageWidgets = [];

                for (var message in messages) {
                  final messageData = message.data() as Map<String, dynamic>;
                  final messageText = messageData['content'] ?? '';
                  final messageSender = messageData['senderId'] ?? '';
                  final timestamp = messageData['timestamp'] as Timestamp?;
                  final isRead = messageData['isRead'] ?? false;
                  final isMe = messageSender == _auth.currentUser!.uid;

                  final messageWidget = MessageBubble(
                    text: messageText,
                    isMe: isMe,
                    timestamp: timestamp?.toDate(),
                    isRead: isRead,
                  );
                  messageWidgets.add(messageWidget);
                }

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: messageWidgets,
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                _updateTypingStatus(value.isNotEmpty);
              },
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _updateTypingStatus(false);
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? timestamp;
  final bool isRead;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.timestamp,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue[600] : Colors.grey[200],
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomLeft:
                  isMe ? const Radius.circular(20) : const Radius.circular(5),
              bottomRight:
                  isMe ? const Radius.circular(5) : const Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timestamp != null)
                    Text(
                      _formatTime(timestamp!),
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: isRead ? Colors.blue[200] : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
