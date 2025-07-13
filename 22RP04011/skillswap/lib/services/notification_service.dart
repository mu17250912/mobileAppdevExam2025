import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Get token
    String? token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');
  }

  Future<void> _showNotification(RemoteMessage message) async {
    // For now, just print the notification
    // In a real app, you would show a local notification or update the UI
    debugPrint('Received notification: ${message.notification?.title}');
    debugPrint('Notification body: ${message.notification?.body}');
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> onTokenRefresh() async {
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      debugPrint('FCM Token refreshed: $token');
      // Here you would typically update the token in your backend
    });
  }
}
