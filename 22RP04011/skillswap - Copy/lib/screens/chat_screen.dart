import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/typing_service.dart';
import '../widgets/typing_indicators.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    required this.receiverId,
    required this.receiverName,
    super.key,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  ChatMode _currentMode = ChatMode.quick;
  bool _isEncrypted = false;
  String? _replyToMessageId;
  ChatMessage? _replyToMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<ChatMessage> _searchResults = [];
  bool _otherUserTyping = false;
  bool _isUserTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    // Debug print for chat opening
    final currentUserId = _auth.currentUser?.uid ?? '';
    final chatId = _generateChatId(currentUserId, widget.receiverId);
    print(
        '[DEBUG] Opening chat: currentUserId=$currentUserId, receiverId=${widget.receiverId}, chatId=$chatId');
    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Mark messages as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
    _listenToOtherUserTyping();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _generateChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? '${user1}_$user2'
        : '${user2}_$user1';
  }

  Future<void> _sendMessageWithContext(BuildContext buttonContext) async {
    final currentUserId = _auth.currentUser?.uid ?? '';
    final chatId = _generateChatId(currentUserId, widget.receiverId);
    print(
        '[DEBUG] Sending message: currentUserId=$currentUserId, receiverId=${widget.receiverId}, chatId=$chatId');
    if (_messageController.text.trim().isEmpty) return;

    await ChatService.sendMessage(
      receiverId: widget.receiverId,
      text: _messageController.text.trim(),
      replyToMessageId: _replyToMessageId,
      isEncrypted: _isEncrypted,
    );

    _messageController.clear();
    _replyToMessageId = null;
    _replyToMessage = null;
    _scrollToBottom();

    // Show confirmation using the button's context
    if (mounted) {
      ScaffoldMessenger.of(buttonContext).showSnackBar(
        const SnackBar(
          content: Text('Message sent!'),
          duration: Duration(milliseconds: 800),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    final chatId =
        _generateChatId(_auth.currentUser?.uid ?? '', widget.receiverId);
    await ChatService.markMessagesAsRead(chatId);
  }

  Future<void> _toggleChatMode() async {
    final newMode =
        _currentMode == ChatMode.quick ? ChatMode.detailed : ChatMode.quick;
    setState(() {
      _currentMode = newMode;
    });

    final chatId =
        _generateChatId(_auth.currentUser?.uid ?? '', widget.receiverId);
    await ChatService.toggleChatMode(chatId: chatId, mode: newMode);
  }

  Future<void> _toggleEncryption() async {
    setState(() {
      _isEncrypted = !_isEncrypted;
    });
  }

  void _showReactionPicker(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Reaction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: ['👍', '❤️', '😂', '😮', '😢', '😡'].map((emoji) {
                return GestureDetector(
                  onTap: () {
                    final chatId = _generateChatId(
                        _auth.currentUser?.uid ?? '', widget.receiverId);
                    ChatService.addReaction(
                      chatId: chatId,
                      messageId: message.id,
                      reaction: emoji,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePinMessage(ChatMessage message) async {
    final chatId =
        _generateChatId(_auth.currentUser?.uid ?? '', widget.receiverId);
    await ChatService.togglePinMessage(
      chatId: chatId,
      messageId: message.id,
      isPinned: !message.isPinned,
    );
  }

  Future<void> _searchMessages() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final chatId =
        _generateChatId(_auth.currentUser?.uid ?? '', widget.receiverId);
    final results = await ChatService.searchMessages(
      chatId: chatId,
      query: _searchController.text.trim(),
    );

    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  void _listenToOtherUserTyping() {
    final chatId =
        _generateChatId(_auth.currentUser?.uid ?? '', widget.receiverId);
    TypingService.otherUserTypingStream(
      chatId: chatId,
      otherUserId: widget.receiverId,
    ).listen((isTyping) {
      if (mounted) {
        setState(() {
          _otherUserTyping = isTyping;
        });
      }
    });
  }

  void _onUserTyping(String value) {
    if (!_isUserTyping) {
      _isUserTyping = true;
      _setTypingStatus(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isUserTyping = false;
      _setTypingStatus(false);
    });
  }

  void _setTypingStatus(bool isTyping) {
    final chatId =
        _generateChatId(_auth.currentUser?.uid ?? '', widget.receiverId);
    TypingService.setTypingStatus(chatId: chatId, isTyping: isTyping);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid ?? '';
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            if (_isEncrypted)
              Text(
                'End-to-end encrypted',
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_currentMode == ChatMode.quick
                ? Icons.chat
                : Icons.description),
            onPressed: _toggleChatMode,
            tooltip:
                'Toggle ${_currentMode == ChatMode.quick ? 'Detailed' : 'Quick'} Mode',
          ),
          IconButton(
            icon: Icon(_isEncrypted ? Icons.lock : Icons.lock_open),
            onPressed: _toggleEncryption,
            tooltip: 'Toggle Encryption',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search Messages'),
                  content: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search in this chat...',
                    ),
                    onSubmitted: (_) {
                      _searchMessages();
                      Navigator.pop(context);
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _searchMessages();
                        Navigator.pop(context);
                      },
                      child: const Text('Search'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Search Messages',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_otherUserTyping)
            TypingIndicator(isTyping: true, name: widget.receiverName),
          // Reply preview
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Icon(Icons.reply, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to: ${_replyToMessage!.text}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _replyToMessage = null;
                        _replyToMessageId = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          // Search results
          if (_isSearching && _searchResults.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.yellow[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Results (${_searchResults.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._searchResults.take(3).map((message) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          message.text,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.getMessagesStream(widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('[DEBUG] Error loading messages: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: isTablet ? 80 : 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            color: Colors.red,
                          ),
                        ),
                        if (snapshot.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              snapshot.error.toString(),
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: isTablet ? 120 : 80, color: Colors.grey),
                        SizedBox(height: isTablet ? 24 : 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return _buildMessageTile(message, isMe, isTablet);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: _onUserTyping,
                    onSubmitted: (_) => _sendMessageWithContext(context),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (buttonContext) => IconButton(
                    icon: Icon(Icons.send, color: Colors.blue[800]),
                    onPressed: () => _sendMessageWithContext(buttonContext),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(ChatMessage message, bool isMe, bool isTablet) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: message.isPinned
              ? Border.all(color: Colors.amber, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply indicator
            if (message.replyToMessageId != null)
              Container(
                padding: const EdgeInsets.all(4),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '↩ Reply',
                  style: TextStyle(
                    fontSize: isTablet ? 10 : 8,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // Message text
            Text(
              message.text,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Message metadata
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(
                    fontSize: isTablet ? 10 : 8,
                    color: Colors.grey[600],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: isTablet ? 14 : 12,
                    color: message.isRead ? Colors.blue : Colors.grey,
                  ),
                ],
                if (message.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.push_pin,
                      size: isTablet ? 12 : 10,
                      color: Colors.amber,
                    ),
                  ),
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      message.reactions.values.join(' '),
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
