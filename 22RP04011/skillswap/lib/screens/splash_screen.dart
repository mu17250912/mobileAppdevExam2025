import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for 2 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is already authenticated
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Check subscription status
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      final subscriptionStatus = data?['subscriptionStatus'] as String?;
      final subscriptionExpiry = data?['subscriptionExpiry'] as Timestamp?;
      bool hasActiveSubscription = false;
      if (subscriptionStatus == 'active' && subscriptionExpiry != null) {
        final expiryDate = subscriptionExpiry.toDate();
        hasActiveSubscription = expiryDate.isAfter(DateTime.now());
      }
      if (hasActiveSubscription) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/subscription');
      }
    } else {
      // User is not authenticated, navigate to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_horiz,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // App Name
            const Text(
              'SkillSwap',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            // App Tagline
            const Text(
              'Connect • Learn • Grow',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 50),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              strokeWidth: 3,
            ),

            const SizedBox(height: 30),

            // Loading Text
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
