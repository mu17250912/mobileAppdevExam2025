import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../utils/constants.dart';
import 'chat_screen.dart';

class MessagingHomeScreen extends StatefulWidget {
  const MessagingHomeScreen({super.key});

  @override
  State<MessagingHomeScreen> createState() => _MessagingHomeScreenState();
}

class _MessagingHomeScreenState extends State<MessagingHomeScreen> {
  @override
  void initState() {
    super.initState();
    final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
    messagingProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Demo Mode',
            onPressed: () async {
              final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
              const testUserId = 'test_user_123';
              await messagingProvider.startNewChat(testUserId);
              await messagingProvider.sendMessage(
                receiverId: testUserId,
                content: 'This is a demo message!',
              );
              await messagingProvider.refresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo chat and message created!')),
                );
              }
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isAdmin) {
                return IconButton(
                  icon: const Icon(Icons.broadcast_on_personal),
                  onPressed: () {
                    _showBroadcastDialog();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
      ),
      body: Consumer<MessagingProvider>(
        builder: (context, messagingProvider, child) {
          if (messagingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (messagingProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text('Error loading messages', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red[600])),
                  const SizedBox(height: 8),
                  Text(messagingProvider.error!, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      messagingProvider.clearError();
                      messagingProvider.refresh();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (messagingProvider.chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No conversations yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Start a conversation with a service provider', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await messagingProvider.refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messagingProvider.chats.length,
              itemBuilder: (context, index) {
                final chat = messagingProvider.chats[index];
                return _buildChatTile(chat, messagingProvider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showStartChatDialog();
        },
        child: const Icon(Icons.add),
        tooltip: 'Start New Chat',
      ),
    );
  }

  Widget _buildChatTile(ChatModel chat, MessagingProvider messagingProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;
    final otherParticipantName = messagingProvider.getOtherParticipantName(chat.id);
    final unreadCount = currentUserId != null ? (chat.unreadCounts[currentUserId] ?? 0) : 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(AppColors.primaryColor),
          child: Text(
            otherParticipantName.isNotEmpty ? otherParticipantName[0].toUpperCase() : 'U',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        title: Text(
          otherParticipantName,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              chat.lastMessage.isNotEmpty ? chat.lastMessage : 'No messages yet',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(chat.lastMessageTime),
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: unreadCount > 0
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(AppColors.primaryColor),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              )
            : null,
        onTap: () {
          Get.to(() => ChatScreen(chatId: chat.id));
        },
        onLongPress: () {
          _showChatOptions(chat, messagingProvider);
        },
      ),
    );
  }

  void _showChatOptions(ChatModel chat, MessagingProvider messagingProvider) {
    showModalBottomSheet(
      context: context,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Chat', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(modalContext);
                final success = await messagingProvider.deleteChat(chat.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat deleted successfully'), backgroundColor: Color(AppColors.successColor)),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text('Block User', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(modalContext);
                final otherParticipantId = messagingProvider.getOtherParticipantId(chat.id);
                if (otherParticipantId != null) {
                  final success = await messagingProvider.blockUser(otherParticipantId);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User blocked successfully'), backgroundColor: Color(AppColors.successColor)),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStartChatDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start New Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter user ID to chat with',
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
              final userId = textController.text.trim();
              if (userId.isNotEmpty) {
                Navigator.pop(context);
                final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
                await messagingProvider.startNewChat(userId);
                await messagingProvider.sendMessage(
                  receiverId: userId,
                  content: 'Hello from test user!',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Started chat and sent test message to $userId')),
                  );
                }
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Broadcast Message', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter your broadcast message...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
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
                final success = await messagingProvider.broadcastMessage(
                  content: textController.text.trim(),
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message broadcasted successfully'), backgroundColor: Color(AppColors.successColor)),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Messages', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
        title: Text('Search Results', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
                      subtitle: Text(_formatTimestamp(message.timestamp)),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Get.to(() => ChatScreen(chatId: message.chatId));
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