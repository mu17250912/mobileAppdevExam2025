import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';

class MessagingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or get chat between participants
  static Future<String> createOrGetChat(List<String> participantIds, {bool isGroup = false, String? groupName}) async {
    participantIds.sort();
    final chatId = participantIds.join('_');
    final chatDoc = await _firestore.collection(AppConstants.chatsCollection).doc(chatId).get();
    if (!chatDoc.exists) {
      final chat = ChatModel(
        id: chatId,
        participantIds: participantIds,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCounts: {for (var id in participantIds) id: 0},
        isGroup: isGroup,
        groupName: groupName,
      );
      await _firestore.collection(AppConstants.chatsCollection).doc(chatId).set(chat.toJson());
    }
    return chatId;
  }

  // Send message
  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String? attachmentUrl,
    String type = 'text',
  }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = MessageModel(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      content: content,
      attachmentUrl: attachmentUrl,
      timestamp: DateTime.now(),
      readBy: [senderId],
      isDeleted: false,
      isBlocked: false,
      type: type,
    );
    await _firestore.collection(AppConstants.chatsCollection).doc(chatId)
      .collection('messages').doc(messageId).set(message.toJson());
    // Update chat metadata
    await _firestore.collection(AppConstants.chatsCollection).doc(chatId).update({
      'lastMessage': content,
      'lastMessageTime': DateTime.now().toIso8601String(),
      'unreadCounts': FieldValue.increment(1),
    });
  }

  // Fetch chats for a user (real-time)
  static Stream<List<ChatModel>> getChatsForUser(String userId) {
    return _firestore.collection(AppConstants.chatsCollection)
      .where('participantIds', arrayContains: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ChatModel.fromJson(doc.data())).toList());
  }

  // Fetch messages for a chat (real-time)
  static Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore.collection(AppConstants.chatsCollection).doc(chatId)
      .collection('messages').orderBy('timestamp').snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromJson(doc.data())).toList());
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String chatId, String userId) async {
    final messages = await _firestore.collection(AppConstants.chatsCollection).doc(chatId)
      .collection('messages').where('readBy', arrayContains: userId).get();
    for (final doc in messages.docs) {
      if (!doc.data()['readBy'].contains(userId)) {
        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
    // Optionally update chat unreadCounts
    await _firestore.collection(AppConstants.chatsCollection).doc(chatId)
      .update({'unreadCounts.$userId': 0});
  }

  // Delete specific message
  static Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore.collection(AppConstants.chatsCollection).doc(chatId)
      .collection('messages').doc(messageId).delete();
  }

  // Delete conversation
  static Future<void> deleteChat(String chatId) async {
    final messages = await _firestore.collection(AppConstants.chatsCollection).doc(chatId)
      .collection('messages').get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection(AppConstants.chatsCollection).doc(chatId).delete();
  }

  // Block/report user (set isBlocked on all messages from that user)
  static Future<void> blockUserInChat(String chatId, String userId) async {
    final messages = await _firestore.collection(AppConstants.chatsCollection).doc(chatId)
      .collection('messages').where('senderId', isEqualTo: userId).get();
    for (final doc in messages.docs) {
      await doc.reference.update({'isBlocked': true});
    }
  }

  // Search messages
  static Future<List<MessageModel>> searchMessages(String query) async {
    // This is a simplified search - in a real app, you might want to use
    // a more sophisticated search solution like Algolia or Elasticsearch
    final chats = await _firestore.collection(AppConstants.chatsCollection).get();
    List<MessageModel> results = [];
    
    for (final chatDoc in chats.docs) {
      final messages = await _firestore.collection(AppConstants.chatsCollection)
        .doc(chatDoc.id).collection('messages')
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThan: query + '\uf8ff')
        .get();
      
      for (final messageDoc in messages.docs) {
        results.add(MessageModel.fromJson(messageDoc.data()));
      }
    }
    
    return results;
  }

  // Admin broadcast
  static Future<void> broadcastMessage({
    required String senderId,
    required String content,
    String? attachmentUrl,
    String type = 'text',
    required List<String> recipientIds,
  }) async {
    for (final recipientId in recipientIds) {
      final chatId = await createOrGetChat([senderId, recipientId]);
      await sendMessage(
        chatId: chatId,
        senderId: senderId,
        content: content,
        attachmentUrl: attachmentUrl,
        type: type,
      );
    }
  }
} 