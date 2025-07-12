import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import '../services/ad_service.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdService _adService = AdService();
  bool _shouldShowAds = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    bool isPremium = await LocalStorageService.isPremium();
    setState(() {
      _shouldShowAds = !isPremium;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName != null && userName.isNotEmpty
                        ? 'Welcome, $userName! 👋'
                        : 'Welcome back! 👋',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your safe space for health information and support',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Freemium & Premium Features Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Freemium vs Premium', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Freemium
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Freemium', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            SizedBox(height: 8),
                            Text('• Soma articles y’ibanze'),
                            Text('• Chat y’ibanze'),
                            Text('• Kwibutsa'),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.grey[300]),
                      // Premium
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Premium', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                            const SizedBox(height: 8),
                            const Text('• Articles zose'),
                            const Text('• Chat idafite imipaka'),
                            const Text('• Amakuru yihariye'),
                            const Text('• Nta matangazo'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => PremiumPaymentDialog(onUpgraded: () => setState(() {})),
                                );
                              },
                              child: const Text('Upgrade'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Main Navigation
          _buildNavigationTile(
            context,
            'Info Hub',
            Icons.info_outline,
            Colors.blue,
            'Articles, videos & resources',
            '/info-hub',
          ),
          _buildNavigationTile(
            context,
            'Live Chat Counselor',
            Icons.chat_outlined,
            Colors.green,
            'Talk to a licensed counselor',
            '/chat',
          ),
          _buildNavigationTile(
            context,
            'Reminders',
            Icons.alarm_outlined,
            Colors.orange,
            'Health check-ups & appointments',
            '/reminders',
          ),
          _buildNavigationTile(
            context,
            'Emergency Help',
            Icons.emergency_outlined,
            Colors.red,
            'Quick access to emergency services',
            '/emergency',
          ),
          _buildNavigationTile(
            context,
            'Profile & Badges',
            Icons.person_outline,
            Colors.purple,
            'Your achievements & settings',
            '/profile',
          ),
          // Banner Ad - only show if not premium and ad is ready
          if (_shouldShowAds && _adService.isBannerAdReady)
            Container(
              width: _adService.bannerAd!.size.width.toDouble(),
              height: _adService.bannerAd!.size.height.toDouble(),
              alignment: Alignment.center,
              child: AdWidget(ad: _adService.bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    bool isPremium,
  ) {
    return ElevatedButton(
      onPressed: () {
        // Handle plan selection
        if (isPremium) {
          _showPremiumDialog(context);
        } else {
          _showFreemiumDialog(context);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text('Premium Features'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✨ Unlimited access to all articles'),
              SizedBox(height: 8),
              Text('✨ Priority chat with counselors'),
              SizedBox(height: 8),
              Text('✨ Advanced reminder features'),
              SizedBox(height: 8),
              Text('✨ Premium health tips'),
              SizedBox(height: 8),
              Text('✨ Ad-free experience'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Set premium status
                await LocalStorageService.setPremiumStatus(true);
                // Refresh UI
                setState(() {
                  _shouldShowAds = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Premium activated! Ads removed.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Activate Premium'),
            ),
          ],
        );
      },
    );
  }

  void _showFreemiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_outline, color: Colors.grey),
              SizedBox(width: 8),
              Text('Freemium Plan'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📱 Basic health articles'),
              SizedBox(height: 8),
              Text('📱 Limited chat sessions'),
              SizedBox(height: 8),
              Text('📱 Basic reminders'),
              SizedBox(height: 8),
              Text('📱 Standard support'),
              SizedBox(height: 8),
              Text('📱 Ad-supported'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    String route,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}

class PremiumPaymentDialog extends StatefulWidget {
  final VoidCallback onUpgraded;
  const PremiumPaymentDialog({required this.onUpgraded, super.key});

  @override
  State<PremiumPaymentDialog> createState() => _PremiumPaymentDialogState();
}

class _PremiumPaymentDialogState extends State<PremiumPaymentDialog> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shyiramo nimero yawe ya telefoni'),
      content: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Mobile Number',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            setState(() { _isLoading = true; });
            // TODO: Integrate payment logic here
            // After payment, update Firebase user as premium
            await FirebaseService().updateUserProfile({
              'isPremium': true,
              'phoneNumber': _phoneController.text.trim(),
            });
            setState(() { _isLoading = false; });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wabaye premium!')), // You are now premium!
            );
            widget.onUpgraded();
          },
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Pay & Upgrade'),
        ),
      ],
    );
  }
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
} 