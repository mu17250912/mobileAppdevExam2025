import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange, width: 6),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/sp.png',
                  fit: BoxFit.cover,
                  width: 180,
                  height: 180,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                await Future.delayed(const Duration(seconds: 3));
                Navigator.of(context).pop(); // Remove loading dialog
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.arrow_forward, color: Colors.black),
              label: const Text(
                'Get Start',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 