import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text(
              'No notifications yet.',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
} 