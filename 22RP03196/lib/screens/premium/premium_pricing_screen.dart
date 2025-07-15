import 'package:flutter/material.dart';

class PremiumPricingScreen extends StatelessWidget {
  const PremiumPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 24),
                Icon(Icons.emoji_events, color: Colors.white, size: 80),
                SizedBox(height: 24),
                Text('Pricing', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 18),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    child: Column(
                      children: [
                        Text('Full access to all workouts', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Personalized plans', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Text('No ads', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 18),
                        Text(' 249.99', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF22A6F2))),
                        Text('/ month', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/premium_checkout',
                    arguments: {'planType': 'one-time'},
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF22A6F2),
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: TextStyle(fontSize: 18),
                    elevation: 2,
                  ),
                  child: Text('One-time Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/premium_checkout',
                    arguments: {'planType': 'monthly'},
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF22A6F2),
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: TextStyle(fontSize: 18),
                    elevation: 2,
                  ),
                  child: Text('Subscribe Monthly', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/premium_checkout',
                    arguments: {'planType': 'annual'},
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF22A6F2),
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: TextStyle(fontSize: 18),
                    elevation: 2,
                  ),
                  child: Text('Subscribe Annually', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 