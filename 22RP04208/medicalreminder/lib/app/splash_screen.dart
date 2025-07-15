import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onContinue;
  const SplashScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text('Medical Reminder', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onContinue,
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
} 