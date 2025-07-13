import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/navigation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize FCM
  static Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Permission status handled silently

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToDatabase(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final data = message.data;
        final type = data['type'] ?? '';
        final title = message.notification!.title ?? 'Notification';
        final body = message.notification!.body ?? '';
        final context = navigatorKey.currentContext;
        if (context != null) {
          if (type == 'new_product') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title: $body')),
            );
          } else if (type == 'chat_message') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title: $body'),
                action: SnackBarAction(
                  label: 'Reply',
                  onPressed: () {
                    // Navigate to chat screen (implement navigation logic as needed)
                    // Example: Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen()));
                  },
                ),
              ),
            );
          }
        }
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  // Save FCM token to Firestore
  static Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  // Show local notification when app is in foreground
  static void _showLocalNotification(RemoteMessage message) {
    // You can use flutter_local_notifications package for better local notifications
    // For now, we'll just show a snackbar
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    // Navigate based on notification type
    final data = message.data;
    if (data['type'] == 'order_update') {
      // Navigate to order history
    } else if (data['type'] == 'new_product') {
      // Navigate to home
    } else if (data['type'] == 'promotion') {
      // Navigate to promotions
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        // Store notification in Firestore
        await _firestore.collection('notifications').add({
          'userId': userId,
          'title': title,
          'body': body,
          'type': type,
          'data': data ?? {},
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // In a real app, you would send this to your backend server
        // which would then send the FCM message
      }
    } catch (e) {
      // Error sending notification
    }
  }

  // Send notification to all users
  static Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all user FCM tokens
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var doc in usersSnapshot.docs) {
        final fcmToken = doc.data()['fcmToken'];
        if (fcmToken != null) {
          await sendNotificationToUser(
            userId: doc.id,
            title: title,
            body: body,
            type: type,
            data: data,
          );
        }
      }
    } catch (e) {
      // Error sending notification to all users
    }
  }

  // Get user notifications
  static Stream<QuerySnapshot> getUserNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Get unread notification count
  static Stream<int> getUnreadNotificationCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
} 