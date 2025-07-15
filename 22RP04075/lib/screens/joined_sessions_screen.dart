import 'package:flutter/material.dart';

class JoinedSessionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real joined sessions data
    final List<Map<String, dynamic>> joinedSessions = [
      {
        'title': 'Calculus Study Group',
        'date': 'Jul 13, 2025',
        'time': '2:00 PM',
        'partner': 'Sarah Martinez',
      },
      {
        'title': 'Physics Revision',
        'date': 'Jul 14, 2025',
        'time': '4:00 PM',
        'partner': 'David Karim',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Joined Sessions'),
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: joinedSessions.length,
        itemBuilder: (context, index) {
          final session = joinedSessions[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(session['title'] ?? ''),
              subtitle: Text('${session['date']} at ${session['time']}\nPartner: ${session['partner']}'),
              isThreeLine: true,
              leading: Icon(Icons.event),
            ),
          );
        },
      ),
    );
  }
} 