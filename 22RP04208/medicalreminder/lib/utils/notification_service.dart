import 'package:flutter/foundation.dart';

class NotificationService {
  static void scheduleNotification(DateTime dateTime, String body) {
    // Stub: Implement real notification scheduling for mobile
    if (kIsWeb && webReminderCallback != null) {
      webReminderCallback!(dateTime, body);
    }
  }

  static void Function(DateTime, String)? webReminderCallback;

  static Future<void> initialize({void Function(DateTime, String)? onWebReminder}) async {
    if (kIsWeb && onWebReminder != null) {
      webReminderCallback = onWebReminder;
    }
    // Stub: Add real initialization for mobile if needed
  }
} 