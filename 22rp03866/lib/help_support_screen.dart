import 'package:flutter/material.dart';
import 'theme/colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF23272F) : AppColors.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Icon(Icons.contact_support, size: 80, color: isDark ? AppColors.primary : AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Help & Support',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  _FaqItem(
                    question: 'How do I book a park?',
                    answer: 'Browse parks on the Home screen, tap a park for details, then tap "Book Now" and follow the steps.',
                  ),
                  _FaqItem(
                    question: 'How do I edit my profile?',
                    answer: 'Go to Account > Edit Profile to update your information.',
                  ),
                  _FaqItem(
                    question: 'How do I enable dark mode?',
                    answer: 'Go to Account > Account Settings and toggle the Dark Mode switch.',
                  ),
                  _FaqItem(
                    question: 'How do I contact support?',
                    answer: 'Email us at support@safarigo.com or use the contact info below.',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(Icons.email, color: AppColors.primary),
                    title: Text('support@safarigo.com', style: TextStyle(color: isDark ? Colors.white : AppColors.text)),
                  ),
                  ListTile(
                    leading: Icon(Icons.phone, color: AppColors.primary),
                    title: Text('+250788902010', style: TextStyle(color: isDark ? Colors.white : AppColors.text)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'App Tips',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(Icons.lightbulb, color: AppColors.primary),
                    title: Text('Swipe left or right on the Home screen to explore more parks.', style: TextStyle(color: isDark ? Colors.white : AppColors.text)),
                  ),
                  ListTile(
                    leading: Icon(Icons.security, color: AppColors.primary),
                    title: Text('Your data is securely stored and never shared without your consent.', style: TextStyle(color: isDark ? Colors.white : AppColors.text)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(answer, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : AppColors.text)),
        ],
      ),
    );
  }
} 