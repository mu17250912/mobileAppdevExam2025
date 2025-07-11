import 'package:flutter/material.dart';
import 'premium_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PremiumService.isPremium(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('Analytics & Reports')),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: Text('Analytics & Reports')),
            body: Center(child: Text('Upgrade to Premium to access advanced analytics!')),
          );
        }
        // Premium content
        return Scaffold(
          appBar: AppBar(title: Text('Analytics & Reports')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 80, color: Colors.green[800]),
                SizedBox(height: 24),
                Text('Advanced Analytics & Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('Charts, trends, and export options coming soon!', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }
} 