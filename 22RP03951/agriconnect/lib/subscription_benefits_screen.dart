import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class SubscriptionBenefitsScreen extends StatelessWidget {
  const SubscriptionBenefitsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Benefits'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentPlan(context),
            const SizedBox(height: 24),
            _buildBenefitsList(),
            const SizedBox(height: 24),
            _buildUpgradeSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlan(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Card(
          color: _getPlanColor(userProvider.subscriptionPlan).withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.card_membership,
                      color: _getPlanColor(userProvider.subscriptionPlan),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current Plan: ${userProvider.subscriptionPlan ?? 'Basic'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getPlanDescription(userProvider.subscriptionPlan),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plan Benefits',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildBenefitCard(
          'Basic Plan',
          'Free',
          [
            'Browse all products',
            'Basic order management',
            'Standard customer support',
            'Email notifications',
          ],
          Colors.grey,
        ),
        const SizedBox(height: 12),
        _buildBenefitCard(
          'Premium Plan',
          'Rwf 12,000/month',
          [
            'All Basic features',
            'Priority customer support',
            'Advanced analytics dashboard',
            'Premium product listings',
            'No commission fees',
            'Bulk order discounts',
            'Priority order processing',
          ],
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildBenefitCard(
          'Enterprise Plan',
          'Rwf 35,000/month',
          [
            'All Premium features',
            'Dedicated account manager',
            'Custom integrations',
            'White-label options',
            'Advanced reporting',
            'API access',
            'Custom branding',
            '24/7 priority support',
          ],
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildBenefitCard(String title, String price, List<String> features, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upgrade Your Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Unlock premium features to grow your business faster and more efficiently.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/subscription');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('View Subscription Plans'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlanColor(String? plan) {
    switch (plan) {
      case 'Premium':
        return Colors.green;
      case 'Enterprise':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getPlanDescription(String? plan) {
    switch (plan) {
      case 'Premium':
        return 'You have access to premium features including priority support and advanced analytics.';
      case 'Enterprise':
        return 'You have full access to all features including custom integrations and dedicated support.';
      default:
        return 'You have access to basic features. Consider upgrading for more benefits.';
    }
  }
} 