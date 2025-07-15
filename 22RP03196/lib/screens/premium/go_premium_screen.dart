import 'package:flutter/material.dart';

class GoPremiumScreen extends StatelessWidget {
  const GoPremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Icon(Icons.workspace_premium, color: Colors.white, size: 80),
              SizedBox(height: 24),
              Text('Go Premium!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 18),
              Text('Upgrade to premium and get access to all features.',
                style: TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center),
              Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/premium_pricing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF22A6F2),
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: TextStyle(fontSize: 18),
                  elevation: 2,
                ),
                child: Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 