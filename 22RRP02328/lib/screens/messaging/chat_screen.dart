import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/messaging_provider.dart';
import '../../models/message_model.dart';
import '../../utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
    messagingProvider.loadChatMessages(widget.chatId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<MessagingProvider>(
          builder: (context, messagingProvider, child) {
            final otherParticipantName = messagingProvider.getOtherParticipantName(widget.chatId);
            return Text(otherParticipantName);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessagingProvider>(
              builder: (context, messagingProvider, child) {
                if (messagingProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (messagingProvider.error != null) {
                  return Center(child: Text('Error: ' + messagingProvider.error!));
                }
                if (messagingProvider.currentChatMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Start the conversation!', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messagingProvider.currentChatMessages.length,
                  itemBuilder: (context, index) {
                    final message = messagingProvider.currentChatMessages[index];
                    return GestureDetector(
                      onLongPress: () => _showMessageOptions(message, messagingProvider),
                      child: _buildMessageTile(message, messagingProvider),
                    );
                  },
                );
              },
            ),
          ),
          Consumer<MessagingProvider>(
            builder: (context, messagingProvider, child) {
              final isTyping = messagingProvider.typingUsers[widget.chatId] ?? false;
              if (!isTyping) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        messagingProvider.getOtherParticipantName(widget.chatId)[0].toUpperCase(),
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${messagingProvider.getOtherParticipantName(widget.chatId)} is typing...', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      setState(() {
                        _isTyping = text.isNotEmpty;
                      });
                      final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
                      if (_isTyping) {
                        messagingProvider.startTyping(widget.chatId);
                      } else {
                        messagingProvider.stopTyping(widget.chatId);
                      }
                    },
                    onSubmitted: (_) {
                      final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
                      _sendMessage(messagingProvider);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
                    _sendMessage(messagingProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickAttachment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(MessageModel message, MessagingProvider messagingProvider) {
    final isCurrentUser = message.senderId == messagingProvider.currentUserId;
    final otherParticipantName = messagingProvider.getOtherParticipantName(widget.chatId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(AppColors.primaryColor),
              child: Text(
                otherParticipantName.isNotEmpty ? otherParticipantName[0].toUpperCase() : 'U',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? const Color(AppColors.primaryColor)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.attachmentUrl != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          message.attachmentUrl!,
                          width: 200,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  Text(
                    message.content,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isCurrentUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isCurrentUser 
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey[600],
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readBy.length > 1 ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.readBy.length > 1 
                              ? Colors.blue[200]
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(AppColors.primaryColor),
              child: Text(
                'M',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: () {
              setState(() {
                _showEmojiPicker = !_showEmojiPicker;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
                final otherUserId = messagingProvider.getOtherParticipantId(widget.chatId);
                if (otherUserId != null) {
                  await messagingProvider.sendMessage(
                    receiverId: otherUserId,
                    content: '[Image]',
                    messageType: 'image',
                    mediaUrl: pickedFile.path, // In production, upload to storage and use URL
                  );
                }
              }
            },
          ),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) {
                _handleTyping();
              },
            ),
          ),
          const SizedBox(width: 8),
          Consumer<MessagingProvider>(
            builder: (context, messagingProvider, child) {
              return IconButton(
                icon: messagingProvider.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                onPressed: messagingProvider.isLoading || _messageController.text.trim().isEmpty
                    ? null
                    : () => _sendMessage(messagingProvider),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleTyping() {
    if (!_isTyping) {
      _isTyping = true;
      final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
      messagingProvider.startTyping(widget.chatId);
    }
    
    // Reset typing timer
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isTyping) {
        _isTyping = false;
        final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
        messagingProvider.stopTyping(widget.chatId);
      }
    });
  }

  Future<void> _sendMessage(MessagingProvider messagingProvider) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final otherUserId = messagingProvider.getOtherParticipantId(widget.chatId);
    if (otherUserId == null) return;

    final success = await messagingProvider.sendMessage(
      receiverId: otherUserId,
      content: message,
    );

    if (success) {
      _messageController.clear();
      _scrollToBottom();
      _isTyping = false;
      messagingProvider.stopTyping(widget.chatId);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Color(AppColors.errorColor),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _pickAttachment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // TODO: Upload and send image as message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Picked image: ${pickedFile.path}')),
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: Text('Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  // TODO: Upload and send image as message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Picked image: ${pickedFile.path}')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('Camera', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  // TODO: Upload and send image as message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Captured image: ${pickedFile.path}')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text('Location', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                // For now, just show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location sharing coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(
                'Search Messages',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSearchDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(
                'Block User',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                Navigator.pop(context);
                final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
                final otherUserId = messagingProvider.getOtherParticipantId(widget.chatId);
                if (otherUserId != null) {
                  final success = await messagingProvider.blockUser(otherUserId);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User blocked successfully'),
                        backgroundColor: Color(AppColors.successColor),
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: Text(
                'Report User',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReportUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Messages',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
                final results = await messagingProvider.searchMessages(textController.text.trim());
                if (mounted) {
                  _showSearchResults(results);
                }
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(List<MessageModel> results) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Search Results',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: results.isEmpty
              ? const Center(child: Text('No messages found'))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final message = results[index];
                    return ListTile(
                      title: Text(message.content),
                      subtitle: Text(_formatTime(message.timestamp)),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        // Navigate to the specific message in the chat
                        // This would require scrolling to the message
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _showMessageOptions(MessageModel message, MessagingProvider messagingProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Message'),
            onTap: () async {
              Navigator.pop(context);
              await messagingProvider.deleteMessage(message.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Block User'),
            onTap: () async {
              Navigator.pop(context);
              await messagingProvider.blockUser(message.senderId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.report, color: Colors.red),
            title: const Text('Report User'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report feature coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showReportUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text('Reporting feature coming soon!'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
} 