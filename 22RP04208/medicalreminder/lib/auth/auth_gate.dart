import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dashboard/home_screen.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const AuthScreen();
        }
        // User is logged in, check if onboarding is complete
        return FutureBuilder<bool>(
          future: _isOnboarded(snapshot.data!),
          builder: (context, onboardSnap) {
            if (onboardSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (onboardSnap.data == true) {
              return const HomeScreen();
            } else {
              return const OnboardingScreen();
            }
          },
        );
      },
    );
  }

  Future<bool> _isOnboarded(User user) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['onboarded'] == true;
  }
} 