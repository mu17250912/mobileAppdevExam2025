import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final List<String> participants;
  final String lastMessageId;
  final String lastMessageContent;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final int unreadCount;
  final Map<String, int> participantUnreadCounts;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.participants,
    required this.lastMessageId,
    required this.lastMessageContent,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.participantUnreadCounts,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessageId: data['lastMessageId'] ?? '',
      lastMessageContent: data['lastMessageContent'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      participantUnreadCounts:
          Map<String, int>.from(data['participantUnreadCounts'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessageId': lastMessageId,
      'lastMessageContent': lastMessageContent,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'participantUnreadCounts': participantUnreadCounts,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String getConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  bool isParticipant(String userId) {
    return participants.contains(userId);
  }

  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId);
  }

  ChatConversation copyWith({
    String? id,
    List<String>? participants,
    String? lastMessageId,
    String? lastMessageContent,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    int? unreadCount,
    Map<String, int>? participantUnreadCounts,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      participantUnreadCounts:
          participantUnreadCounts ?? this.participantUnreadCounts,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
