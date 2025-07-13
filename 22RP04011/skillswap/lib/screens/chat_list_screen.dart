import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text('Not logged in.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('messages')
            .where('senderId', isEqualTo: _user!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load messages',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final sentMessages = snapshot.data?.docs ?? [];

          // Get unique conversation partners
          final conversationPartners = <String>{};
          for (final doc in sentMessages) {
            final data = doc.data() as Map<String, dynamic>;
            conversationPartners.add(data['receiverId'] as String);
          }

          // Also get messages received by the user
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('messages')
                .where('receiverId', isEqualTo: _user!.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, receivedSnapshot) {
              final receivedMessages = receivedSnapshot.data?.docs ?? [];

              // Add conversation partners from received messages
              for (final doc in receivedMessages) {
                final data = doc.data() as Map<String, dynamic>;
                conversationPartners.add(data['senderId'] as String);
              }

              if (conversationPartners.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation by connecting with other users',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: conversationPartners.length,
                itemBuilder: (context, index) {
                  final partnerId = conversationPartners.elementAt(index);
                  return _buildConversationTile(
                      partnerId, sentMessages, receivedMessages);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(
      String partnerId,
      List<QueryDocumentSnapshot> sentMessages,
      List<QueryDocumentSnapshot> receivedMessages) {
    // Find the most recent message with this partner
    final allMessages = <QueryDocumentSnapshot>[];
    allMessages.addAll(sentMessages.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['receiverId'] == partnerId;
    }));
    allMessages.addAll(receivedMessages.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['senderId'] == partnerId;
    }));

    if (allMessages.isEmpty) return const SizedBox.shrink();

    // Sort by timestamp and get the most recent
    allMessages.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTimestamp = aData['timestamp'] as Timestamp?;
      final bTimestamp = bData['timestamp'] as Timestamp?;
      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;
      return bTimestamp.compareTo(aTimestamp);
    });

    final latestMessage = allMessages.first;
    final messageData = latestMessage.data() as Map<String, dynamic>;
    final content = messageData['content'] ?? '';
    final timestamp = messageData['timestamp'] as Timestamp?;
    final isFromMe = messageData['senderId'] == _user!.uid;
    final isRead = messageData['isRead'] ?? false;

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(partnerId).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const ListTile(
            leading: CircleAvatar(child: CircularProgressIndicator()),
            title: Text('Loading...'),
          );
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        final name = userData?['fullName'] ?? 'User';
        final photoUrl = userData?['photoUrl'] as String?;
        final isOnline = userData?['isOnline'] ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 1,
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (timestamp != null)
                  Text(
                    _formatTime(timestamp.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isFromMe)
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 16,
                        color: isRead ? Colors.blue : Colors.grey,
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    receiverId: partnerId,
                    receiverName: name,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
