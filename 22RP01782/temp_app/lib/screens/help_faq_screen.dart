import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  final List<Map<String, String>> faqs = const [
    {
      'question': 'How do I apply for a gig?',
      'answer': 'Go to the Job Listings screen, find a gig you like, and tap the Apply button.'
    },
    {
      'question': 'How do I track my income?',
      'answer': 'Mark gigs as completed and enter the amount earned. View analytics in the Income Dashboard.'
    },
    {
      'question': 'How do I become a premium user?',
      'answer': 'Go to the Premium screen and follow the instructions to upgrade.'
    },
    {
      'question': 'How do I export my data?',
      'answer': 'Go to your Profile and tap the Export Data button.'
    },
    {
      'question': 'How do I contact support?',
      'answer': 'Tap the Contact Support button below to send us an email.'
    },
  ];

  void _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@campusgigs.com',
      query: 'subject=Support Request',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...faqs.map((faq) => ExpansionTile(
                title: Text(faq['question']!),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(faq['answer']!),
                  ),
                ],
              )),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _contactSupport,
            icon: const Icon(Icons.email),
            label: const Text('Contact Support'),
          ),
          const SizedBox(height: 16),
          FutureBuilder(
            future: user != null ? FirebaseFirestore.instance.collection('users').doc(user.uid).get() : null,
            builder: (context, snapshot) {
              final isPremium = snapshot.hasData && (snapshot.data?.data()?['premium'] ?? false);
              if (!isPremium) return const SizedBox.shrink();
              return ElevatedButton.icon(
                onPressed: () async {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'premium-support@campusgigs.com',
                    query: 'subject=Premium Support Request',
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  }
                },
                icon: const Icon(Icons.verified_user),
                label: const Text('Contact Premium Support'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              );
            },
          ),
        ],
      ),
    );
  }
} 