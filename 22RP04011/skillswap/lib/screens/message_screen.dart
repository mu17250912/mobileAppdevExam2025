import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillswap/screens/chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('receiverId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Group messages by sender
          final messages = snapshot.data!.docs;
          final senders = <String, QueryDocumentSnapshot>{};

          for (var message in messages) {
            final senderId = message['senderId'];
            if (!senders.containsKey(senderId)) {
              senders[senderId] = message;
            }
          }

          return ListView.builder(
            itemCount: senders.length,
            itemBuilder: (context, index) {
              final senderId = senders.keys.elementAt(index);
              final lastMessage = senders[senderId]!;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(senderId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = userData['name'] ?? 'Unknown User';
                  final userAvatar = userData['photoUrl'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userAvatar.isNotEmpty
                          ? NetworkImage(userAvatar)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                    title: Text(userName),
                    subtitle: Text(
                      lastMessage['content'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatTimestamp(lastMessage['timestamp']),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverId: senderId,
                            receiverName: userName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
