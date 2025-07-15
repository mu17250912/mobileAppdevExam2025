import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import '../models/chat_model.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate chat ID for two users
  static String _generateChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? '${user1}_$user2'
        : '${user2}_$user1';
  }

  // Simple encryption key (in production, use proper key management)
  static String _getEncryptionKey(String chatId) {
    final user = _auth.currentUser;
    if (user == null) return '';

    final key = '${user.uid}_$chatId';
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }

  // Simple encryption (in production, use proper encryption)
  static String _encrypt(String text, String key) {
    if (key.isEmpty) return text;

    final bytes = utf8.encode(text);
    final keyBytes = utf8.encode(key);
    final encrypted = <int>[];

    for (int i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64.encode(encrypted);
  }

  // Simple decryption
  static String _decrypt(String encryptedText, String key) {
    if (key.isEmpty) return encryptedText;

    try {
      final encrypted = base64.decode(encryptedText);
      final keyBytes = utf8.encode(key);
      final decrypted = <int>[];

      for (int i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      return encryptedText; // Return original if decryption fails
    }
  }

  // Send message
  static Future<void> sendMessage({
    required String receiverId,
    required String text,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    bool isEncrypted = false,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final chatId = _generateChatId(currentUser.uid, receiverId);
    final timestamp = DateTime.now();

    // Encrypt message if needed
    final processedText =
        isEncrypted ? _encrypt(text, _getEncryptionKey(chatId)) : text;

    final message = ChatMessage(
      id: '', // Will be set by Firestore
      senderId: currentUser.uid,
      receiverId: receiverId,
      text: processedText,
      type: type,
      timestamp: timestamp,
      replyToMessageId: replyToMessageId,
      metadata: metadata,
    );

    // Add message to Firestore
    final messageRef = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toFirestore());

    // Update chat thread
    await _updateChatThread(
      chatId: chatId,
      user1Id: currentUser.uid,
      user2Id: receiverId,
      lastMessageText: text,
      lastMessageSenderId: currentUser.uid,
      isEncrypted: isEncrypted,
    );

    // Send notification to receiver
    await _sendChatNotification(receiverId, text);
  }

  // Get messages stream
  static Stream<List<ChatMessage>> getMessagesStream(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    final chatId = _generateChatId(currentUser.uid, otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final message = ChatMessage.fromFirestore(doc);

        // Decrypt message if needed
        final chatThread = _getChatThreadSync(chatId);
        if (chatThread?.isEncrypted == true) {
          final decryptedText =
              _decrypt(message.text, _getEncryptionKey(chatId));
          return message.copyWith(text: decryptedText);
        }

        return message;
      }).toList();
    });
  }

  // Get chat threads stream
  static Stream<List<ChatThread>> getChatThreadsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('chatThreads')
        .where('user1Id', isEqualTo: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final threads = <ChatThread>[];

      for (final doc in snapshot.docs) {
        threads.add(ChatThread.fromFirestore(doc));
      }

      // Also get threads where current user is user2
      final snapshot2 = await _firestore
          .collection('chatThreads')
          .where('user2Id', isEqualTo: currentUser.uid)
          .get();

      for (final doc in snapshot2.docs) {
        threads.add(ChatThread.fromFirestore(doc));
      }

      // Sort by last message time
      threads.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return threads;
    });
  }

  // Update chat thread
  static Future<void> _updateChatThread({
    required String chatId,
    required String user1Id,
    required String user2Id,
    required String lastMessageText,
    required String lastMessageSenderId,
    bool isEncrypted = false,
  }) async {
    final threadData = {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'lastMessageTime': Timestamp.now(),
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'isEncrypted': isEncrypted,
    };

    await _firestore
        .collection('chatThreads')
        .doc(chatId)
        .set(threadData, SetOptions(merge: true));
  }

  // Get chat thread synchronously (for internal use)
  static ChatThread? _getChatThreadSync(String chatId) {
    // This is a simplified version - in production, you'd want to cache this
    return null;
  }

  // Add reaction to message
  static Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String reaction,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.${currentUser.uid}': reaction,
    });
  }

  // Remove reaction from message
  static Future<void> removeReaction({
    required String chatId,
    required String messageId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.${currentUser.uid}': FieldValue.delete(),
    });
  }

  // Pin/unpin message
  static Future<void> togglePinMessage({
    required String chatId,
    required String messageId,
    required bool isPinned,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isPinned': isPinned,
    });

    // Update chat thread pinned messages
    final threadRef = _firestore.collection('chatThreads').doc(chatId);
    if (isPinned) {
      await threadRef.update({
        'pinnedMessageIds': FieldValue.arrayUnion([messageId]),
      });
    } else {
      await threadRef.update({
        'pinnedMessageIds': FieldValue.arrayRemove([messageId]),
      });
    }
  }

  // Toggle chat mode
  static Future<void> toggleChatMode({
    required String chatId,
    required ChatMode mode,
  }) async {
    await _firestore.collection('chatThreads').doc(chatId).update({
      'mode': mode.toString().split('.').last,
    });
  }

  // Search messages
  static Future<List<ChatMessage>> searchMessages({
    required String chatId,
    required String query,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('text', isGreaterThanOrEqualTo: query)
        .where('text', isLessThan: query + '\uf8ff')
        .get();

    return snapshot.docs.map((doc) {
      final message = ChatMessage.fromFirestore(doc);

      // Decrypt message if needed
      final chatThread = _getChatThreadSync(chatId);
      if (chatThread?.isEncrypted == true) {
        final decryptedText = _decrypt(message.text, _getEncryptionKey(chatId));
        return message.copyWith(text: decryptedText);
      }

      return message;
    }).toList();
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final batch = _firestore.batch();

    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();

    // Update unread count in thread
    await _firestore
        .collection('chatThreads')
        .doc(chatId)
        .update({'unreadCount': 0});
  }

  // Send chat notification
  static Future<void> _sendChatNotification(
      String receiverId, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get sender name
    final senderDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();

    final senderName = senderDoc.data()?['name'] ?? 'Someone';

    await _firestore.collection('notifications').add({
      'userId': receiverId,
      'title': 'New message from $senderName',
      'body': message.length > 50 ? '${message.substring(0, 50)}...' : message,
      'type': 'chat',
      'isRead': false,
      'timestamp': Timestamp.now(),
      'data': {
        'senderId': currentUser.uid,
        'senderName': senderName,
      },
    });
  }

  // Get unread chat count
  static Stream<int> getUnreadChatCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('chatThreads')
        .where('user1Id', isEqualTo: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      int totalUnread = 0;

      for (final doc in snapshot.docs) {
        final thread = ChatThread.fromFirestore(doc);
        totalUnread += thread.unreadCount;
      }

      // Also check threads where current user is user2
      final snapshot2 = await _firestore
          .collection('chatThreads')
          .where('user2Id', isEqualTo: currentUser.uid)
          .get();

      for (final doc in snapshot2.docs) {
        final thread = ChatThread.fromFirestore(doc);
        totalUnread += thread.unreadCount;
      }

      return totalUnread;
    });
  }
}
