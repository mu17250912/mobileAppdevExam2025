import 'package:flutter/material.dart';

class ManagerLogin extends StatelessWidget {
  const ManagerLogin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Login'),
      ),
      body: const Center(
        child: Text('Manager Login Page'),
      ),
    );
  }
} 