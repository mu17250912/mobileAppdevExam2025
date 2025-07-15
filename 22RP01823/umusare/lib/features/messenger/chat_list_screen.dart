import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import 'chat_detail_screen.dart';
import '../../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF145A32),
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ChatService().getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF145A32)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading chats', style: TextStyle(color: Colors.red)));
          }
          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline, color: Color(0xFF145A32), size: 54),
                          const SizedBox(height: 18),
                          const Text(
                            'No chats yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF145A32),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation with a seller or support. Your chats will appear here.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final chat = chats[i];
              final participants = List<String>.from(chat['participants'] ?? []);
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchUserInfo(otherUserId),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF145A32),
                        backgroundImage: user != null && user['avatarUrl'] != null && user['avatarUrl'] != ''
                            ? NetworkImage(user['avatarUrl'])
                            : null,
                        child: user == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : Text(user['name'] != null && user['name'].isNotEmpty ? user['name'][0].toUpperCase() : '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(
                        user != null && user['name'] != null ? user['name'] : 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        chat['lastMessage'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: chat['lastTimestamp'] != null
                          ? Text(
                              _formatTimestamp(chat['lastTimestamp']),
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              chatId: chat['id'],
                              participants: chat['participants'] ?? [],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

String _formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    final dt = timestamp.toDate();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  return '';
}

Future<Map<String, dynamic>?> _fetchUserInfo(String userId) async {
  if (userId.isEmpty) return null;
  // Simulate fetching user info from Firestore 'users' collection
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return doc.exists ? doc.data() : null;
} 