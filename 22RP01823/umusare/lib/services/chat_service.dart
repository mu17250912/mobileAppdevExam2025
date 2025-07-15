import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Get all chats for the current user
  Stream<List<Map<String, dynamic>>> getUserChats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  // Create a new chat (if not exists) and return chatId
  Future<String> createOrGetChat(String otherUserId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not logged in');
    final query = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();
    for (final doc in query.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }
    final docRef = await _firestore.collection('chats').add({
      'participants': [userId, otherUserId],
      'lastMessage': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Send a message in a chat
  Future<void> sendMessage(String chatId, String text) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not logged in');
    final message = {
      'senderId': userId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('chats').doc(chatId).collection('messages').add(message);
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // Stream messages in a chat
  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
} 