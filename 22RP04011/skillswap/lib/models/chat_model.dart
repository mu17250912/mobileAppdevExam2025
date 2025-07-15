import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMode {
  quick,
  detailed,
}

enum MessageType {
  text,
  image,
  file,
  location,
  voice,
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, String> reactions; // userId -> reaction emoji
  final bool isPinned;
  final String? replyToMessageId;
  final Map<String, dynamic>?
      metadata; // For additional data like file URLs, etc.

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.reactions = const {},
    this.isPinned = false,
    this.replyToMessageId,
    this.metadata,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type'] ?? 'text'}',
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      reactions: data['reactions'] != null && data['reactions'] is Map
          ? Map<String, String>.from(data['reactions'])
          : <String, String>{},
      isPinned: data['isPinned'] ?? false,
      replyToMessageId: data['replyToMessageId'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'reactions': reactions,
      'isPinned': isPinned,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, String>? reactions,
    bool? isPinned,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      reactions: reactions ?? this.reactions,
      isPinned: isPinned ?? this.isPinned,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ChatThread {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime lastMessageTime;
  final String lastMessageText;
  final String lastMessageSenderId;
  final int unreadCount;
  final ChatMode mode;
  final List<String> pinnedMessageIds;
  final bool isEncrypted;

  ChatThread({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.lastMessageTime,
    required this.lastMessageText,
    required this.lastMessageSenderId,
    this.unreadCount = 0,
    this.mode = ChatMode.quick,
    this.pinnedMessageIds = const [],
    this.isEncrypted = false,
  });

  factory ChatThread.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatThread(
      id: doc.id,
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      lastMessageText: data['lastMessageText'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCount: data['unreadCount'] ?? 0,
      mode: ChatMode.values.firstWhere(
        (e) => e.toString() == 'ChatMode.${data['mode'] ?? 'quick'}',
        orElse: () => ChatMode.quick,
      ),
      pinnedMessageIds: List<String>.from(data['pinnedMessageIds'] ?? []),
      isEncrypted: data['isEncrypted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'mode': mode.toString().split('.').last,
      'pinnedMessageIds': pinnedMessageIds,
      'isEncrypted': isEncrypted,
    };
  }

  String getOtherUserId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final BadgeType type;
  final int requiredValue;
  final String? skillId; // For skill-specific badges
  final DateTime? earnedAt;
  final bool isEarned;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.type,
    required this.requiredValue,
    this.skillId,
    this.earnedAt,
    this.isEarned = false,
  });

  factory Badge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Badge(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      emoji: data['emoji'] ?? '',
      type: BadgeType.values.firstWhere(
        (e) => e.toString() == 'BadgeType.${data['type'] ?? 'session'}',
        orElse: () => BadgeType.session,
      ),
      requiredValue: data['requiredValue'] ?? 0,
      skillId: data['skillId'],
      earnedAt: data['earnedAt'] != null
          ? (data['earnedAt'] as Timestamp).toDate()
          : null,
      isEarned: data['isEarned'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'emoji': emoji,
      'type': type.toString().split('.').last,
      'requiredValue': requiredValue,
      'skillId': skillId,
      'earnedAt': earnedAt != null ? Timestamp.fromDate(earnedAt!) : null,
      'isEarned': isEarned,
    };
  }

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? emoji,
    BadgeType? type,
    int? requiredValue,
    String? skillId,
    DateTime? earnedAt,
    bool? isEarned,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      requiredValue: requiredValue ?? this.requiredValue,
      skillId: skillId ?? this.skillId,
      earnedAt: earnedAt ?? this.earnedAt,
      isEarned: isEarned ?? this.isEarned,
    );
  }
}

enum BadgeType {
  session,
  skill,
  community,
  time,
}
