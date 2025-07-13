import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8), // Soft green background
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UMUTONI NOVELS STORE',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Version: 1.0.0',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'A Flutter app for the UMUTONI NOVELS STORE assessment project. Browse, favorite, and read about your favorite novels!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Developer:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text('umutoni claudine'),
            const SizedBox(height: 16),
            const Text(
              'Contact:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text('Email: umutonicocose@gmail.com'),
            const SizedBox(height: 24),
            const Text(
              '© 2024 UMUTONI NOVELS STORE',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
} 