// Temporary stub notification service to avoid compilation issues
// TODO: Re-implement with compatible flutter_local_notifications version

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    // Stub implementation
    print('Notification service initialized (stub)');
  }

  Future<void> showAppointmentRequestNotification({
    required String doctorName,
    required String patientName,
    required String date,
    required String time,
    required String appointmentId,
  }) async {
    // Stub implementation - just save to Firestore
    await saveNotificationToFirestore(
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      title: 'New Appointment Request',
      message: '$patientName has requested an appointment with $doctorName on $date at $time',
      appointmentId: appointmentId,
    );
  }

  Future<void> showAppointmentResponseNotification({
    required String patientName,
    required String doctorName,
    required String date,
    required String time,
    required String status,
    required String appointmentId,
  }) async {
    // Stub implementation - just save to Firestore
    final String title = status == 'approved' 
        ? 'Appointment Approved' 
        : 'Appointment Rejected';
    
    final String message = status == 'approved'
        ? 'Your appointment with $doctorName on $date at $time has been approved!'
        : 'Your appointment with $doctorName on $date at $time has been rejected.';

    await saveNotificationToFirestore(
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      title: title,
      message: message,
      appointmentId: appointmentId,
      status: status,
    );
  }

  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentDateTime,
    required int minutesBefore,
  }) async {
    // Stub implementation - just save to Firestore
    final scheduledDate = appointmentDateTime.subtract(Duration(minutes: minutesBefore));
    
    if (scheduledDate.isBefore(DateTime.now())) {
      return; // Don't schedule if the time has already passed
    }

    final String title = minutesBefore == 10 
        ? 'Appointment in 10 minutes' 
        : 'Appointment in 5 minutes';
    
    final String message = 'You have an appointment with $doctorName in $minutesBefore minutes.';

    await saveNotificationToFirestore(
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      title: title,
      message: message,
      appointmentId: appointmentId,
    );
  }

  Future<void> cancelAppointmentReminders(String appointmentId) async {
    // Stub implementation
    print('Cancelled reminders for appointment: $appointmentId');
  }

  Future<void> showGeneralNotification({
    required String title,
    required String message,
    String? payload,
  }) async {
    // Stub implementation - just save to Firestore
    await saveNotificationToFirestore(
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      title: title,
      message: message,
    );
  }

  Future<void> saveNotificationToFirestore({
    required String userId,
    required String title,
    required String message,
    String? appointmentId,
    String? status,
  }) async {
    if (userId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'appointmentId': appointmentId,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
  }

  Future<List<dynamic>> getPendingNotifications() async {
    // Stub implementation
    return [];
  }

  Future<void> cancelAllNotifications() async {
    // Stub implementation
    print('Cancelled all notifications');
  }
} 