import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProviderSubscriptionScreen extends StatefulWidget {
  const ProviderSubscriptionScreen({super.key});

  @override
  State<ProviderSubscriptionScreen> createState() => _ProviderSubscriptionScreenState();
}

class _ProviderSubscriptionScreenState extends State<ProviderSubscriptionScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String _selectedPlan = 'free';

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'free',
      'name': 'Free Plan',
      'price': 0,
      'duration': 'Forever',
      'features': [
        'Up to 5 service categories',
        'Basic booking management',
        'Standard customer support',
        'Basic analytics',
        'Up to 50 bookings per month',
      ],
      'color': Colors.grey,
      'popular': false,
    },
    {
      'id': 'basic',
      'name': 'Basic Plan',
      'price': 9.99,
      'duration': 'per month',
      'features': [
        'Up to 15 service categories',
        'Advanced booking management',
        'Priority customer support',
        'Advanced analytics',
        'Up to 200 bookings per month',
        'Custom branding',
        'SMS notifications',
      ],
      'color': Colors.blue,
      'popular': false,
    },
    {
      'id': 'premium',
      'name': 'Premium Plan',
      'price': 50000,
      'duration': 'per month',
      'features': [
        'Unlimited service categories',
        'Full booking management',
        '24/7 customer support',
        'Premium analytics & reports',
        'Unlimited bookings',
        'Custom branding & domain',
        'SMS & email notifications',
        'Advanced marketing tools',
        'API access',
        'White-label solution',
      ],
      'color': Colors.purple,
      'popular': true,
    },
    {
      'id': 'enterprise',
      'name': 'Enterprise Plan',
      'price': 120000,
      'duration': 'per month',
      'features': [
        'Everything in Premium',
        'Multi-location support',
        'Advanced team management',
        'Custom integrations',
        'Dedicated account manager',
        'Custom development support',
        'Advanced security features',
        'Compliance reporting',
      ],
      'color': Colors.orange,
      'popular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a provider.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Plan Status
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final currentPlan = userData['subscriptionPlan'] ?? 'free';
                final planExpiry = userData['planExpiry'] as Timestamp?;
                final isActive = planExpiry?.toDate().isAfter(DateTime.now()) ?? false;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_user, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Current Plan',
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
                );
              },
            ),
            const SizedBox(height: 24),

            // Plans Header
            const Text(
              'Choose Your Plan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the plan that best fits your business needs',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Plans Grid
            ..._plans.map((plan) => _buildPlanCard(plan)).toList(),

            const SizedBox(height: 24),

            // Features Comparison
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Features Comparison',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildFeaturesTable(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildFAQItem(
                      'Can I change my plan anytime?',
                      'Yes, you can upgrade or downgrade your plan at any time. Changes will be reflected in your next billing cycle.',
                    ),
                    _buildFAQItem(
                      'What payment methods do you accept?',
                      'We accept all major credit cards, debit cards, and digital wallets including PayPal, Apple Pay, and Google Pay.',
                    ),
                    _buildFAQItem(
                      'Is there a free trial?',
                      'Yes, all paid plans come with a 7-day free trial. You can cancel anytime during the trial period.',
                    ),
                    _buildFAQItem(
                      'Can I cancel my subscription?',
                      'Yes, you can cancel your subscription at any time. You\'ll continue to have access until the end of your current billing period.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isPopular = plan['popular'] as bool;
    final planId = plan['id'] as String;
    final planName = plan['name'] as String;
    final price = plan['price'] as double;
    final duration = plan['duration'] as String;
    final features = plan['features'] as List<String>;
    final color = plan['color'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPopular ? 8 : 2,
      child: Container(
        decoration: isPopular
            ? BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  const Spacer(),
                  Icon(Icons.check_circle, color: color, size: 24),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                planName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${price.toInt()} FRW',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    duration,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(feature)),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handlePlanSelection(planId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    planId == 'free' ? 'Current Plan' : 'Choose Plan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesTable() {
    final features = [
      'Service Categories',
      'Monthly Bookings',
      'Analytics',
      'Customer Support',
      'Custom Branding',
      'SMS Notifications',
      'Marketing Tools',
      'API Access',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Feature')),
          DataColumn(label: Text('Free')),
          DataColumn(label: Text('Basic')),
          DataColumn(label: Text('Premium')),
          DataColumn(label: Text('Enterprise')),
        ],
        rows: features.map((feature) {
          return DataRow(
            cells: [
              DataCell(Text(feature)),
              DataCell(_getFeatureValue(feature, 'free')),
              DataCell(_getFeatureValue(feature, 'basic')),
              DataCell(_getFeatureValue(feature, 'premium')),
              DataCell(_getFeatureValue(feature, 'enterprise')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _getFeatureValue(String feature, String plan) {
    String value = '';
    Color color = Colors.grey;

    switch (feature) {
      case 'Service Categories':
        switch (plan) {
          case 'free':
            value = '5';
            break;
          case 'basic':
            value = '15';
            break;
          case 'premium':
          case 'enterprise':
            value = 'Unlimited';
            color = Colors.green;
            break;
        }
        break;
      case 'Monthly Bookings':
        switch (plan) {
          case 'free':
            value = '50';
            break;
          case 'basic':
            value = '200';
            break;
          case 'premium':
          case 'enterprise':
            value = 'Unlimited';
            color = Colors.green;
            break;
        }
        break;
      case 'Analytics':
        switch (plan) {
          case 'free':
            value = 'Basic';
            break;
          case 'basic':
            value = 'Advanced';
            color = Colors.blue;
            break;
          case 'premium':
          case 'enterprise':
            value = 'Premium';
            color = Colors.green;
            break;
        }
        break;
      case 'Customer Support':
        switch (plan) {
          case 'free':
            value = 'Standard';
            break;
          case 'basic':
            value = 'Priority';
            color = Colors.blue;
            break;
          case 'premium':
            value = '24/7';
            color = Colors.green;
            break;
          case 'enterprise':
            value = 'Dedicated';
            color = Colors.orange;
            break;
        }
        break;
      case 'Custom Branding':
      case 'SMS Notifications':
        switch (plan) {
          case 'free':
            value = '✗';
            color = Colors.red;
            break;
          default:
            value = '✓';
            color = Colors.green;
            break;
        }
        break;
      case 'Marketing Tools':
      case 'API Access':
        switch (plan) {
          case 'free':
          case 'basic':
            value = '✗';
            color = Colors.red;
            break;
          default:
            value = '✓';
            color = Colors.green;
            break;
        }
        break;
    }

    return Text(
      value,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(color: Colors.grey)),
        ),
      ],
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

  void _handlePlanSelection(String planId) async {
    if (planId == 'free') {
      // Show current plan message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already on the Free plan')),
      );
      return;
    }

    // Show payment dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscribe to Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to subscribe to the ${_getPlanName(planId)}.'),
            const SizedBox(height: 16),
            const Text('This will include:'),
            const SizedBox(height: 8),
            ..._plans.firstWhere((p) => p['id'] == planId)['features'].map((feature) => 
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              ),
            ).toList(),
            const SizedBox(height: 16),
            const Text(
              'Note: You will be charged monthly. You can cancel anytime.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processSubscription(planId);
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  Future<void> _processSubscription(String planId) async {
    try {
      // Update user subscription in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'subscriptionPlan': planId,
        'planExpiry': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'subscriptionDate': FieldValue.serverTimestamp(),
      });

      // Add subscription record
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .add({
        'userId': user!.uid,
        'planId': planId,
        'amount': _plans.firstWhere((p) => p['id'] == planId)['price'],
        'status': 'active',
        'startDate': FieldValue.serverTimestamp(),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully subscribed to ${_getPlanName(planId)}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing subscription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 