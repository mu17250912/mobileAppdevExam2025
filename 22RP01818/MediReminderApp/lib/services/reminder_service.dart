import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:async/async.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  // Add a reminder to a medication
  Future<void> addReminder(
    String medId,
    Map<String, dynamic> reminderData,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medId)
        .collection('reminders')
        .add(reminderData);
  }

  // Get reminders for a medication
  Stream<QuerySnapshot> getReminders(String medId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medId)
        .collection('reminders')
        .snapshots();
  }

  // Update a reminder
  Future<void> updateReminder(
    String medId,
    String reminderId,
    Map<String, dynamic> reminderData,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medId)
        .collection('reminders')
        .doc(reminderId)
        .update(reminderData);
  }

  // Delete a reminder
  Future<void> deleteReminder(String medId, String reminderId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medId)
        .collection('reminders')
        .doc(reminderId)
        .delete();
  }

  // Get reminders for the coming hour for a medication
  Stream<QuerySnapshot> getUpcomingReminders(String medId) {
    final now = Timestamp.now();
    final oneHourLater = Timestamp.fromDate(
      DateTime.now().add(Duration(hours: 1)),
    );
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medId)
        .collection('reminders')
        .where('reminderTime', isGreaterThanOrEqualTo: now)
        .where('reminderTime', isLessThanOrEqualTo: oneHourLater)
        .snapshots();
  }

  // Get all upcoming reminders for all medications for the current user
  Stream<List<Map<String, dynamic>>> getAllUpcomingReminders() async* {
    yield []; // Yield immediately so UI doesn't hang
    final userMedications = await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .get();
    // Listen to all reminders in real time
    final List<Stream<QuerySnapshot>> reminderStreams = userMedications.docs
        .map((med) {
          return _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .doc(med.id)
              .collection('reminders')
              .where('status', whereIn: ['pending', 'snoozed', 'read'])
              .snapshots();
        })
        .toList();
    await for (final snapshots in StreamZip(reminderStreams)) {
      List<Map<String, dynamic>> result = [];
      for (int i = 0; i < snapshots.length; i++) {
        final med = userMedications.docs[i];
        final remindersSnapshot = snapshots[i];
        for (var reminder in remindersSnapshot.docs) {
          final data = reminder.data() as Map<String, dynamic>?;
          result.add({
            'medName': med['name'],
            'reminderTime': (reminder['reminderTime'] as Timestamp).toDate(),
            'status': reminder['status'],
            'medId': med.id,
            'reminderId': reminder.id,
            'read': data != null && data['read'] != null ? data['read'] : false,
          });
        }
      }
      // Sort reminders by reminderTime ascending
      result.sort(
        (a, b) => (a['reminderTime'] as DateTime).compareTo(
          b['reminderTime'] as DateTime,
        ),
      );
      // Convert reminderTime back to string for UI if needed
      yield result
          .map(
            (reminder) => {
              ...reminder,
              'reminderTime': reminder['reminderTime'].toString(),
            },
          )
          .toList();
    }
  }

  // Mark all snoozed reminders as read for the current user
  Future<void> markAllSnoozedRemindersAsRead() async {
    final userMedications = await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .get();
    for (final med in userMedications.docs) {
      final snoozedReminders = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .doc(med.id)
          .collection('reminders')
          .where('status', isEqualTo: 'snoozed')
          .where('read', isEqualTo: false)
          .get();
      for (final reminder in snoozedReminders.docs) {
        await reminder.reference.update({'read': true});
      }
    }
  }

  // Mark a single reminder as snoozed (after snoozing)
  Future<void> markReminderAsSnoozed(String medId, String reminderId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medId)
        .collection('reminders')
        .doc(reminderId)
        .update({'status': 'snoozed', 'read': false});
  }

  // Mark a single reminder as read (after user reads notification)
  Future<void> markReminderAsRead(String medId, String reminderId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medId)
        .collection('reminders')
        .doc(reminderId)
        .update({'status': 'read', 'read': true});
  }
}
