import 'package:flutter/material.dart';

class EmployeeLogin extends StatelessWidget {
  const EmployeeLogin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Login'),
      ),
      body: const Center(
        child: Text('Employee Login Page'),
      ),
    );
  }
} 