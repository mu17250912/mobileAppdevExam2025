import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to login after 2 seconds
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7B8AFF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              color: Colors.white,
              child: Text(
                'CT',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'CreditTrack',
              style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Manage your loans efficiently',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(height: 32),
            Container(
              height: 4,
              width: 180,
              color: Colors.red,
            ),
            SizedBox(height: 32),
            Text(
              'Almost ready',
              style: TextStyle(fontSize: 18, color: Colors.white, decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
    );
  }
} 