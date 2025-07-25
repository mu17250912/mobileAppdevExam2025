import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:hive/hive.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: null,
      macOS: null,
      linux: null,
    );
    await _notifications.initialize(initializationSettings);
    _initialized = true;
  }

  static Future<void> saveNotificationToFirestore({
    required String title,
    required String body,
    required String type,
  }) async {
    // This function is no longer used as Firestore is removed.
    // Keeping it for now to avoid breaking existing calls, but it will do nothing.
  }

  static Future<void> _saveToHive({required String title, required String body, required String type}) async {
    final box = await Hive.openBox('notifications');
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    });
  }

  static Future<void> showAdminChangeNotification({
    required String title,
    required String body,
    required String changeType,
  }) async {
    await initialize();
    await _saveToHive(title: title, body: body, type: changeType);
    // This function is no longer used as Firestore is removed.
    // Keeping it for now to avoid breaking existing calls, but it will do nothing.

    IconData iconData;
    Color iconColor;
    String channelId;
    String channelName;

    switch (changeType) {
      case 'disease_added':
        iconData = Icons.bug_report;
        iconColor = Colors.red;
        channelId = 'admin_disease_channel';
        channelName = 'Disease Updates';
        break;
      case 'tip_added':
        iconData = Icons.agriculture;
        iconColor = Colors.green;
        channelId = 'admin_tips_channel';
        channelName = 'Tips Updates';
        break;
      case 'price_updated':
        iconData = Icons.attach_money;
        iconColor = Colors.orange;
        channelId = 'admin_prices_channel';
        channelName = 'Price Updates';
        break;
      case 'weather_alert':
        iconData = Icons.cloud;
        iconColor = Colors.blue;
        channelId = 'admin_weather_channel';
        channelName = 'Weather Alerts';
        break;
      case 'premium_feature':
        iconData = Icons.star;
        iconColor = Colors.amber;
        channelId = 'admin_premium_channel';
        channelName = 'Premium Updates';
        break;
      default:
        iconData = Icons.admin_panel_settings;
        iconColor = Colors.purple;
        channelId = 'admin_general_channel';
        channelName = 'Admin Updates';
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'admin_channel',
      'Admin Notifications',
      channelDescription: 'Notifications when admin makes changes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static Future<void> showPremiumActivatedNotification() async {
    await initialize();
    await _saveToHive(title: '🎉 Premium Activated!', body: 'Welcome to InfoFarmer Premium! You now have access to all premium features.', type: 'premium_feature');
    // This function is no longer used as Firestore is removed.
    // Keeping it for now to avoid breaking existing calls, but it will do nothing.
  }

  static Future<void> showLoginNotification() async {
    await initialize();
    await _saveToHive(title: 'Welcome to InfoFarmer!', body: 'You have successfully logged in.', type: 'login');
    // This function is no longer used as Firestore is removed.
    // Keeping it for now to avoid breaking existing calls, but it will do nothing.
  }

  static Future<void> showWeatherAlertNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    await _saveToHive(title: title, body: body, type: 'weather_alert');
    // This function is no longer used as Firestore is removed.
    // Keeping it for now to avoid breaking existing calls, but it will do nothing.
  }

  static Future<void> showDiseaseDetectionNotification({
    required String diseaseName,
    required double confidence,
  }) async {
    await initialize();
    await _saveToHive(title: '🔍 Disease Detected', body: 'Detected: $diseaseName (${(confidence * 100).toStringAsFixed(1)}% confidence)', type: 'ai_detection');
    // This function is no longer used as Firestore is removed.
    // Keeping it for now to avoid breaking existing calls, but it will do nothing.
  }

  static Future<void> showDiseaseInfoNotification({
    required String diseaseName,
    required String infoUrl,
    required bool isSubscribed,
  }) async {
    await initialize();
    String body = isSubscribed
        ? 'Learn more about ' + diseaseName + ': ' + infoUrl
        : 'Subscribe to access more information about ' + diseaseName + '.';
    await _saveToHive(title: 'Disease Info: ' + diseaseName, body: body, type: 'disease_info');
    // This function is no longer used as Firestore is removed.
    // Keeping it for now to avoid breaking existing calls, but it will do nothing.

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'disease_info_channel',
      'Disease Info',
      channelDescription: 'Disease information notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Disease Info: ' + diseaseName,
      body,
      platformChannelSpecifics,
    );
  }
} 