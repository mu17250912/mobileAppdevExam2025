import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../services/messaging_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagingProvider extends ChangeNotifier {
  List<ChatModel> _chats = [];
  List<MessageModel> _currentChatMessages = [];
  String? _currentChatId;
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  final Map<String, bool> _typingUsers = {}; // chatId -> isTyping
  Map<String, String> _userNames = {}; // userId -> userName
  String? _currentUserId;
  String? _currentUserRole;

  StreamSubscription<List<ChatModel>>? _chatsSub;
  StreamSubscription<List<MessageModel>>? _messagesSub;

  // Getters
  List<ChatModel> get chats => _chats;
  List<MessageModel> get currentChatMessages => _currentChatMessages;
  String? get currentChatId => _currentChatId;
  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  Map<String, bool> get typingUsers => _typingUsers;
  Map<String, String> get userNames => _userNames;
  String? get currentUserRole => _currentUserRole;

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  void _cancelSubscriptions() {
    _chatsSub?.cancel();
    _chatsSub = null;
    _messagesSub?.cancel();
    _messagesSub = null;
  }

  void reset() {
    _cancelSubscriptions();
    _chats = [];
    _currentChatMessages = [];
    _currentChatId = null;
    _isLoading = false;
    _error = null;
    _unreadCount = 0;
    _typingUsers.clear();
    _userNames.clear();
    _currentUserId = null;
    _currentUserRole = null;
    notifyListeners();
  }

  // Initialize messaging
  void initialize() async {
    _setLoading(true);
    _clearError();
    _cancelSubscriptions();
    try {
      _currentUserId = AuthService.currentUser?.uid;
      if (_currentUserId != null) {
        final userData = await AuthService.getUserData(_currentUserId!);
        _currentUserRole = userData?.userType;
      }
      await _loadChats();
      await _loadUnreadCount();
      await _loadUserNames();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load user chats with role-based filtering
  Future<void> _loadChats() async {
    if (_currentUserId == null) return;
    _chatsSub?.cancel();
    try {
      _chatsSub = MessagingService.getChatsForUser(_currentUserId!).listen((chats) {
        if (_currentUserRole == 'admin') {
          _chats = chats;
        } else {
          _chats = chats;
        }
        notifyListeners();
      }, onError: (e) {
        _setError(e.toString());
      });
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Load unread message count
  Future<void> _loadUnreadCount() async {
    if (_currentUserId == null) return;
    
    try {
      int totalUnread = 0;
      for (final chat in _chats) {
        totalUnread += chat.unreadCounts[_currentUserId] ?? 0;
      }
      _unreadCount = totalUnread;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Optimize user name fetching: only fetch if not cached
  Future<void> _loadUserNames() async {
    try {
      final idsToFetch = <String>{};
      for (final chat in _chats) {
        for (final participantId in chat.participantIds) {
          if (participantId != _currentUserId && !_userNames.containsKey(participantId)) {
            idsToFetch.add(participantId);
          }
        }
      }
      for (final participantId in idsToFetch) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(participantId).get();
          if (userDoc.exists && userDoc.data() != null) {
            _userNames[participantId] = userDoc.data()!['name'] ?? 'User';
          } else {
            _userNames[participantId] = 'User';
          }
        } catch (e) {
          _userNames[participantId] = 'User';
        }
      }
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Load messages for a specific chat
  Future<void> loadChatMessages(String chatId) async {
    _setLoading(true);
    _clearError();
    _messagesSub?.cancel();
    try {
      _currentChatId = chatId;
      _messagesSub = MessagingService.getMessages(chatId).listen((messages) {
        _currentChatMessages = messages;
        notifyListeners();
      }, onError: (e) {
        _setError(e.toString());
      });
      
      // Mark messages as read
      if (_currentUserId != null) {
        await MessagingService.markMessagesAsRead(chatId, _currentUserId!);
        await _loadUnreadCount(); // Refresh unread count
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Send message: only show notification on error
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
    String? replyTo,
  }) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    if (_currentChatId == null) {
      // Create new chat
      try {
        _currentChatId = await MessagingService.createOrGetChat([_currentUserId!, receiverId]);
      } catch (e) {
        _setError(e.toString());
        return false;
      }
    }

    try {
      await MessagingService.sendMessage(
        chatId: _currentChatId!,
        senderId: _currentUserId!,
        content: content,
        attachmentUrl: mediaUrl,
        type: messageType,
      );
      
      // Stop typing indicator
      _setTypingStatus(_currentChatId!, false);
      
      NotificationService.showSuccessNotification(
        title: 'Message Sent',
        message: 'Your message has been sent successfully!',
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      NotificationService.showErrorNotification(
        title: 'Message Failed',
        message: e.toString(),
      );
      return false;
    }
  }

  // Start new chat
  Future<void> startNewChat(String otherUserId) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final chatId = await MessagingService.createOrGetChat([_currentUserId!, otherUserId]);
      await loadChatMessages(chatId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Set typing status
  void _setTypingStatus(String chatId, bool isTyping) {
    _typingUsers[chatId] = isTyping;
    notifyListeners();
  }

  // Start typing indicator
  void startTyping(String chatId) {
    _setTypingStatus(chatId, true);
  }

  // Stop typing indicator
  void stopTyping(String chatId) {
    _setTypingStatus(chatId, false);
  }

  // Delete message
  Future<bool> deleteMessage(String messageId) async {
    if (_currentChatId == null) return false;
    
    try {
      await MessagingService.deleteMessage(_currentChatId!, messageId);
      NotificationService.showSuccessNotification(
        title: 'Message Deleted',
        message: 'Message has been deleted successfully!',
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Delete chat
  Future<bool> deleteChat(String chatId) async {
    try {
      await MessagingService.deleteChat(chatId);
      if (_currentChatId == chatId) {
        _currentChatId = null;
        _currentChatMessages.clear();
      }
      NotificationService.showSuccessNotification(
        title: 'Chat Deleted',
        message: 'Chat has been deleted successfully!',
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Block user in chat
  Future<bool> blockUser(String userId) async {
    if (_currentChatId == null) return false;
    
    try {
      await MessagingService.blockUserInChat(_currentChatId!, userId);
      NotificationService.showSuccessNotification(
        title: 'User Blocked',
        message: 'User has been blocked successfully!',
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Admin broadcast message
  Future<bool> broadcastMessage({
    required String content,
    String messageType = 'text',
    String? mediaUrl,
    List<String>? specificRecipients,
  }) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    if (_currentUserRole != 'admin') {
      _setError('Only admins can broadcast messages');
      return false;
    }

    try {
      List<String> recipientIds = [];
      
      if (specificRecipients != null) {
        recipientIds = specificRecipients;
      } else {
        // Get all users for broadcast
        // This would need to be implemented in AuthService
        // For now, we'll use the current chat participants
        for (final chat in _chats) {
          for (final participantId in chat.participantIds) {
            if (participantId != _currentUserId && !recipientIds.contains(participantId)) {
              recipientIds.add(participantId);
            }
          }
        }
      }

      await MessagingService.broadcastMessage(
        senderId: _currentUserId!,
        content: content,
        attachmentUrl: mediaUrl,
        type: messageType,
        recipientIds: recipientIds,
      );

      NotificationService.showSuccessNotification(
        title: 'Broadcast Sent',
        message: 'Message has been broadcasted successfully!',
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Search messages
  Future<List<MessageModel>> searchMessages(String query) async {
    try {
      return await MessagingService.searchMessages(query);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  // Get chat by ID
  ChatModel? getChatById(String chatId) {
    try {
      return _chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  // Get other participant in chat
  String? getOtherParticipantId(String chatId) {
    final chat = getChatById(chatId);
    if (chat == null) return null;
    
    if (_currentUserId == null) return null;
    
    return chat.participantIds.firstWhere(
      (id) => id != _currentUserId,
      orElse: () => '',
    );
  }

  // Get other participant name
  Future<String> getOtherParticipantNameAsync(String chatId) async {
    final otherId = getOtherParticipantId(chatId);
    if (otherId == null || otherId.isEmpty) return 'Unknown User';
    if (_userNames.containsKey(otherId)) {
      return _userNames[otherId]!;
    }
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final name = userDoc.data()!['name'] ?? 'User';
        _userNames[otherId] = name;
        notifyListeners();
        return name;
      }
    } catch (e) {}
    return 'Unknown User';
  }

  // Synchronous fallback for UI (may show 'Unknown User' until async fetch completes)
  String getOtherParticipantName(String chatId) {
    final otherId = getOtherParticipantId(chatId);
    if (otherId == null || otherId.isEmpty) return 'Unknown User';
    return _userNames[otherId] ?? 'Unknown User';
  }

  // Clear current chat
  void clearCurrentChat() {
    _currentChatId = null;
    _currentChatMessages.clear();
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadChats();
    await _loadUnreadCount();
    await _loadUserNames();
  }
} 