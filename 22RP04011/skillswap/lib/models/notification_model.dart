import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  skillRequest,
  sessionInvite,
  sessionReminder,
  message,
  rating,
  achievement,
  system,
  promotion,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final String userId;
  final String? senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isRead;
  final bool isActioned;
  final Map<String, dynamic> data;
  final String? actionUrl;
  final String? actionText;
  final int? badgeCount;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.medium,
    required this.userId,
    this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    required this.createdAt,
    this.readAt,
    this.isRead = false,
    this.isActioned = false,
    this.data = const {},
    this.actionUrl,
    this.actionText,
    this.badgeCount,
  });

  // Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? data['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'system'),
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == (data['priority'] ?? 'medium'),
        orElse: () => NotificationPriority.medium,
      ),
      userId: data['userId'] ?? '',
      senderId: data['senderId'],
      senderName: data['senderName'],
      senderPhotoUrl: data['senderPhotoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] ?? false,
      isActioned: data['isActioned'] ?? false,
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      actionUrl: data['actionUrl'],
      actionText: data['actionText'],
      badgeCount: data['badgeCount'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'userId': userId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'isRead': isRead,
      'isActioned': isActioned,
      'data': data,
      'actionUrl': actionUrl,
      'actionText': actionText,
      'badgeCount': badgeCount,
    };
  }

  // Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    String? userId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    DateTime? createdAt,
    DateTime? readAt,
    bool? isRead,
    bool? isActioned,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? actionText,
    int? badgeCount,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
      isActioned: isActioned ?? this.isActioned,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
      badgeCount: badgeCount ?? this.badgeCount,
    );
  }

  // Mark as read
  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  // Mark as actioned
  NotificationModel markAsActioned() {
    return copyWith(isActioned: true);
  }

  // Get priority color
  Color get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.medium:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  // Get type icon
  IconData get typeIcon {
    switch (type) {
      case NotificationType.skillRequest:
        return Icons.school;
      case NotificationType.sessionInvite:
        return Icons.event;
      case NotificationType.sessionReminder:
        return Icons.alarm;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.rating:
        return Icons.star;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.promotion:
        return Icons.local_offer;
    }
  }

  // Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

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

  // Check if notification is recent (within 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  // Get notification preview (truncated message)
  String get preview {
    if (message.length <= 60) return message;
    return '${message.substring(0, 60)}...';
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Notification templates
class NotificationTemplates {
  static NotificationModel skillRequest({
    required String id,
    required String userId,
    required String senderId,
    required String senderName,
    required String skillName,
    String? senderPhotoUrl,
  }) {
    return NotificationModel(
      id: id,
      title: 'New Skill Request',
      message: '$senderName wants to learn $skillName from you!',
      type: NotificationType.skillRequest,
      priority: NotificationPriority.high,
      userId: userId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      createdAt: DateTime.now(),
      actionText: 'View Request',
      data: {'skillName': skillName},
    );
  }

  static NotificationModel sessionInvite({
    required String id,
    required String userId,
    required String senderId,
    required String senderName,
    required String sessionTitle,
    required DateTime sessionTime,
    String? senderPhotoUrl,
  }) {
    return NotificationModel(
      id: id,
      title: 'Session Invitation',
      message: '$senderName invited you to "$sessionTitle"',
      type: NotificationType.sessionInvite,
      priority: NotificationPriority.high,
      userId: userId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      createdAt: DateTime.now(),
      actionText: 'Respond',
      data: {
        'sessionTitle': sessionTitle,
        'sessionTime': sessionTime.toIso8601String(),
      },
    );
  }

  static NotificationModel achievement({
    required String id,
    required String userId,
    required String achievementTitle,
    required String achievementDescription,
  }) {
    return NotificationModel(
      id: id,
      title: 'Achievement Unlocked!',
      message: 'Congratulations! You earned: $achievementTitle',
      type: NotificationType.achievement,
      priority: NotificationPriority.medium,
      userId: userId,
      createdAt: DateTime.now(),
      actionText: 'View Achievement',
      data: {
        'achievementTitle': achievementTitle,
        'achievementDescription': achievementDescription,
      },
    );
  }
}
