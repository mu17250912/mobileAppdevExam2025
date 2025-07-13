import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file, sessionRequest }

enum MessageStatus { sent, delivered, read, failed }

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;
  final List<String>? attachments;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.metadata,
    this.replyToMessageId,
    this.attachments,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type'] ?? 'text'}',
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${data['status'] ?? 'sent'}',
        orElse: () => MessageStatus.sent,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      replyToMessageId: data['replyToMessageId'] as String?,
      attachments: List<String>.from(data['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
      'attachments': attachments,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    List<String>? attachments,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      attachments: attachments ?? this.attachments,
    );
  }
}
