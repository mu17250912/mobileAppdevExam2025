import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/chat_conversation_model.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get conversation ID for two users
  String _getConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Send a message
  Future<Message> sendMessage({
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    List<String>? attachments,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final conversationId = _getConversationId(currentUser.uid, receiverId);
    final now = DateTime.now();

    // Create the message
    final message = Message(
      id: '', // Will be set by Firestore
      senderId: currentUser.uid,
      receiverId: receiverId,
      content: content,
      type: type,
      status: MessageStatus.sent,
      timestamp: now,
      metadata: metadata,
      replyToMessageId: replyToMessageId,
      attachments: attachments,
    );

    try {
      // Add message to messages collection
      final messageDoc =
          await _firestore.collection('messages').add(message.toFirestore());

      // Update or create conversation
      await _updateConversation(conversationId, currentUser.uid, receiverId,
          messageDoc.id, content, now);

      // Mark message as delivered
      await messageDoc.update({'status': 'delivered'});

      // Send notification
      await _sendMessageNotification(receiverId, content, currentUser.uid);

      return message.copyWith(id: messageDoc.id);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Update conversation metadata
  Future<void> _updateConversation(
    String conversationId,
    String senderId,
    String receiverId,
    String messageId,
    String content,
    DateTime timestamp,
  ) async {
    final participants = [senderId, receiverId];
    final participantUnreadCounts = <String, int>{};

    // Get current conversation if it exists
    final conversationDoc =
        await _firestore.collection('conversations').doc(conversationId).get();

    if (conversationDoc.exists) {
      final existingData = conversationDoc.data()!;
      participantUnreadCounts.addAll(
          Map<String, int>.from(existingData['participantUnreadCounts'] ?? {}));
    }

    // Increment unread count for receiver
    participantUnreadCounts[receiverId] =
        (participantUnreadCounts[receiverId] ?? 0) + 1;

    final conversation = ChatConversation(
      id: conversationId,
      participants: participants,
      lastMessageId: messageId,
      lastMessageContent: content,
      lastMessageSenderId: senderId,
      lastMessageTime: timestamp,
      participantUnreadCounts: participantUnreadCounts,
      createdAt: conversationDoc.exists
          ? (conversationDoc.data()!['createdAt'] as Timestamp).toDate()
          : timestamp,
      updatedAt: timestamp,
    );

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .set(conversation.toFirestore());
  }

  // Get messages for a conversation
  Stream<List<Message>> getMessages(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final conversationId = _getConversationId(currentUser.uid, otherUserId);

    return _firestore
        .collection('messages')
        .where('senderId', whereIn: [currentUser.uid, otherUserId])
        .where('receiverId', whereIn: [currentUser.uid, otherUserId])
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  // Get user conversations
  Stream<List<ChatConversation>> getUserConversations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatConversation.fromFirestore(doc))
            .toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final conversationId = _getConversationId(currentUser.uid, otherUserId);

    try {
      // Mark messages as read
      final unreadMessages = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'delivered')
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();

      // Update conversation unread count
      await _firestore.collection('conversations').doc(conversationId).update({
        'participantUnreadCounts.$currentUser.uid': 0,
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadCounts =
            Map<String, int>.from(data['participantUnreadCounts'] ?? {});
        totalUnread += unreadCounts[currentUser.uid] ?? 0;
      }
      return totalUnread;
    });
  }

  // Send message notification
  Future<void> _sendMessageNotification(
      String receiverId, String message, String senderId) async {
    try {
      final senderDoc =
          await _firestore.collection('users').doc(senderId).get();
      final senderData = senderDoc.data();
      final senderName = senderData?['fullName'] ?? 'User';

      await _firestore.collection('notifications').add({
        'userId': receiverId,
        'title': 'New Message',
        'message':
            '$senderName: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
        'type': 'message',
        'senderId': senderId,
        'senderName': senderName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'conversationId': _getConversationId(senderId, receiverId),
          'message': message,
        },
      });
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final conversationId = _getConversationId(currentUser.uid, otherUserId);

    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Get typing status stream
  Stream<bool> getTypingStatus(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(false);
    }

    final typingDocId = '${otherUserId}_${currentUser.uid}';

    return _firestore.collection('typing').doc(typingDocId).snapshots().map(
        (snapshot) =>
            snapshot.exists && (snapshot.data()?['isTyping'] ?? false));
  }

  // Update typing status
  Future<void> updateTypingStatus(String otherUserId, bool isTyping) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final typingDocId = '${currentUser.uid}_$otherUserId';

    if (isTyping) {
      await _firestore.collection('typing').doc(typingDocId).set({
        'isTyping': true,
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('typing').doc(typingDocId).delete();
    }
  }
}
