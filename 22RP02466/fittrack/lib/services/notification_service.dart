import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:math';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      defaultPresentSound: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;
  }

  // Schedule BMI check reminder
  static Future<void> scheduleBMIReminder({int hour = 9, int minute = 0}) async {
    await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bmi_reminders',
      'BMI Reminders',
      channelDescription: 'Reminders to check your BMI regularly',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      1,
      'Time to Check Your BMI! 📊',
      'Track your health progress with a quick BMI measurement.',
      _nextInstanceOf(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Schedule daily health tip
  static Future<void> scheduleHealthTip() async {
    await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'health_tips',
      'Health Tips',
      channelDescription: 'Daily health and wellness tips',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      2,
      'Daily Health Tip 💡',
      _getRandomHealthTip(),
      _nextInstanceOf(10, 0), // 10:00 AM
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Show health alert for significant BMI changes
  static Future<void> showHealthAlert(String title, String body) async {
    await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'health_alerts',
      'Health Alerts',
      channelDescription: 'Important health notifications',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFE91E63), // Pink color
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      Random().nextInt(1000),
      title,
      body,
      details,
    );
  }

  // Check for significant BMI changes and alert user
  static void checkForSignificantChanges(double previousBMI, double currentBMI) {
    final difference = (currentBMI - previousBMI).abs();
    final percentageChange = (difference / previousBMI) * 100;

    if (percentageChange >= 5) { // 5% or more change
      String alertTitle = 'BMI Change Alert ⚠️';
      String alertBody = '';

      if (currentBMI > previousBMI) {
        alertBody = 'Your BMI has increased by ${percentageChange.toStringAsFixed(1)}%. Consider reviewing your health habits.';
      } else {
        alertBody = 'Your BMI has decreased by ${percentageChange.toStringAsFixed(1)}%. Great progress! Keep up the good work!';
      }

      showHealthAlert(alertTitle, alertBody);
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Schedule premium notification
  static Future<void> schedulePremiumNotification() async {
    await initialize();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'premium_notifications',
      'Premium Notifications',
      channelDescription: 'Exclusive tips and motivational messages for premium users',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.zonedSchedule(
      99,
      '🌟 Premium Tip',
      'Here is your exclusive premium tip: Stay consistent and track your progress daily!',
      _nextInstanceOf(8, 0), // 8:00 AM
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Helper method to get next instance of time
  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // Get random health tip
  static String _getRandomHealthTip() {
    final tips = [
      'Stay hydrated! Drink 8 glasses of water daily 💧',
      'Take a 10-minute walk to boost your energy 🚶‍♀️',
      'Include protein in every meal for better health 🥩',
      'Get 7-8 hours of sleep for optimal health 😴',
      'Practice portion control for balanced nutrition 🍽️',
      'Add more vegetables to your diet 🥗',
      'Exercise for at least 30 minutes daily 🏃‍♀️',
      'Limit processed foods for better health 🥑',
      'Practice mindful eating habits 🧘‍♀️',
      'Stay active throughout the day 💪',
    ];
    
    return tips[Random().nextInt(tips.length)];
  }

  // Show immediate notification (for testing)
  static Future<void> showTestNotification() async {
    await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Test Notification',
      'This is a test notification from FitTrack BMI',
      details,
    );
  }
} 