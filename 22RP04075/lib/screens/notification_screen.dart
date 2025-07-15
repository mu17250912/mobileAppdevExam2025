import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real notification data
    final List<Map<String, String>> notifications = [
      {
        'title': 'Session Created',
        'body': 'You created a session for Calculus Study Group.',
        'time': 'Jul 13, 2025, 2:00 PM',
        'partner': 'Sarah Martinez',
      },
      {
        'title': 'Session Reminder',
        'body': 'Physics Revision session with David Karim is tomorrow at 4:00 PM.',
        'time': 'Jul 14, 2025, 4:00 PM',
        'partner': 'David Karim',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: Text('Notifications'),
        backgroundColor: Colors.blue[800],
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.notifications_active, color: Colors.blue[800]),
              title: Text(notif['title'] ?? ''),
              subtitle: Text('${notif['body']}\nTime: ${notif['time']}\nPartner: ${notif['partner']}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
} 