import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_colors.dart';

class SubscriptionPaymentInstructionsScreen extends StatelessWidget {
  final String planName;
  final String planPrice;
  const SubscriptionPaymentInstructionsScreen({Key? key, required this.planName, required this.planPrice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const ussdCode = '*182*8*1*271056#';
    const recipient = 'AgriConnect Rwanda';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Instructions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are subscribing to:',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              planName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 2),
            Text(
              planPrice,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            const Text(
              'How to Pay for Your Subscription',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              '1. Dial the following USSD code on your phone:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SelectableText(
                  ussdCode,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.primary),
                  tooltip: 'Copy USSD code',
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: ussdCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('USSD code copied!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '2. Enter the amount for your subscription plan.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              '3. When prompted for recipient, enter:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            SelectableText(
              recipient,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'After payment, your subscription will be activated automatically or by our support team. If you have any issues, please contact support.',
                style: TextStyle(fontSize: 15),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 