import 'package:flutter/material.dart';
import 'login.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  void _goToLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_tree_rounded, 
                size: 80, 
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'OrgBridge',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Organizational Task Manager',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _goToLogin(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.white,
                  elevation: 2,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF764ba2)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 