import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        // Fetch user role from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = userDoc.data();
        final role = data?['role'];
        if (role == 'driver') {
          // Check for required fields
          final hasRequiredFields =
              (data?['name'] != null && (data?['name'] as String).trim().isNotEmpty) &&
              (data?['available'] != null && data?['available'] == true) &&
              (data?['driverInfo'] != null &&
               data?['driverInfo']['carModel'] != null &&
               (data?['driverInfo']['carModel'] as String).trim().isNotEmpty);
          if (!hasRequiredFields) {
            Navigator.pushReplacementNamed(context, '/driver_register');
          } else {
            Navigator.pushReplacementNamed(context, '/driver_dashboard');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFFB2FF59)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 100, color: Colors.white),
            const SizedBox(height: 32),
            Text(
              'RwandaQuickRide',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fast, affordable rides in Rwanda',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
} 