import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace with your app logo if available
            Icon(Icons.confirmation_num, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            Text('Event organizer', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
} 