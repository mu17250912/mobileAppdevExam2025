import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TypingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _typingDocId(String chatId, String userId) =>
      '${chatId}_$userId';

  // Set typing status for the current user in a chat
  static Future<void> setTypingStatus({
    required String chatId,
    required bool isTyping,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('typing')
        .doc(_typingDocId(chatId, user.uid))
        .set({
      'chatId': chatId,
      'userId': user.uid,
      'isTyping': isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Listen to typing status of the other user in a chat
  static Stream<bool> otherUserTypingStream({
    required String chatId,
    required String otherUserId,
  }) {
    return _firestore
        .collection('typing')
        .doc(_typingDocId(chatId, otherUserId))
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>?;
      return data?['isTyping'] == true;
    });
  }
}
