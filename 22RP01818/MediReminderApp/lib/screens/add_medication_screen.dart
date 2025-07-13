import 'package:flutter/material.dart';
import '../services/medication_service.dart';
import '../services/reminder_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart'; // To access flutterLocalNotificationsPlugin and mainNavKey
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:just_audio/just_audio.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  String _frequency = 'Once daily';
  final _timeController = TextEditingController();
  TimeOfDay? _selectedTime;
  final MedicationService _medService = MedicationService();
  final ReminderService _reminderService = ReminderService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> playAlertSound() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/alert.mp3');
      await _audioPlayer.play();
    } catch (e) {
      // Handle error if needed
    }
  }

  // Test button to play alert sound
  void _testPlayAlertSound() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/alert.mp3');
      await _audioPlayer.play();
    } catch (e) {
      // Optionally show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing sound: $e')),
      );
    }
  }

  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required FlutterLocalNotificationsPlugin plugin,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alert'), // Use custom sound
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      await plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      await plugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } else if (kIsWeb) {
      // For web, play sound when the reminder is due (in-app only)
      final duration = scheduledTime.difference(DateTime.now());
      if (duration.isNegative) {
        playAlertSound();
      } else {
        Future.delayed(duration, playAlertSound);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Medication'), backgroundColor: Colors.blueAccent),
      backgroundColor: Color(0xFFE6EDFF),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Medication Name', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _dosageController,
              decoration: InputDecoration(labelText: 'Dosage', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _frequency,
              items: ['Once daily', 'Twice daily', 'Three times daily', 'Weekly']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (val) => setState(() => _frequency = val!),
              decoration: InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _timeController,
              readOnly: true,
              onTap: _pickTime,
              decoration: InputDecoration(
                labelText: 'First Dose Time',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _testPlayAlertSound,
              child: Text('Test Alert Sound'),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final dosage = _dosageController.text.trim();
                  final time = _timeController.text.trim();
                  if (name.isEmpty || dosage.isEmpty || time.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill all fields')),
                    );
                  } else {
                    try {
                      final medData = {
                        'name': name,
                        'dosage': dosage,
                        'frequency': _frequency,
                        'time': time,
                        'status': 'pending',
                      };
                      final medRef = await _medService.addMedicationWithRef(medData);
                      final now = DateTime.now();
                      final selectedTime = _selectedTime ?? TimeOfDay.now();
                      // If selected time is before now, set for next day
                      DateTime reminderDateTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      if (reminderDateTime.isBefore(now)) {
                        reminderDateTime = reminderDateTime.add(Duration(days: 1));
                      }
                      final reminderData = {
                        'reminderTime': Timestamp.fromDate(reminderDateTime),
                        'status': 'pending',
                      };
                      await _reminderService.addReminder(medRef.id, reminderData);

                      // Unified notification logic for all platforms
                      await scheduleReminderNotification(
                        id: medRef.id.hashCode,
                        title: 'Time for $name!',
                        body: '$dosage - $time',
                        scheduledTime: reminderDateTime,
                        plugin: flutterLocalNotificationsPlugin,
                      );

                      Navigator.pop(context);
                      // Navigate to main screen and switch to My Meds tab
                      Navigator.pushReplacementNamed(context, '/main');
                      // Switch to My Meds tab using global key
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mainNavKey.currentState != null) {
                          mainNavKey.currentState!.switchToMyMeds();
                        }
                      });
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Medication "$name" added successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } catch (e) {
                      print('Error adding medication or reminder: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add medication or reminder!')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Save Medication'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}