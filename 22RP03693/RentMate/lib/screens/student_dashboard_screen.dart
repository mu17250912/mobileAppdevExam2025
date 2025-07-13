import 'package:flutter/material.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: const Center(
        child: Text(
          'Welcome, Student!',
          style: TextStyle(fontSize: 24, color: Colors.blue),
        ),
      ),
    );
  }
} 