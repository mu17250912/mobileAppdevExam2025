class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, String id) {
    return NotificationModel(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      read: json['read'] ?? false,
    );
  }
} 