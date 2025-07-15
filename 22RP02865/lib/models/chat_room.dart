import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'chat_room.g.dart';

@HiveType(typeId: 12)
enum ChatRoomType {
  @HiveField(0)
  direct,
  @HiveField(1)
  group,
}

@HiveType(typeId: 13)
class ChatRoom extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<String> participants;

  @HiveField(4)
  final ChatRoomType type;

  @HiveField(5)
  final String createdBy;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime lastMessageTime;

  @HiveField(8)
  final String lastMessage;

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.participants,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.lastMessageTime,
    required this.lastMessage,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'participants': participants,
      'type': type.index,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'lastMessageTime': lastMessageTime,
      'lastMessage': lastMessage,
    };
  }

  // Create from Map (from Firestore)
  factory ChatRoom.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoom(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      type: ChatRoomType.values[map['type'] ?? 0],
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: map['lastMessage'] ?? '',
    );
  }

  // Copy with modifications
  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? participants,
    ChatRoomType? type,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastMessageTime,
    String? lastMessage,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  // Check if user is participant
  bool isParticipant(String userId) {
    return participants.contains(userId);
  }

  // Add participant
  ChatRoom addParticipant(String userId) {
    if (!participants.contains(userId)) {
      final newParticipants = List<String>.from(participants)..add(userId);
      return copyWith(participants: newParticipants);
    }
    return this;
  }

  // Remove participant
  ChatRoom removeParticipant(String userId) {
    final newParticipants = List<String>.from(participants)..remove(userId);
    return copyWith(participants: newParticipants);
  }

  // Update last message
  ChatRoom updateLastMessage(String message) {
    return copyWith(
      lastMessage: message,
      lastMessageTime: DateTime.now(),
    );
  }

  // Get formatted last message time
  String get formattedLastMessageTime {
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Get participant count
  int get participantCount {
    return participants.length;
  }

  // Check if it's a direct message
  bool get isDirect {
    return type == ChatRoomType.direct;
  }

  // Check if it's a group chat
  bool get isGroup {
    return type == ChatRoomType.group;
  }

  // Get chat room icon
  String get icon {
    switch (type) {
      case ChatRoomType.direct:
        return '👤';
      case ChatRoomType.group:
        return '👥';
      default:
        return '💬';
    }
  }

  // Get chat room color
  int get color {
    switch (type) {
      case ChatRoomType.direct:
        return 0xFF2196F3; // Blue
      case ChatRoomType.group:
        return 0xFF4CAF50; // Green
      default:
        return 0xFF607D8B; // Blue Grey
    }
  }
} 