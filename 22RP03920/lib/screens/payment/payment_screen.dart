import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  final double amount;
  final Map<String, dynamic> bookingDetails;

  const PaymentScreen({Key? key, required this.amount, required this.bookingDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Appointment Payment', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              Text('Amount Due:', style: Theme.of(context).textTheme.bodyLarge),
              Text('RWF ${amount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Simulate Payment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  // Simulate marking appointment as paid (extend here for real payment)
                  // Optionally update Firebase or local state here
                  Navigator.pushReplacementNamed(
                    context,
                    '/payment_success',
                    arguments: bookingDetails,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 