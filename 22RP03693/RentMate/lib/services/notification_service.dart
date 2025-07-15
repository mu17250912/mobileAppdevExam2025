import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send notification to user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type ?? 'general',
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Get notifications for user
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationModel(
          id: doc.id,
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          type: data['type'] ?? 'general',
          data: data['data'],
          isRead: data['isRead'] ?? false,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Send booking notification
  Future<void> sendBookingNotification({
    required String userId,
    required String propertyTitle,
    required String status,
  }) async {
    String title;
    String message;

    switch (status.toLowerCase()) {
      case 'approved':
        title = 'Booking Approved!';
        message = 'Your booking for $propertyTitle has been approved.';
        break;
      case 'rejected':
        title = 'Booking Update';
        message = 'Your booking for $propertyTitle has been rejected.';
        break;
      case 'cancelled':
        title = 'Booking Cancelled';
        message = 'Your booking for $propertyTitle has been cancelled.';
        break;
      default:
        title = 'Booking Update';
        message = 'Your booking for $propertyTitle has been updated.';
    }

    await sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'booking',
      data: {'propertyTitle': propertyTitle, 'status': status},
    );
  }

  // Send payment notification
  Future<void> sendPaymentNotification({
    required String userId,
    required double amount,
    required String status,
  }) async {
    String title;
    String message;

    switch (status.toLowerCase()) {
      case 'completed':
        title = 'Payment Successful!';
        message = 'Your payment of \$${amount.toStringAsFixed(2)} has been processed successfully.';
        break;
      case 'failed':
        title = 'Payment Failed';
        message = 'Your payment of \$${amount.toStringAsFixed(2)} has failed. Please try again.';
        break;
      case 'refunded':
        title = 'Payment Refunded';
        message = 'Your payment of \$${amount.toStringAsFixed(2)} has been refunded.';
        break;
      default:
        title = 'Payment Update';
        message = 'Your payment of \$${amount.toStringAsFixed(2)} has been updated.';
    }

    await sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'payment',
      data: {'amount': amount, 'status': status},
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      data: json['data'],
      isRead: json['isRead'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 