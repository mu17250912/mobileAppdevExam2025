import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  final String userId;
  const AdminScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Center(
        child: Text('Welcome Admin! User ID: ' + userId),
      ),
    );
  }
}
