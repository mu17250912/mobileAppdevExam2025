import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 80, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(height: 24),
            Text(
              'Smart Budget',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary),
          ],
        ),
      ),
    );
  }
} 