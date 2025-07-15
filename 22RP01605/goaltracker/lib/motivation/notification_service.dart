import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );
      await _notifications.initialize(settings);

      // Request notification permission for Android 13+
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _requestNotificationPermission();
      }
    } catch (e) {
      print('Notification service initialization error: $e');
    }
  }

  static Future<void> _requestNotificationPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation
            .requestNotificationsPermission();
        print('Notification permission granted: $granted');
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  static Future<void> showMotivationNotification(String quote) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'motivation_channel',
            'Motivation',
            channelDescription: 'Daily motivational reminders',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.show(0, 'Stay Motivated!', quote, details);
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }
}
