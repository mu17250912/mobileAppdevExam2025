class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // application, internship, general
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId; // internshipId or applicationId
  final String? actionUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.relatedId,
    this.actionUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'relatedId': relatedId,
      'actionUrl': actionUrl,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      message: map['message'],
      type: map['type'],
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'],
      relatedId: map['relatedId'],
      actionUrl: map['actionUrl'],
    );
  }
} 