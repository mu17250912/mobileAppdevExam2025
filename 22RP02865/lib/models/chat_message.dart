import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 10)
enum MessageType {
  @HiveField(0)
  text,
  @HiveField(1)
  studyTip,
  @HiveField(2)
  motivation,
  @HiveField(3)
  resource,
  @HiveField(4)
  goal,
}

@HiveType(typeId: 11)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String roomId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final MessageType type;

  @HiveField(5)
  final Map<String, dynamic> metadata;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    this.isRead = false,
  }) : 
    metadata = metadata ?? {},
    timestamp = timestamp ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'type': type.index,
      'metadata': metadata,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  // Create from Map (from Firestore)
  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      roomId: map['roomId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values[map['type'] ?? 0],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  // Copy with modifications
  ChatMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? content,
    MessageType? type,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  // Check if message is from current user
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  // Get formatted time
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

  // Get message preview (for chat list)
  String get preview {
    switch (type) {
      case MessageType.text:
        return content.length > 50 ? '${content.substring(0, 50)}...' : content;
      case MessageType.studyTip:
        return '💡 Study Tip';
      case MessageType.motivation:
        return '💪 Motivation';
      case MessageType.resource:
        return '📚 Resource';
      case MessageType.goal:
        return '🎯 Goal';
      default:
        return 'Message';
    }
  }

  // Get message color based on type
  int get messageColor {
    switch (type) {
      case MessageType.studyTip:
        return 0xFF4CAF50; // Green
      case MessageType.motivation:
        return 0xFFFF9800; // Orange
      case MessageType.resource:
        return 0xFF2196F3; // Blue
      case MessageType.goal:
        return 0xFF9C27B0; // Purple
      default:
        return 0xFF000000; // Black
    }
  }
} 