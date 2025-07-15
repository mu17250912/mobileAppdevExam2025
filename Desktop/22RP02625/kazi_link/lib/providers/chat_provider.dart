import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_provider.dart';

class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;

  ChatMessage({required this.sender, required this.text, required this.timestamp});
}

class ChatProvider extends ChangeNotifier {
  final Map<String, List<ChatMessage>> _chats = {};

  List<ChatMessage> getMessagesForJob(String jobId) => _chats[jobId] ?? [];

  void sendMessage(BuildContext context, String jobId, String sender, String text) {
    final message = ChatMessage(sender: sender, text: text, timestamp: DateTime.now());
    _chats.putIfAbsent(jobId, () => []).add(message);
    notifyListeners();
    // Trigger notification for recipient
    final recipient = sender == 'me' ? 'client' : 'me';
    Provider.of<NotificationProvider>(context, listen: false).addNotification(
      NotificationItem(
        id: '',
        icon: Icons.message,
        title: 'New Message',
        message: 'You have a new message from $sender.',
        time: 'Just now',
      ),
    );
  }
} 