import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saferide/services/auth_service.dart';
import 'package:saferide/services/error_service.dart';
import 'package:saferide/models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen(
      {super.key, required this.otherUserId, required this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final ErrorService _errorService = ErrorService();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  UserModel? _currentUser;
  UserModel? _otherUser;
  bool _isLoading = true;
  String? _error;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final currentUser = await _authService.getCurrentUserModel();
      final otherUser = await _authService.getUserById(widget.otherUserId);

      if (!mounted) return;
      setState(() {
        _currentUser = currentUser;
        _otherUser = otherUser;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load users';
        _isLoading = false;
      });
    }
  }

  String get _chatId {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return '';

    // Create a consistent chat ID by sorting user IDs
    final users = [currentUserId, widget.otherUserId]..sort();
    return '${users[0]}_${users[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: _otherUser?.profileImage != null
                  ? ClipOval(
                      child: Image.network(
                        _otherUser!.profileImage!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.deepPurple.shade700,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 18,
                      color: Colors.deepPurple.shade700,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_otherUser != null) ...[
                    Text(
                      _otherUser!.isDriver ? 'Driver' : 'Passenger',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha((0.8 * 255).toInt()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _makeCall,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    Expanded(
                      child: _buildChatMessages(),
                    ),
                    _buildMessageInput(),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadUsers();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading messages: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index].data() as Map<String, dynamic>;
            final isMe = message['senderId'] == _auth.currentUser?.uid;

            return _buildMessageBubble(message, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final timestamp = (message['timestamp'] as Timestamp).toDate();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: _otherUser?.profileImage != null
                  ? ClipOval(
                      child: Image.network(
                        _otherUser!.profileImage!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey.shade600,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.deepPurple : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withAlpha((0.7 * 255).toInt())
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple.shade100,
              child: _currentUser?.profileImage != null
                  ? ClipOval(
                      child: Image.network(
                        _currentUser!.profileImage!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.deepPurple.shade700,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.deepPurple.shade700,
                    ),
            ),
          ],
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
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
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
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final message = {
        'text': text,
        'senderId': currentUser.uid,
        'senderName': _currentUser?.name ?? 'User',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Add message to chat
      await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add(message);

      // Update chat metadata
      await _firestore.collection('chats').doc(_chatId).set({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [currentUser.uid, widget.otherUserId],
        'participantNames': [
          _currentUser?.name ?? 'User',
          widget.otherUserName
        ],
      }, SetOptions(merge: true));

      _messageController.clear();

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      _errorService.logError('Error sending message', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _makeCall() {
    if (_otherUser?.phone != null) {
      // In a real app, you would use url_launcher to make a phone call
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calling ${_otherUser!.phone}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call'),
              onTap: () {
                Navigator.pop(context);
                _makeCall();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/driver-profile',
                  arguments: widget.otherUserId,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                _blockUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report User'),
              onTap: () {
                Navigator.pop(context);
                _reportUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content:
            Text('Are you sure you want to block ${widget.otherUserName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement block user functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${widget.otherUserName} has been blocked')),
              );
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _reportUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text('Are you sure you want to report this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement report user functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User has been reported')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
