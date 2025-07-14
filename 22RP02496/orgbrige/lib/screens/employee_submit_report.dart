import 'package:flutter/material.dart';

class EmployeeSubmitReport extends StatelessWidget {
  const EmployeeSubmitReport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Report'),
      ),
      body: const Center(
        child: Text('Employee Submit Report Page'),
      ),
    );
  }
} 