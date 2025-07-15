import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  final String userEmail;
  final String userRole;
  final String otherUserEmail;
  final String otherUserName;
  
  const ChatScreen({
    Key? key, 
    required this.userEmail, 
    required this.userRole,
    required this.otherUserEmail,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      // Get chat ID (combination of both user emails, sorted)
      final chatId = _getChatId();
      
      final query = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();
      
      setState(() {
        messages = query.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        isLoading = false;
      });

      // Scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getChatId() {
    final emails = [widget.userEmail, widget.otherUserEmail];
    emails.sort();
    return '${emails[0]}_${emails[1]}';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final chatId = _getChatId();
      final message = _messageController.text.trim();
      
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderEmail': widget.userEmail,
        'senderName': widget.userEmail.split('@')[0],
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update chat metadata
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'participants': [widget.userEmail, widget.otherUserEmail],
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSender': widget.userEmail,
      }, SetOptions(merge: true));

      _messageController.clear();
      _loadMessages(); // Refresh messages
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  bool _isOwnMessage(String senderEmail) {
    return senderEmail == widget.userEmail;
  }

  // Add this function to delete a message for both users
  Future<void> _deleteMessageForBoth(String messageId) async {
    final chatId = _getChatId();
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'deletedFor': [widget.userEmail, widget.otherUserEmail],
      });
      _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  // Add this function to edit a message (for sender only)
  Future<void> _editMessage(String messageId, String oldText) async {
    final chatId = _getChatId();
    final TextEditingController editController = TextEditingController(text: oldText);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: editController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Edit your message'),
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(editController.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty && result != oldText) {
      try {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .update({
          'message': result,
          'edited': true,
        });
        _loadMessages();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error editing message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.otherUserEmail,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isOwn = _isOwnMessage(message['senderEmail']);
        // Filter out messages deleted for this user
        if (message['deletedFor'] != null && (message['deletedFor'] as List).contains(widget.userEmail)) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isOwn) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  child: Text(
                    message['senderName']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isOwn 
                            ? (widget.userRole == 'trainer' ? Colors.green : Colors.blue)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isOwn)
                            Text(
                              message['senderName'] ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          if (!isOwn) const SizedBox(height: 4),
                          Text(
                            message['message'] ?? '',
                            style: GoogleFonts.poppins(
                              color: isOwn ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (message['edited'] == true)
                            Text(
                              'edited',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: isOwn ? Colors.white70 : Colors.grey[500],
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _formatMessageTime(message['timestamp']),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: isOwn ? Colors.white70 : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwn)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteMessageForBoth(message['id']);
                            } else if (value == 'edit') {
                              _editMessage(message['id'], message['message'] ?? '');
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete for both'),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert, size: 18, color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
              if (isOwn) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: (widget.userRole == 'trainer' ? Colors.green : Colors.blue).withOpacity(0.2),
                  child: Text(
                    message['senderName']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
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
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
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

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inHours > 0) {
        return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
} 