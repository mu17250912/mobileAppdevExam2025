import 'package:flutter/material.dart';
import '../config/design_system.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
        ),
        title: const Text('About QuickDocs', style: AppTypography.titleMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.description, size: 64, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text('QuickDocs', style: AppTypography.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Your simple, powerful document manager', style: AppTypography.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('How QuickDocs Works', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              'QuickDocs helps you create, manage, and share professional invoices, quotes, and other business documents in seconds. You can generate PDFs, send them to clients, and keep track of your business paperwork all in one place.',
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text('Free Tier', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              '• Create up to 10 documents (invoices, quotes, etc.)\n'
              '• Export documents as PDF (with a "Created with QuickDocs" watermark)\n'
              '• Use basic templates\n'
              '• Receive notifications and manage your dashboard\n',
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text('Premium Tier', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              '• Unlimited document creation\n'
              '• No watermark on exported PDFs\n'
              '• Priority support\n'
              '• All future premium features included\n',
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text('How to Upgrade', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              'To upgrade to premium, go to Settings and tap "Upgrade to Premium". After payment, your account will be upgraded and you will enjoy all premium features instantly.',
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 32),
            Center(
              child: Text('Thank you for using QuickDocs!', style: AppTypography.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
} 