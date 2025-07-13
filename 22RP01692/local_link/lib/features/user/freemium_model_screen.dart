import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_premium_screen.dart';

class FreemiumModelScreen extends StatefulWidget {
  const FreemiumModelScreen({super.key});

  @override
  State<FreemiumModelScreen> createState() => _FreemiumModelScreenState();
}

class _FreemiumModelScreenState extends State<FreemiumModelScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> _features = [
    {
      'name': 'Basic Booking',
      'free': '3 bookings per month',
      'premium': 'Unlimited bookings',
      'icon': Icons.book,
      'color': Colors.blue,
    },
    {
      'name': 'Service Search',
      'free': 'Basic search filters',
      'premium': 'Advanced filters + premium providers',
      'icon': Icons.search,
      'color': Colors.green,
    },
    {
      'name': 'Customer Support',
      'free': 'Email support (48h response)',
      'premium': '24/7 priority support',
      'icon': Icons.support_agent,
      'color': Colors.orange,
    },
    {
      'name': 'Booking History',
      'free': 'Last 10 bookings',
      'premium': 'Unlimited history + analytics',
      'icon': Icons.history,
      'color': Colors.purple,
    },
    {
      'name': 'Notifications',
      'free': 'Basic notifications',
      'premium': 'Custom notifications + priority alerts',
      'icon': Icons.notifications,
      'color': Colors.red,
    },
    {
      'name': 'Provider Ratings',
      'free': 'Basic ratings view',
      'premium': 'Detailed reviews + verified badges',
      'icon': Icons.star,
      'color': Colors.amber,
    },
    {
      'name': 'Payment Options',
      'free': 'Standard payment methods',
      'premium': 'Multiple payment options + virtual balance',
      'icon': Icons.payment,
      'color': Colors.indigo,
    },
    {
      'name': 'Priority Booking',
      'free': 'Standard queue',
      'premium': 'Priority slots + instant booking',
      'icon': Icons.priority_high,
      'color': Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view freemium model.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Free vs Premium'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final subscriptionPlan = userData['subscriptionPlan'] as String?;
          final subscriptionExpiry = userData['subscriptionExpiry'] as Timestamp?;
          final hasActiveSubscription = subscriptionPlan != null && 
              subscriptionExpiry != null && 
              subscriptionExpiry.toDate().isAfter(DateTime.now());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Status
                _buildCurrentStatusCard(hasActiveSubscription, subscriptionPlan),
                const SizedBox(height: 24),

                // Features Comparison
                _buildFeaturesComparison(),
                const SizedBox(height: 24),

                // Upgrade Options
                _buildUpgradeOptions(),
                const SizedBox(height: 24),

                // Benefits
                _buildBenefitsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStatusCard(bool hasActiveSubscription, String? subscriptionPlan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  hasActiveSubscription ? Icons.star : Icons.star_border,
                  color: hasActiveSubscription ? Colors.amber : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasActiveSubscription ? 'Premium User' : 'Free User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        hasActiveSubscription 
                            ? 'Plan: ${_getPlanDisplayName(subscriptionPlan!)}'
                            : 'Upgrade to unlock premium features',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasActiveSubscription ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasActiveSubscription ? 'ACTIVE' : 'FREE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (!hasActiveSubscription) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserPremiumScreen()),
                    );
                  },
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Upgrade to Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Feature Comparison',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Feature',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Free',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Premium',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Features
                ..._features.map((feature) => _buildFeatureRow(feature)).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(Map<String, dynamic> feature) {
    final name = feature['name'] as String;
    final freeFeature = feature['free'] as String;
    final premiumFeature = feature['premium'] as String;
    final icon = feature['icon'] as IconData;
    final color = feature['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                freeFeature,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Text(
                premiumFeature,
                style: TextStyle(fontSize: 12, color: Colors.green[700]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upgrade Options',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildUpgradeCard(
                'Monthly',
                '30,000 FRW',
                'per month',
                Colors.blue,
                Icons.calendar_month,
                () => _showUpgradeDialog('monthly'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUpgradeCard(
                'Annual',
                '300,000 FRW',
                'per year (Save 17%)',
                Colors.green,
                Icons.calendar_today,
                () => _showUpgradeDialog('annual'),
                isPopular: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildUpgradeCard(
          'Lifetime',
          '600,000 FRW',
          'one-time payment',
          Colors.purple,
          Icons.all_inclusive,
          () => _showUpgradeDialog('lifetime'),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildUpgradeCard(
    String title,
    String price,
    String subtitle,
    Color color,
    IconData icon,
    VoidCallback onTap, {
    bool isPopular = false,
    bool fullWidth = false,
  }) {
    return Card(
      elevation: isPopular ? 8 : 2,
      child: Container(
        width: fullWidth ? double.infinity : null,
        decoration: isPopular
            ? BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (isPopular) const SizedBox(height: 8),
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Why Upgrade to Premium?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBenefitItem(
                  Icons.speed,
                  'Faster Service',
                  'Get priority booking slots and faster response times',
                  Colors.orange,
                ),
                _buildBenefitItem(
                  Icons.security,
                  'Better Security',
                  'Enhanced security features and fraud protection',
                  Colors.green,
                ),
                _buildBenefitItem(
                  Icons.support_agent,
                  'Premium Support',
                  '24/7 dedicated customer support team',
                  Colors.blue,
                ),
                _buildBenefitItem(
                  Icons.analytics,
                  'Advanced Analytics',
                  'Detailed insights and booking analytics',
                  Colors.purple,
                ),
                _buildBenefitItem(
                  Icons.savings,
                  'Save Money',
                  'Exclusive discounts and special offers',
                  Colors.red,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(String plan) {
    String planName;
    String price;
    String description;

    switch (plan) {
      case 'monthly':
        planName = 'Monthly Premium';
        price = '30,000 FRW/month';
        description = 'Perfect for trying out premium features';
        break;
      case 'annual':
        planName = 'Annual Premium';
        price = '300,000 FRW/year';
        description = 'Best value - save 17% compared to monthly';
        break;
      case 'lifetime':
        planName = 'Lifetime Premium';
        price = '600,000 FRW';
        description = 'One-time payment for lifetime access';
        break;
      default:
        planName = 'Premium Plan';
        price = '30,000 FRW/month';
        description = 'Upgrade to premium features';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to $planName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to upgrade to:'),
            const SizedBox(height: 8),
            Text(
              planName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Price: $price'),
            Text(description),
            const SizedBox(height: 16),
            const Text('This includes:'),
            const SizedBox(height: 8),
            ..._features.take(4).map((feature) => Text('• ${feature['premium']}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserPremiumScreen()),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  String _getPlanDisplayName(String planId) {
    switch (planId) {
      case 'basic_plus':
        return 'Basic Plus';
      case 'premium_user':
        return 'Premium User';
      case 'vip_user':
        return 'VIP User';
      default:
        return planId;
    }
  }
} 