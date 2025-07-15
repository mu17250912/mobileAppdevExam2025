import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillswap/main.dart'; // Correct import for MainScaffold
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _navError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToLogin());
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (ModalRoute.of(context) != null) {
        if (user != null) {
          debugPrint('Splash: Navigating to home (direct widget push)');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainScaffold(initialTabIndex: 0),
            ),
          );
        } else {
          debugPrint('Splash: Navigating to /login');
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        setState(() {
          _navError = 'Navigation context is invalid.';
        });
      }
    } catch (e, st) {
      debugPrint('Splash navigation error: $e\n$st');
      setState(() {
        _navError = 'Navigation error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1976D2), // Deep Blue
              Color(0xFF42A5F5), // Light Blue
              Color(0xFF7C4DFF), // Vibrant Purple
              Color(0xFFFFC107), // Amber/Gold
            ],
          ),
        ),
        child: Center(
          child: _navError != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _navError ?? 'Unknown error',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo (SVG)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SvgPicture.asset(
                          'assets/app_icon.svg',
                          fit: BoxFit.contain,
                          placeholderBuilder: (context) => const Icon(
                            Icons.swap_horiz,
                            size: 60,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // App Name
                    const Text(
                      'SkillSwap',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tagline
                    const Text(
                      'Connect · Learn · Grow',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
