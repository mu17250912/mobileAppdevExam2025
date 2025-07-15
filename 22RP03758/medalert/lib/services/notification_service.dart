import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'voice_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final VoiceService _voiceService = VoiceService();
  
  bool _isInitialized = false;

  // Notification channels
  static const String _medicationChannelId = 'medication_reminders';
  static const String _reReminderChannelId = 'medication_re_reminders';
  static const String _caregiverChannelId = 'caregiver_notifications';

  Future<void> initialize() async {
    try {
      debugPrint('Initializing NotificationService...');
      
      // Check if running on web
      if (kIsWeb) {
        debugPrint('Running on web platform - notifications not supported');
        _isInitialized = false;
        return;
      }
      
      // Initialize timezone
      tz.initializeTimeZones();
      debugPrint('Timezone initialized');

      // Initialize notifications with platform-specific handling
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      debugPrint('Notifications initialized: $initialized');

      // Only create channels on Android
      if (initialized != null) {
        await _createNotificationChannels();
        _isInitialized = true;
        debugPrint('NotificationService initialization completed');
      } else {
        debugPrint('NotificationService initialization failed');
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
      _isInitialized = false;
    }
  }

  Future<void> _createNotificationChannels() async {
    // Medication reminder channel
    const medicationChannel = AndroidNotificationChannel(
      _medicationChannelId,
      'Medication Reminders',
      description: 'Notifications for medication reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Re-reminder channel
    const reReminderChannel = AndroidNotificationChannel(
      _reReminderChannelId,
      'Medication Re-Reminders',
      description: 'Notifications for missed medication reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Caregiver notification channel
    const caregiverChannel = AndroidNotificationChannel(
      _caregiverChannelId,
      'Caregiver Notifications',
      description: 'Notifications for caregiver alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(medicationChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reReminderChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(caregiverChannel);
  }

  void _onNotificationTapped(NotificationResponse response) async {
    // Handle notification tap
    final payload = response.payload;
    if (payload != null) {
      final data = json.decode(payload);
      final action = data['action'];
      final medicationId = data['medicationId'];

      switch (action) {
        case 'mark_taken':
          await _markMedicationAsTaken(medicationId);
          break;
        case 'view_details':
          // Navigate to medication details
          break;
      }
    }
  }

  Future<void> _markMedicationAsTaken(String medicationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get medication details for voice feedback
      final medicationDoc = await _firestore
          .collection('medications')
          .doc(medicationId)
          .get();
      
      final medication = medicationDoc.data();
      final medicationName = medication?['name'] ?? 'medication';

      // Record medication taken
      await _firestore.collection('medication_logs').add({
        'medicationId': medicationId,
        'patientId': user.uid,
        'takenAt': FieldValue.serverTimestamp(),
        'status': 'taken',
      });

      // Cancel any pending re-reminders for this medication
      await _cancelReReminders(medicationId);

      // Provide voice feedback
      try {
        await _voiceService.speak('$medicationName marked as taken. Good job!');
      } catch (e) {
        debugPrint('Error providing voice feedback: $e');
      }

      // Show success message (you can implement this with a global snackbar)
      debugPrint('Medication marked as taken: $medicationId');
    } catch (e) {
      debugPrint('Error marking medication as taken: $e');
    }
  }

  Future<void> scheduleMedicationReminders() async {
    try {
      debugPrint('Starting to schedule medication reminders...');
      
      // Check if running on web
      if (kIsWeb) {
        debugPrint('Running on web platform - notifications not supported');
        return;
      }
      
      if (!_isInitialized) {
        debugPrint('NotificationService not initialized. Initializing now...');
        await initialize();
      }
      
      if (!_isInitialized) {
        debugPrint('NotificationService still not initialized after retry. Skipping reminder scheduling.');
        return;
      }
      
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return;
      }

      debugPrint('User authenticated: ${user.uid}');

      // Cancel existing reminders
      await _cancelAllReminders();
      debugPrint('Cancelled existing reminders');

      // Get user's medications
      final medicationsSnapshot = await _firestore
          .collection('medications')
          .where('patientId', isEqualTo: user.uid)
          .get();

      debugPrint('Found ${medicationsSnapshot.docs.length} medications');

      for (final doc in medicationsSnapshot.docs) {
        final medication = doc.data();
        final medicationId = doc.id;
        final time = medication['time'] as String?;
        final frequency = medication['frequency'] as String?;

        debugPrint('Processing medication: ${medication['name']} at $time with frequency $frequency');

        if (time != null && frequency != null) {
          await _scheduleMedicationReminder(medicationId, medication, time, frequency);
        } else {
          debugPrint('Skipping medication ${medication['name']} - missing time or frequency');
        }
      }
      
      debugPrint('Medication reminder scheduling completed');
    } catch (e) {
      debugPrint('Error scheduling medication reminders: $e');
      // Don't rethrow, just log the error
    }
  }

  Future<void> _scheduleMedicationReminder(
    String medicationId,
    Map<String, dynamic> medication,
    String time,
    String frequency,
  ) async {
    try {
      // Parse multiple times
      final timeStrings = time.split(',').map((t) => t.trim()).toList();
      
      for (int timeIndex = 0; timeIndex < timeStrings.length; timeIndex++) {
        final timeString = timeStrings[timeIndex];
        final timeParts = timeString.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // Calculate next occurrence
        final now = tz.TZDateTime.now(tz.local);
        var scheduledTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // If time has passed today, schedule for tomorrow
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        // Create unique notification ID for each time
        final notificationId = _getNotificationId(medicationId, 'reminder') + timeIndex;

        // Schedule the reminder
        await _notifications.zonedSchedule(
          notificationId,
          'Medication Reminder',
          'Time to take ${medication['name']} - ${medication['dosage']}',
          scheduledTime,
          _getNotificationDetails(medicationId, medication, 'reminder'),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: json.encode({
            'action': 'mark_taken',
            'medicationId': medicationId,
            'type': 'reminder',
            'timeIndex': timeIndex,
          }),
        );

        // Schedule re-reminder after 30 minutes
        final reReminderTime = scheduledTime.add(const Duration(minutes: 30));
        await _notifications.zonedSchedule(
          notificationId + 1000,
          'Medication Reminder - Overdue',
          'You haven\'t taken ${medication['name']} yet. Please take it now.',
          reReminderTime,
          _getNotificationDetails(medicationId, medication, 're_reminder'),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: json.encode({
            'action': 'mark_taken',
            'medicationId': medicationId,
            'type': 're_reminder',
            'timeIndex': timeIndex,
          }),
        );

        // Schedule caregiver notification after 1 hour
        final caregiverTime = scheduledTime.add(const Duration(hours: 1));
        await _notifications.zonedSchedule(
          notificationId + 2000,
          'Patient Medication Alert',
          'Patient hasn\'t taken ${medication['name']} for over an hour.',
          caregiverTime,
          _getNotificationDetails(medicationId, medication, 'caregiver'),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: json.encode({
            'action': 'view_details',
            'medicationId': medicationId,
            'type': 'caregiver',
            'timeIndex': timeIndex,
          }),
        );
      }

      debugPrint('Scheduled reminders for medication: ${medication['name']} at ${timeStrings.length} times');
    } catch (e) {
      debugPrint('Error scheduling reminder for medication $medicationId: $e');
    }
  }

  NotificationDetails _getNotificationDetails(
    String medicationId,
    Map<String, dynamic> medication,
    String type,
  ) {
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(type),
      _getChannelName(type),
      channelDescription: _getChannelDescription(type),
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      actions: [
        const AndroidNotificationAction(
          'mark_taken',
          'Mark as Taken',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'view_details',
          'View Details',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  String _getChannelId(String type) {
    switch (type) {
      case 'reminder':
        return _medicationChannelId;
      case 're_reminder':
        return _reReminderChannelId;
      case 'caregiver':
        return _caregiverChannelId;
      default:
        return _medicationChannelId;
    }
  }

  String _getChannelName(String type) {
    switch (type) {
      case 'reminder':
        return 'Medication Reminders';
      case 're_reminder':
        return 'Medication Re-Reminders';
      case 'caregiver':
        return 'Caregiver Notifications';
      default:
        return 'Medication Reminders';
    }
  }

  String _getChannelDescription(String type) {
    switch (type) {
      case 'reminder':
        return 'Notifications for medication reminders';
      case 're_reminder':
        return 'Notifications for missed medication reminders';
      case 'caregiver':
        return 'Notifications for caregiver alerts';
      default:
        return 'Notifications for medication reminders';
    }
  }

  int _getNotificationId(String medicationId, String type) {
    // Create unique notification ID based on medication ID and type
    final baseId = medicationId.hashCode;
    switch (type) {
      case 'reminder':
        return baseId;
      case 're_reminder':
        return baseId + 1000;
      case 'caregiver':
        return baseId + 2000;
      default:
        return baseId;
    }
  }

  Future<void> _cancelReReminders(String medicationId) async {
    await _notifications.cancel(_getNotificationId(medicationId, 're_reminder'));
    await _notifications.cancel(_getNotificationId(medicationId, 'caregiver'));
  }

  Future<void> _cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelMedicationReminders(String medicationId) async {
    // Cancel all possible notification IDs for this medication
    // We'll cancel a range of IDs to cover multiple times
    for (int i = 0; i < 10; i++) { // Support up to 10 times per medication
      await _notifications.cancel(_getNotificationId(medicationId, 'reminder') + i);
      await _notifications.cancel(_getNotificationId(medicationId, 're_reminder') + i);
      await _notifications.cancel(_getNotificationId(medicationId, 'caregiver') + i);
    }
  }

  Future<void> requestPermissions() async {
    // Check if running on web
    if (kIsWeb) {
      debugPrint('Running on web platform - notifications not supported');
      return;
    }
    
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized. Initializing now...');
      await initialize();
    }
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Test method to check if notifications are working
  Future<void> testNotification() async {
    try {
      // Check if running on web
      if (kIsWeb) {
        debugPrint('Running on web platform - test notification not supported');
        return;
      }
      
      if (!_isInitialized) {
        debugPrint('NotificationService not initialized for test');
        return;
      }
      
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notification channel',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        999,
        'Test Notification',
        'This is a test notification',
        notificationDetails,
      );
      
      debugPrint('Test notification sent successfully');
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }
} 