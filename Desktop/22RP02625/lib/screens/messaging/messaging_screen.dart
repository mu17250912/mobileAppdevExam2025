import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('userIds', arrayContains: user.uid)
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!.docs;
          if (chats.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;
              final otherUserId = (data['userIds'] as List).firstWhere((id) => id != user.uid);
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnap) {
                  final userData = userSnap.data?.data() as Map<String, dynamic>?;
                  final unreadCount = data['unreadCount_${user.uid}'] ?? 0;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData != null && userData['photoUrl'] != null && userData['photoUrl'].isNotEmpty
                          ? NetworkImage(userData['photoUrl'])
                          : null,
                      child: userData == null || userData['photoUrl'] == null || userData['photoUrl'].isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(userData?['displayName'] ?? 'User'),
                    subtitle: Text(data['lastMessage'] ?? ''),
                    trailing: unreadCount > 0
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        : null,
                    onTap: () async {
                      // Mark messages as read
                      await FirebaseFirestore.instance.collection('chats').doc(chat.id).update({
                        'unreadCount_${user.uid}': 0,
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailsScreen(chatId: chat.id, otherUserId: otherUserId),
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
}

class ChatDetailsScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  const ChatDetailsScreen({super.key, required this.chatId, required this.otherUserId});

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  bool _isTyping = false;
  @override
  void initState() {
    super.initState();
    _listenToTyping();
  }
  void _listenToTyping() {
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots().listen((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['typing_${widget.otherUserId}'] == true) {
        setState(() => _isTyping = true);
      } else {
        setState(() => _isTyping = false);
      }
    });
  }
  void _setTyping(bool typing) {
    if (user == null) return;
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'typing_${user!.uid}': typing,
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || user == null) return;
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc();
    await messageRef.set({
      'senderId': user.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    final recipientId = widget.otherUserId;
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount_$recipientId': FieldValue.increment(1),
    });
    _controller.clear();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null || user == null) return;
    final ref = FirebaseStorage.instance.ref().child('chat_images/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putData(await picked.readAsBytes());
    final url = await ref.getDownloadURL();
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc();
    await messageRef.set({
      'senderId': user.uid,
      'imageUrl': url,
      'timestamp': FieldValue.serverTimestamp(),
    });
    final recipientId = widget.otherUserId;
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastMessage': '[Image]',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount_$recipientId': FieldValue.increment(1),
    });
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || user == null) return;
    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    final ref = FirebaseStorage.instance.ref().child('chat_files/${widget.chatId}/$fileName');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc();
    await messageRef.set({
      'senderId': user.uid,
      'fileUrl': url,
      'fileName': fileName,
      'timestamp': FieldValue.serverTimestamp(),
    });
    final recipientId = widget.otherUserId;
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastMessage': '[File]',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount_$recipientId': FieldValue.increment(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == user?.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () async {
                          final reaction = await showModalBottomSheet<String>(
                            context: context,
                            builder: (context) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(icon: const Icon(Icons.thumb_up), onPressed: () => Navigator.pop(context, 'like')),
                                IconButton(icon: const Icon(Icons.favorite), onPressed: () => Navigator.pop(context, 'love')),
                                IconButton(icon: const Icon(Icons.emoji_emotions), onPressed: () => Navigator.pop(context, 'smile')),
                              ],
                            ),
                          );
                          if (reaction != null) {
                            await FirebaseFirestore.instance
                                .collection('chats')
                                .doc(widget.chatId)
                                .collection('messages')
                                .doc(messages[index].id)
                                .update({'reaction': reaction});
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (msg['imageUrl'] != null)
                                Image.network(msg['imageUrl']!, width: 180, height: 180, fit: BoxFit.cover),
                              if (msg['fileUrl'] != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.insert_drive_file, size: 32),
                                    GestureDetector(
                                      onTap: () async {
                                        final url = msg['fileUrl'];
                                        if (await canLaunchUrl(Uri.parse(url))) {
                                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      child: Text(msg['fileName'] ?? 'File', style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                    ),
                                  ],
                                ),
                              if (msg['text'] != null)
                                Text(msg['text'] ?? ''),
                              if (msg['reaction'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text('Reaction: ${msg['reaction']}', style: const TextStyle(fontSize: 12, color: Colors.purple)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('User is typing...', style: TextStyle(color: Colors.grey)),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                    onChanged: (v) => _setTyping(v.isNotEmpty),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _sendImage,
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _sendFile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    if (user != null) {
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'typing_${user!.uid}': false,
      });
    }
    super.dispose();
  }
} 