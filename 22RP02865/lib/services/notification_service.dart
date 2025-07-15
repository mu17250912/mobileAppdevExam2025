import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/task.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Future<void> scheduleTaskNotification(Task task) async {
    if (!task.hasReminder) return;

    final androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      channelDescription: 'Notifications for study tasks',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      enableVibration: true,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule notification based on task's reminder settings
    final scheduledTime = task.dateTime.subtract(Duration(minutes: task.reminderMinutes));
    
    if (scheduledTime.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        task.hashCode,
        'Study Task Reminder',
        'Time to study:  [${task.subject}',
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: 'task_reminder_${task.id}',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      print('NotificationService: Scheduled reminder for task "${task.subject}" at ${scheduledTime.toString()}');
    } else {
      print('NotificationService: Cannot schedule reminder for past time');
    }
  }

  Future<void> scheduleMultipleReminders(Task task) async {
    if (!task.hasReminder) return;

    // Schedule multiple reminders for important tasks
    final reminderTimes = [5, 15, 30]; // minutes before
    final taskId = task.hashCode;
    
    for (int i = 0; i < reminderTimes.length; i++) {
      final minutes = reminderTimes[i];
      final scheduledTime = task.dateTime.subtract(Duration(minutes: minutes));
      
      if (scheduledTime.isAfter(DateTime.now())) {
        final androidDetails = AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          channelDescription: 'Notifications for study tasks',
          importance: minutes <= 5 ? Importance.max : Importance.high,
          priority: minutes <= 5 ? Priority.max : Priority.high,
          category: AndroidNotificationCategory.reminder,
          enableVibration: true,
          playSound: true,
        );

        final iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        
        final details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.zonedSchedule(
          taskId + i, // Unique ID for each reminder
          'Study Task Reminder',
          minutes <= 5 
              ? 'URGENT: ${task.subject} starts in $minutes minutes!'
              : 'Reminder: ${task.subject} starts in $minutes minutes',
          tz.TZDateTime.from(scheduledTime, tz.local),
          details,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllTaskNotifications(Task task) async {
    // Cancel all reminders for a specific task
    final taskId = task.hashCode;
    for (int i = 0; i < 3; i++) {
      await _notifications.cancel(taskId + i);
    }
    await _notifications.cancel(taskId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'immediate_channel',
      'Immediate Notifications',
      channelDescription: 'Immediate notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails();
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required List<int> days,
  }) async {
            final androidDetails = AndroidNotificationDetails(
          'repeating_channel',
          'Repeating Notifications',
          channelDescription: 'Repeating notifications',
          importance: Importance.high,
          priority: Priority.high,
        );

    final iosDetails = DarwinNotificationDetails();
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    for (final day in days) {
      await _notifications.zonedSchedule(
        id + day,
        title,
        body,
        _nextInstanceOfTime(time, day),
        details,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time, int dayOfWeek) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute, 0);
    
    while (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
} 