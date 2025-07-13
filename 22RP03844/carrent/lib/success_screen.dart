import 'package:flutter/material.dart';
import 'user_store.dart';
import 'user_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'receipt_screen.dart';

class SuccessScreen extends StatelessWidget {
  final Map<String, dynamic> receipt;
  const SuccessScreen({Key? key, required this.receipt}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 32),
              const Text('Payment Successful!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Thank you for your payment. Your booking is confirmed.'),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiptScreen(receipt: receipt),
                    ),
                  );
                },
                child: const Text('View/Download Receipt'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final user = UserStore.currentUser;
                  if (user != null && user.isAdmin) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                      (route) => false,
                    );
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 