import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    if (kIsWeb) {
      print('Notification service initialized (web mode - notifications disabled)');
    } else {
      print('Notification service initialized (mobile mode)');
    }
  }

  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (kIsWeb) {
      print('Web: Would schedule notification: $title for ${scheduledDate.toString()}');
      return;
    }
    
    // For mobile platforms, this would integrate with flutter_local_notifications
    print('Mobile: Would schedule notification: $title for ${scheduledDate.toString()}');
  }

  Future<void> scheduleReminderWithAdvance({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
    int advanceDays = 1,
    String? payload,
  }) async {
    if (kIsWeb) {
      print('Web: Would schedule advance notification: $title for ${dueDate.toString()}');
      return;
    }
    
    final reminderDate = dueDate.subtract(Duration(days: advanceDays));
    
    if (reminderDate.isAfter(DateTime.now())) {
      await scheduleReminderNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: reminderDate,
        payload: payload,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) {
      print('Web: Would cancel notification with id: $id');
      return;
    }
    
    print('Mobile: Would cancel notification with id: $id');
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      print('Web: Would cancel all notifications');
      return;
    }
    
    print('Mobile: Would cancel all notifications');
  }

  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    if (kIsWeb) {
      print('Web: Would get pending notifications');
      return [];
    }
    
    print('Mobile: Would get pending notifications');
    return [];
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      // On web, show a snackbar instead of a notification
      print('Web: Showing snackbar notification: $title - $body');
      return;
    }
    
    print('Mobile: Would show immediate notification: $title - $body');
  }

  // Web-specific method to show notifications as snackbars
  void showWebNotification(BuildContext context, String title, String body) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(body),
            ],
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
} 