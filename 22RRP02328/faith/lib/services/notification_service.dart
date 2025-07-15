import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../utils/constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Skip initialization on web to avoid Firebase Messaging issues
    if (kIsWeb) {
      return;
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Show success notification
  static void showSuccessNotification({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (kIsWeb) {
      // On web, show GetX snackbar
      Get.snackbar(
        title,
        message,
        backgroundColor: const Color(AppColors.successColor),
        colorText: Colors.white,
        duration: duration,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } else {
      // On mobile, show local notification
      showLocalNotification(
        title: title,
        body: message,
      );
    }
  }

  // Show error notification
  static void showErrorNotification({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (kIsWeb) {
      // On web, show GetX snackbar
      Get.snackbar(
        title,
        message,
        backgroundColor: const Color(AppColors.errorColor),
        colorText: Colors.white,
        duration: duration,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } else {
      // On mobile, show local notification
      showLocalNotification(
        title: title,
        body: message,
      );
    }
  }

  // Show info notification
  static void showInfoNotification({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (kIsWeb) {
      // On web, show GetX snackbar
      Get.snackbar(
        title,
        message,
        backgroundColor: const Color(AppColors.primaryColor),
        colorText: Colors.white,
        duration: duration,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.info, color: Colors.white),
      );
    } else {
      // On mobile, show local notification
      showLocalNotification(
        title: title,
        body: message,
      );
    }
  }

  // Show warning notification
  static void showWarningNotification({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (kIsWeb) {
      // On web, show GetX snackbar
      Get.snackbar(
        title,
        message,
        backgroundColor: const Color(AppColors.warningColor),
        colorText: Colors.white,
        duration: duration,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.warning, color: Colors.white),
      );
    } else {
      // On mobile, show local notification
      showLocalNotification(
        title: title,
        body: message,
      );
    }
  }

  // Show local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      // On web, just log the notification
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'faith_notifications',
      'Faith Notifications',
      channelDescription: 'Notifications for Faith app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle local notification tap
    // Navigate to appropriate screen based on payload
  }

  // Send notification to specific user (mock implementation)
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Mock implementation - just show local notification
    await showLocalNotification(
      title: title,
      body: body,
      payload: data?.toString(),
    );
  }

  static Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final query = await FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs
        .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  static Future<List<NotificationModel>> getAllNotifications() async {
    final query = await FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs
        .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  // Mark notification as read (mock implementation)
  static Future<void> markNotificationAsRead(String notificationId) async {
    // Mock implementation
  }

  // Delete notification (mock implementation)
  static Future<void> deleteNotification(String notificationId) async {
    // Mock implementation
  }

  static Future<void> saveNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    final notification = {
      'userId': userId,
      'title': title,
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    };
    await FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .add(notification);
  }
} 