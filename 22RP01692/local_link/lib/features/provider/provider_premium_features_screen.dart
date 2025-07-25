import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProviderPremiumFeaturesScreen extends StatefulWidget {
  const ProviderPremiumFeaturesScreen({super.key});

  @override
  State<ProviderPremiumFeaturesScreen> createState() => _ProviderPremiumFeaturesScreenState();
}

class _ProviderPremiumFeaturesScreenState extends State<ProviderPremiumFeaturesScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final Map<String, List<Map<String, dynamic>>> _features = {
    'free': [
      {'name': 'Service Categories', 'limit': '5', 'available': true},
      {'name': 'Monthly Bookings', 'limit': '50', 'available': true},
      {'name': 'Basic Analytics', 'available': true},
      {'name': 'Standard Support', 'available': true},
      {'name': 'Custom Branding', 'available': false},
      {'name': 'SMS Notifications', 'available': false},
      {'name': 'Marketing Tools', 'available': false},
      {'name': 'API Access', 'available': false},
    ],
    'basic': [
      {'name': 'Service Categories', 'limit': '15', 'available': true},
      {'name': 'Monthly Bookings', 'limit': '200', 'available': true},
      {'name': 'Advanced Analytics', 'available': true},
      {'name': 'Priority Support', 'available': true},
      {'name': 'Custom Branding', 'available': true},
      {'name': 'SMS Notifications', 'available': true},
      {'name': 'Marketing Tools', 'available': false},
      {'name': 'API Access', 'available': false},
    ],
    'premium': [
      {'name': 'Service Categories', 'limit': 'Unlimited', 'available': true},
      {'name': 'Monthly Bookings', 'limit': 'Unlimited', 'available': true},
      {'name': 'Premium Analytics', 'available': true},
      {'name': '24/7 Support', 'available': true},
      {'name': 'Custom Branding', 'available': true},
      {'name': 'SMS Notifications', 'available': true},
      {'name': 'Marketing Tools', 'available': true},
      {'name': 'API Access', 'available': true},
    ],
    'enterprise': [
      {'name': 'Service Categories', 'limit': 'Unlimited', 'available': true},
      {'name': 'Monthly Bookings', 'limit': 'Unlimited', 'available': true},
      {'name': 'Premium Analytics', 'available': true},
      {'name': 'Dedicated Support', 'available': true},
      {'name': 'Custom Branding', 'available': true},
      {'name': 'SMS Notifications', 'available': true},
      {'name': 'Marketing Tools', 'available': true},
      {'name': 'API Access', 'available': true},
      {'name': 'Multi-location', 'available': true},
      {'name': 'Team Management', 'available': true},
      {'name': 'Custom Integrations', 'available': true},
    ],
  };

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a provider.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
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
          final currentPlan = userData['subscriptionPlan'] ?? 'free';
          final planExpiry = userData['planExpiry'] as Timestamp?;
          final isActive = planExpiry?.toDate().isAfter(DateTime.now()) ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Plan Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Your Current Plan',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getPlanColor(currentPlan),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getPlanName(currentPlan),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green[100] : Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Expired',
                                style: TextStyle(
                                  color: isActive ? Colors.green[700] : Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (planExpiry != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Expires: ${DateFormat('MMM dd, yyyy').format(planExpiry.toDate())}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Features List
                const Text(
                  'Available Features',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                ..._features[currentPlan]!.map((feature) => _buildFeatureCard(feature)).toList(),

                const SizedBox(height: 24),

                // Upgrade Section
                if (currentPlan != 'enterprise')
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.trending_up, size: 48, color: Colors.blue[700]),
                          const SizedBox(height: 16),
                          const Text(
                            'Upgrade Your Plan',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Get access to more features and grow your business faster',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/subscription');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: const Text(
                              'View Plans',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Usage Statistics
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Usage Statistics',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildUsageItem('Service Categories', '3', '5'),
                        _buildUsageItem('Monthly Bookings', '12', '50'),
                        _buildUsageItem('Active Users', '8', 'Unlimited'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    final name = feature['name'] as String;
    final limit = feature['limit'] as String?;
    final available = feature['available'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          available ? Icons.check_circle : Icons.lock,
          color: available ? Colors.green : Colors.grey,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: available ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: limit != null ? Text('Limit: $limit') : null,
        trailing: available
            ? const Icon(Icons.check, color: Colors.green)
            : const Icon(Icons.close, color: Colors.red),
      ),
    );
  }

  Widget _buildUsageItem(String label, String used, String limit) {
    final usedNum = int.tryParse(used) ?? 0;
    final limitNum = limit == 'Unlimited' ? double.infinity : (int.tryParse(limit) ?? 1);
    final percentage = limitNum == double.infinity ? 0.0 : (usedNum / limitNum);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$used / $limit'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 0.8 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlanColor(String planId) {
    switch (planId) {
      case 'basic':
        return Colors.blue;
      case 'premium':
        return Colors.purple;
      case 'enterprise':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getPlanName(String planId) {
    switch (planId) {
      case 'basic':
        return 'Basic Plan';
      case 'premium':
        return 'Premium Plan';
      case 'enterprise':
        return 'Enterprise Plan';
      default:
        return 'Free Plan';
    }
  }
} 