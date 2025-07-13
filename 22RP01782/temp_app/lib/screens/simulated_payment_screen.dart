// lib/screens/simulated_payment_screen.dart
import 'package:flutter/material.dart';

class SimulatedPaymentScreen extends StatelessWidget {
  const SimulatedPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulated Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Simulate your payment here (e.g., MTN MoMo, Stripe, etc).',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Simulate Successful Payment'),
              onPressed: () {
                Navigator.pop(context, true); // return success
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // return failure
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
