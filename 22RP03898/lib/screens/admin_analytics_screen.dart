import 'package:flutter/material.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Analytics'),
      ),
      body: const Center(
        child: Text(
          'Analytics content will appear here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
