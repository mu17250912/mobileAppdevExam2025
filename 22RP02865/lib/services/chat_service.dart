import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/study_buddy.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controllers for real-time updates
  final StreamController<List<ChatRoom>> _chatRoomsController = 
      StreamController<List<ChatRoom>>.broadcast();
  final StreamController<List<ChatMessage>> _messagesController = 
      StreamController<List<ChatMessage>>.broadcast();
  final StreamController<List<StudyBuddy>> _buddiesController = 
      StreamController<List<StudyBuddy>>.broadcast();

  // Getters for streams
  Stream<List<ChatRoom>> get chatRoomsStream => _chatRoomsController.stream;
  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;
  Stream<List<StudyBuddy>> get buddiesStream => _buddiesController.stream;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Initialize chat service
  void initialize() {
    if (currentUserId != null) {
      _listenToChatRooms();
      _listenToStudyBuddies();
    }
  }

  // Listen to user's chat rooms
  void _listenToChatRooms() {
    if (currentUserId == null) return;

    _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) {
      final chatRooms = snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatRoom.fromMap(data, doc.id);
      }).toList();
      
      // Sort locally to avoid Firebase index requirement
      chatRooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      
      _chatRoomsController.add(chatRooms);
    });
  }

  // Listen to study buddies
  void _listenToStudyBuddies() {
    if (currentUserId == null) return;

    _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('studyBuddies')
        .snapshots()
        .listen((snapshot) {
      final buddies = snapshot.docs.map((doc) {
        final data = doc.data();
        return StudyBuddy.fromMap(data, doc.id);
      }).toList();
      _buddiesController.add(buddies);
    });
  }

  // Create a new chat room
  Future<ChatRoom> createChatRoom({
    required String name,
    required List<String> participantIds,
    String? description,
    ChatRoomType type = ChatRoomType.group,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Ensure current user is in participants
    if (!participantIds.contains(currentUserId)) {
      participantIds.add(currentUserId!);
    }

    final chatRoom = ChatRoom(
      id: '',
      name: name,
      description: description ?? '',
      participants: participantIds,
      type: type,
      createdBy: currentUserId!,
      createdAt: DateTime.now(),
      lastMessageTime: DateTime.now(),
      lastMessage: '',
    );

    final docRef = await _firestore.collection('chatRooms').add(chatRoom.toMap());
    
    // Update the chat room with the generated ID
    final updatedChatRoom = chatRoom.copyWith(id: docRef.id);
    await docRef.update({'id': docRef.id});

    return updatedChatRoom;
  }

  // Create a direct message room
  Future<ChatRoom> createDirectMessage(String otherUserId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if DM already exists
    final existingRooms = await _firestore
        .collection('chatRooms')
        .where('type', isEqualTo: ChatRoomType.direct.index)
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in existingRooms.docs) {
      final room = ChatRoom.fromMap(doc.data(), doc.id);
      if (room.participants.length == 2 && 
          room.participants.contains(otherUserId)) {
        return room;
      }
    }

    // Get other user's name
    final otherUserDoc = await _firestore
        .collection('users')
        .doc(otherUserId)
        .get();
    
    final otherUserName = otherUserDoc.data()?['name'] ?? 'Unknown User';

    return createChatRoom(
      name: otherUserName,
      participantIds: [otherUserId],
      type: ChatRoomType.direct,
    );
  }

  // Send a message
  Future<void> sendMessage({
    required String roomId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final message = ChatMessage(
      id: '',
      roomId: roomId,
      senderId: currentUserId!,
      content: content,
      type: type,
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      isRead: false,
    );

    final batch = _firestore.batch();
    
    // Add message to chat room
    final messageRef = _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc();
    
    batch.set(messageRef, message.toMap());

    // Update chat room's last message
    batch.update(
      _firestore.collection('chatRooms').doc(roomId),
      {
        'lastMessage': content,
        'lastMessageTime': DateTime.now(),
      },
    );

    await batch.commit();
  }

  // Listen to messages in a chat room
  void listenToMessages(String roomId) {
    _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage.fromMap(data, doc.id);
      }).toList();
      _messagesController.add(messages);
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String roomId) async {
    if (currentUserId == null) return;

    final messages = await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Add study buddy
  Future<void> addStudyBuddy({
    required String buddyId,
    required String buddyName,
    String? buddyEmail,
    String? buddyAvatar,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final buddy = StudyBuddy(
      id: buddyId,
      name: buddyName,
      email: buddyEmail ?? '',
      avatar: buddyAvatar ?? '',
      addedAt: DateTime.now(),
      lastInteraction: DateTime.now(),
      sharedGoals: [],
      sharedResources: [],
    );

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('studyBuddies')
        .doc(buddyId)
        .set(buddy.toMap());
  }

  // Remove study buddy
  Future<void> removeStudyBuddy(String buddyId) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('studyBuddies')
        .doc(buddyId)
        .delete();
  }

  // Share study goal with buddy
  Future<void> shareGoalWithBuddy({
    required String buddyId,
    required String goalId,
    required String goalTitle,
  }) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('studyBuddies')
        .doc(buddyId)
        .update({
      'sharedGoals': FieldValue.arrayUnion([
        {
          'goalId': goalId,
          'title': goalTitle,
          'sharedAt': DateTime.now(),
        }
      ])
    });
  }

  // Share resource with buddy
  Future<void> shareResourceWithBuddy({
    required String buddyId,
    required String resourceId,
    required String resourceTitle,
    required String resourceType,
  }) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('studyBuddies')
        .doc(buddyId)
        .update({
      'sharedResources': FieldValue.arrayUnion([
        {
          'resourceId': resourceId,
          'title': resourceTitle,
          'type': resourceType,
          'sharedAt': DateTime.now(),
        }
      ])
    });
  }

  // Search for users to add as study buddies
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (currentUserId == null) return [];

    final users = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + '\uf8ff')
        .limit(10)
        .get();

    return users.docs
        .where((doc) => doc.id != currentUserId)
        .map((doc) => {
              'id': doc.id,
              'name': doc.data()['name'] ?? '',
              'email': doc.data()['email'] ?? '',
              'avatar': doc.data()['avatar'] ?? '',
            })
        .toList();
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collectionGroup('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete message
  Future<void> deleteMessage(String roomId, String messageId) async {
    if (currentUserId == null) return;

    final messageDoc = await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (messageDoc.exists && 
        messageDoc.data()?['senderId'] == currentUserId) {
      await messageDoc.reference.delete();
    }
  }

  // Leave chat room
  Future<void> leaveChatRoom(String roomId) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .update({
      'participants': FieldValue.arrayRemove([currentUserId])
    });
  }

  // Update user's online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .update({
      'isOnline': isOnline,
      'lastSeen': DateTime.now(),
    });
  }

  // Dispose resources
  void dispose() {
    _chatRoomsController.close();
    _messagesController.close();
    _buddiesController.close();
  }
} 