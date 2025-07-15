import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'login_screen.dart';
import 'employee_panel.dart';
import 'logistics_panel.dart';
import 'approver_panel.dart';
import 'subscription_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    // Add a delay to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // User is logged in, get their role and subscription from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          final userData = userDoc.data()!;
          final userRole = userData['role']?.toString() ?? 'Employee';
          final subscriptionStatus = userData['subscriptionStatus'] as String?;
          final subscriptionExpiry = userData['subscriptionExpiry'];

          bool isActive = false;
          if (subscriptionStatus == 'active' && subscriptionExpiry != null) {
            DateTime expiryDate;
            if (subscriptionExpiry is Timestamp) {
              expiryDate = subscriptionExpiry.toDate();
            } else if (subscriptionExpiry is DateTime) {
              expiryDate = subscriptionExpiry;
            } else {
              expiryDate = DateTime.now().subtract(const Duration(days: 1));
            }
            isActive = expiryDate.isAfter(DateTime.now());
          }

          if (!isActive) {
            // Not subscribed or expired, go to subscription screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
            );
            return;
          }

          // Subscribed and active, go to dashboard
          Widget targetScreen;
          switch (userRole.toLowerCase()) {
            case 'logistics':
            case 'logistics officer':
              targetScreen = const LogisticsPanel();
              break;
            case 'approver':
              targetScreen = const ApproverPanel();
              break;
            case 'employee':
            default:
              targetScreen = const EmployeePanel();
              break;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        } else if (mounted) {
          // User document doesn't exist, redirect to login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else if (mounted) {
        // No user logged in, redirect to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        // Error occurred, redirect to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
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
            Image.asset('assets/logo.png', width: 120, height: 120),
            const SizedBox(height: 32),
            const Text(
              'Requisition Management System',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F51B5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3F51B5)),
            ),
          ],
        ),
      ),
    );
  }
} 