import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize(BuildContext context) async {
    // Request permissions (especially important for iOS/macOS)
    await _messaging.requestPermission();

    // Get FCM token
    final token = await _messaging.getToken();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await _firestore.collection('users').doc(user.uid).update({'fcmToken': token});
    }

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final snackBar = SnackBar(content: Text(message.notification!.title ?? 'Notification'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });
  }

  // Create admin notification
  static Future<void> createAdminNotification({
    required String type,
    required String userName,
    required String action,
    double? amount,
    String? userId,
  }) async {
    try {
      await _firestore.collection('admin_notifications').add({
        'type': type,
        'userName': userName,
        'action': action,
        'amount': amount,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error creating admin notification: $e');
    }
  }

  // Create notification when user places a bet
  static Future<void> notifyBetPlaced({
    required String userName,
    required String userId,
    required double wager,
    required int selectionsCount,
  }) async {
    await createAdminNotification(
      type: 'bet',
      userName: userName,
      action: 'placed a bet with $selectionsCount selections',
      amount: wager,
      userId: userId,
    );
  }

  // Create notification when bet is approved/rejected
  static Future<void> notifyBetStatusChanged({
    required String userName,
    required String userId,
    required String status,
    required double wager,
  }) async {
    await createAdminNotification(
      type: 'bet',
      userName: userName,
      action: 'bet was $status',
      amount: wager,
      userId: userId,
    );
  }

  // Create notification for deposits
  static Future<void> notifyDeposit({
    required String userName,
    required String userId,
    required double amount,
  }) async {
    await createAdminNotification(
      type: 'deposit',
      userName: userName,
      action: 'made a deposit',
      amount: amount,
      userId: userId,
    );
  }

  // Create notification for withdrawals
  static Future<void> notifyWithdrawal({
    required String userName,
    required String userId,
    required double amount,
  }) async {
    await createAdminNotification(
      type: 'withdraw',
      userName: userName,
      action: 'requested a withdrawal',
      amount: amount,
      userId: userId,
    );
  }

  // Create notification for profile updates
  static Future<void> notifyProfileUpdate({
    required String userName,
    required String userId,
    required String updateType,
  }) async {
    await createAdminNotification(
      type: 'profile',
      userName: userName,
      action: 'updated their $updateType',
      userId: userId,
    );
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('admin_notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadNotificationCount() {
    return _firestore
        .collection('admin_notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('admin_notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore.collection('admin_notifications').get();
      
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
} 