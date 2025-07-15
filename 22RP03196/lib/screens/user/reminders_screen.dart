import 'package:flutter/material.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool dailyReminder = false;
  bool goalReminder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22A6F2),
        elevation: 0,
        title: Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: SwitchListTile(
                title: Text('Daily Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Receive a daily reminder to visit your favorites'),
                value: dailyReminder,
                onChanged: (val) => setState(() => dailyReminder = val),
                activeColor: const Color(0xFF22A6F2),
              ),
            ),
            SizedBox(height: 18),
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: SwitchListTile(
                title: Text('Goal Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Reminder to keep achieving your workouts'),
                value: goalReminder,
                onChanged: (val) => setState(() => goalReminder = val),
                activeColor: const Color(0xFF22A6F2),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 