import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Show a snackbar notification
  static void showNotification(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show application status update notification
  static void showApplicationStatusUpdate(BuildContext context, String jobTitle, String status) {
    String message = '';
    Color backgroundColor = Colors.blue;
    
    switch (status.toLowerCase()) {
      case 'accepted':
        message = '🎉 Congratulations! Your application for "$jobTitle" has been accepted!';
        backgroundColor = Colors.green;
        break;
      case 'rejected':
        message = 'Thank you for your interest in "$jobTitle". Unfortunately, your application was not selected.';
        backgroundColor = Colors.orange;
        break;
      case 'reviewed':
        message = 'Your application for "$jobTitle" is currently under review.';
        backgroundColor = Colors.blue;
        break;
      default:
        message = 'Your application for "$jobTitle" has been updated.';
        backgroundColor = Colors.blue;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.toLowerCase() == 'accepted' ? Icons.check_circle : 
                  status.toLowerCase() == 'rejected' ? Icons.info : Icons.schedule,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            SizedBox(height: 4),
            Text(
              '📧 Check your email for detailed response from the employer.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 8),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to applications screen
            Navigator.pushNamed(context, '/my-applications');
          },
        ),
      ),
    );
  }

  /// Show admin response notification
  static void showAdminResponseNotification(BuildContext context, String jobTitle, String adminNotes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.orange[700]),
            SizedBox(width: 8),
            Text('Admin Response'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job: $jobTitle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.blue[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '📧 Please check your email carefully for detailed responses from employers.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Admin Response:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(adminNotes),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/my-applications');
            },
            child: Text('View All Applications'),
          ),
        ],
      ),
    );
  }

  /// Create a notification document in Firestore
  static Future<void> createNotification({
    required String userId,
    required String jobId,
    required String jobTitle,
    required String type, // 'status_update', 'admin_response'
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'jobId': jobId,
        'jobTitle': jobTitle,
        'type': type,
        'message': message,
        'additionalData': additionalData,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Get user notifications
  static Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final notificationsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      return notificationsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  static Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final notificationsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      return notificationsSnapshot.docs.length;
    } catch (e) {
      print('Error getting unread notifications count: $e');
      return 0;
    }
  }
} 