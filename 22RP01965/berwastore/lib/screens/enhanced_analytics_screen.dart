import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/in_app_purchase_service.dart';
import 'premium_features_screen.dart';

class EnhancedAnalyticsScreen extends StatefulWidget {
  const EnhancedAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedAnalyticsScreen> createState() => _EnhancedAnalyticsScreenState();
}

class _EnhancedAnalyticsScreenState extends State<EnhancedAnalyticsScreen> {
  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  bool _hasPremiumAnalytics = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumFeatures();
  }

  Future<void> _checkPremiumFeatures() async {
    await _purchaseService.initialize();
    final hasPremium = await _purchaseService.hasPremiumFeature('premium_analytics');
    setState(() {
      _hasPremiumAnalytics = hasPremium;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Analytics'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (!_hasPremiumAnalytics)
            IconButton(
              icon: const Icon(Icons.star),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumFeaturesScreen()),
                );
              },
              tooltip: 'Upgrade to Premium',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasPremiumAnalytics
              ? _buildPremiumAnalytics()
              : _buildUpgradePrompt(),
    );
  }

  Widget _buildPremiumAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium Analytics Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            'Sales Performance',
            'Advanced sales tracking and forecasting',
            Icons.trending_up,
            Colors.green,
          ),
          _buildAnalyticsCard(
            'Customer Insights',
            'Detailed customer behavior analysis',
            Icons.people,
            Colors.blue,
          ),
          _buildAnalyticsCard(
            'Inventory Management',
            'Smart stock forecasting and alerts',
            Icons.inventory,
            Colors.orange,
          ),
          _buildAnalyticsCard(
            'Revenue Analytics',
            'Comprehensive revenue tracking and trends',
            Icons.attach_money,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Premium Analytics Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Premium to access advanced analytics features including sales forecasting, customer insights, and detailed reporting.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumFeaturesScreen()),
                );
              },
              icon: const Icon(Icons.star),
              label: const Text('Upgrade to Premium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 