import 'package:flutter/material.dart';

class EmployeeProfileSettings extends StatelessWidget {
  const EmployeeProfileSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: const Center(
        child: Text('Employee Profile & Settings Page'),
      ),
    );
  }
} 