import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await _notifications.initialize(settings);
  }

  static Future<void> showMotivationNotification(String quote) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'motivation_channel',
          'Motivation',
          channelDescription: 'Daily motivational reminders',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _notifications.show(0, 'Stay Motivated!', quote, details);
  }
}
