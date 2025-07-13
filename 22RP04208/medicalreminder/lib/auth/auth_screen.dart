import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to login by default
    if (!context.mounted) return const SizedBox.shrink();
    Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
} 