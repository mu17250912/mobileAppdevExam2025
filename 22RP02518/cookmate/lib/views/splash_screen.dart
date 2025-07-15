import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 100, height: 100),
            SizedBox(height: 24),
            Text('Let me be your CookMate', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
} 