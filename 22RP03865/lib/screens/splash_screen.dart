import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/sign-in');
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple,
              Colors.deepOrange,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
            Icons.local_fire_department,
            size: 100,
            color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Welcome',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'NeighborhoodAlert App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
      // Removed payment button from splash screen
    );
  }
}

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    // Use signInWithPopup for web compatibility
    final userCredential = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    final user = userCredential.user;

    // Check Firestore for role
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

    if (!userDoc.exists) {
      // First time login, create user doc with default role (user)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'role': 'user', // Set manually to 'admin' in Firestore for admins
      });
      // Show error: Only admins can sign in with Google
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access denied. Only admins can sign in with Google.')),
      );
      return;
    } else {
      final role = userDoc['role'];
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        // Not admin, sign out and show error
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access denied. Only admins can sign in with Google.')),
        );
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Google Sign-In failed: \\${e.toString()}')),
    );
  }
}

Future<void> launchStripeCheckout() async {
  final url = Uri.parse('https://buy.stripe.com/test_4gw...'); // Your Stripe payment link
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch Stripe checkout URL';
  }
} 