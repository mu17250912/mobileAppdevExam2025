import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/reminder_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class ReminderScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const ReminderScreen({super.key, this.onBackToHome});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  Timer? _timer;
  final ReminderService _reminderService = ReminderService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    // Check every second for reminders to snooze
    _timer = Timer.periodic(
      Duration(seconds: 1),
      (_) => _autoSnoozeReminders(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _scheduleSnoozeNotification(
    String medName,
    DateTime newTime,
  ) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      newTime.millisecondsSinceEpoch ~/ 1000, // unique id
      'Medication Reminder',
      'It\'s time to take your medication: $medName',
      tz.TZDateTime.from(newTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mediremind_channel',
          'MediRemind Notifications',
          channelDescription: 'Reminders for medications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _autoSnoozeReminders() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    print('[SNOOZE DEBUG] Checking reminders at: $now');
    final medsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('medications')
        .get();

    for (var med in medsSnapshot.docs) {
      final remindersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('medications')
          .doc(med.id)
          .collection('reminders')
          .where('reminderTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('status', isEqualTo: 'pending')
          .get();

      for (var reminder in remindersSnapshot.docs) {
        // Play alert sound when reminder is due using audioplayers
        try {
          await _audioPlayer.stop(); // Stop any currently playing sound
          await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
        } catch (e) {
          // Error playing sound
        }
        // Auto-snooze: set status to 'snoozed' and add 20 seconds
        final newTime = DateTime.now().add(Duration(seconds: 20));
        await reminder.reference.update({
          'status': 'snoozed',
          'reminderTime': Timestamp.fromDate(newTime),
        });
        // Schedule local notification for snoozed reminder
        await flutterLocalNotificationsPlugin.zonedSchedule(
          newTime.millisecondsSinceEpoch ~/ 1000, // unique id
          'Medication Reminder',
          'It\'s time to take your medication: ${med['name']}',
          tz.TZDateTime.from(newTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'mediremind_channel',
              'MediRemind Notifications',
              channelDescription: 'Reminders for medications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
    // Removed duplicate and outdated _scheduleSnoozeNotification
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6EDFF),
      appBar: AppBar(
        title: Text('MediRemind'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onBackToHome ?? () {},
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _reminderService.getAllUpcomingReminders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading reminders: \\${snapshot.error}'),
            );
          }
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final upcomingReminders = snapshot.data!;
          if (upcomingReminders.isEmpty)
            return Center(child: Text('No upcoming medications!'));
          return ListView.builder(
            itemCount: upcomingReminders.length,
            itemBuilder: (context, index) {
              final reminder = upcomingReminders[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.alarm,
                    color: reminder['status'] == 'snoozed'
                        ? Colors.orange
                        : Colors.blueAccent,
                  ),
                  title: Text(reminder['medName'] ?? 'No name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upcoming at: \\${reminder['reminderTime']}'),
                      if (reminder['status'] == 'snoozed')
                        Text(
                          'Snoozed',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (reminder['status'] == 'pending')
                        Text(
                          'Pending',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (reminder['status'] == 'read')
                        Text(
                          'Read',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
