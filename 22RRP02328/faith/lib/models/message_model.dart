class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String? attachmentUrl;
  final DateTime timestamp;
  final List<String> readBy;
  final bool isDeleted;
  final bool isBlocked;
  final String? type; // 'text', 'image', 'file', etc.

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.attachmentUrl,
    required this.timestamp,
    required this.readBy,
    this.isDeleted = false,
    this.isBlocked = false,
    this.type = 'text',
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      content: json['content'],
      attachmentUrl: json['attachmentUrl'],
      timestamp: DateTime.parse(json['timestamp']),
      readBy: List<String>.from(json['readBy'] ?? []),
      isDeleted: json['isDeleted'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      type: json['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'attachmentUrl': attachmentUrl,
      'timestamp': timestamp.toIso8601String(),
      'readBy': readBy,
      'isDeleted': isDeleted,
      'isBlocked': isBlocked,
      'type': type,
    };
  }
} 