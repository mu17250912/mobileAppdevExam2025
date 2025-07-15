import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new notification
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore.collection('notifications').add(notification.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get notifications for a specific user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return NotificationModel.fromMap(data);
      }).toList();
    });
  }

  // Get unread notifications count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Create application notification for company
  Future<void> notifyCompanyOfApplication(String companyId, String internshipTitle, String studentName) async {
    final notification = NotificationModel(
      id: '',
      userId: companyId,
      title: 'New Application Received',
      message: '$studentName has applied for "$internshipTitle"',
      type: 'application',
      createdAt: DateTime.now(),
      isRead: false,
    );
    
    await createNotification(notification);
  }

  // Create status update notification for student
  Future<void> notifyStudentOfStatusUpdate(String studentId, String internshipTitle, String status) async {
    final notification = NotificationModel(
      id: '',
      userId: studentId,
      title: 'Application Status Updated',
      message: 'Your application for "$internshipTitle" has been $status',
      type: 'application',
      createdAt: DateTime.now(),
      isRead: false,
    );
    
    await createNotification(notification);
  }

  // Create new internship notification for students
  Future<void> notifyStudentsOfNewInternship(List<String> studentIds, String companyName, String internshipTitle) async {
    final batch = _firestore.batch();
    
    for (String studentId in studentIds) {
      final notification = NotificationModel(
        id: '',
        userId: studentId,
        title: 'New Internship Opportunity',
        message: '$companyName has posted a new internship: "$internshipTitle"',
        type: 'internship',
        createdAt: DateTime.now(),
        isRead: false,
      );
      
      final docRef = _firestore.collection('notifications').doc();
      batch.set(docRef, notification.toMap());
    }
    
    await batch.commit();
  }
} 