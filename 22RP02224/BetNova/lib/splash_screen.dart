import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3), // Blue background
      body: Center(
        child: Image.asset(
          'assets/splash_screen/splash.png',
          width: 300, // Adjust as needed
          fit: BoxFit.contain,
        ),
      ),
    );
  }
} 