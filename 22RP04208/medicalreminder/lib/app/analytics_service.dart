import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  static Future<void> logMedicationAdded(String name) async {
    await _analytics.logEvent(name: 'medication_added', parameters: {'name': name});
    await logSessionEvent('add_medication', {'name': name});
  }

  static Future<void> logMedicationRemoved(String name) async {
    await _analytics.logEvent(name: 'medication_removed', parameters: {'name': name});
    await logSessionEvent('remove_medication', {'name': name});
  }

  static Future<void> logMedicationUpdated(String name, Map<String, dynamic> changes) async {
    await _analytics.logEvent(name: 'medication_updated', parameters: {'name': name, ...changes});
    await logSessionEvent('update_medication', {'name': name, ...changes});
  }

  static Future<void> logReminderTriggered(String name) async {
    await _analytics.logEvent(name: 'reminder_triggered', parameters: {'name': name});
    await logSessionEvent('reminder_triggered', {'name': name});
  }

  static Future<void> logProfileOpened() async {
    await _analytics.logEvent(name: 'profile_opened');
  }

  static Future<void> logSettingsOpened() async {
    await _analytics.logEvent(name: 'settings_opened');
  }

  static Future<void> logUpgradeToPremium() async {
    await _analytics.logEvent(name: 'upgrade_to_premium');
    await logSessionEvent('upgrade_to_premium', {});
  }

  static Future<void> logSessionEvent(String action, Map<String, dynamic> details) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('session_logs')
        .add({
          'action': action,
          'details': details,
          'timestamp': DateTime.now().toIso8601String(),
        });
  }
} 