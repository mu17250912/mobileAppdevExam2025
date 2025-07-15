import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String gigId;
  late String posterId;
  late String gigTitle;
  late String currentUserId;
  late String applicantId;
  final TextEditingController _controller = TextEditingController();

  // Add a field to mark messages as read
  Future<void> _markMessagesAsRead() async {
    final messages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(gigId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in messages.docs) {
      await doc.reference.update({'read': true});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    gigId = args?['gigId']?.toString() ?? '';
    posterId = args?['posterId']?.toString() ?? '';
    gigTitle = args?['gigTitle']?.toString() ?? '';
    applicantId = args?['applicantId']?.toString() ?? '';
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Mark messages as read when chat is opened
    if (gigId.isNotEmpty) {
      _markMessagesAsRead();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _chatStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(gigId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(gigId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
    _controller.clear();

    // Determine recipient
    final recipientId = currentUserId == posterId ? applicantId : posterId;
    if (recipientId.isNotEmpty && recipientId != currentUserId) {
      // Save notification to recipient
      await FirebaseFirestore.instance.collection('users').doc(recipientId).collection('notifications').add({
        'title': 'New Message',
        'body': 'You have a new message about gig: $gigTitle',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      // (Optional) Send push notification if FCM token is available
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(recipientId).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken != null) {
        // You would use your backend or Firebase Cloud Functions to send the push notification
        // This is a placeholder for push notification logic
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (gigId.isEmpty || posterId.isEmpty || gigTitle.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Error: Missing chat information.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Chat: $gigTitle')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data();
                    final isMe = msg['senderId'] == currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.deepPurple[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe && msg['senderName'] != null)
                              Text(msg['senderName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(msg['text'] ?? '', style: const TextStyle(fontSize: 16)),
                            if (msg['timestamp'] != null)
                              Text(
                                (msg['timestamp'] as Timestamp).toDate().toString().split('.').first,
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    );
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
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 