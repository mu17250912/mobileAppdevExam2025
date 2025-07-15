import 'package:flutter/material.dart';

class FeatureComparison extends StatelessWidget {
  const FeatureComparison({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Comparison',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureRow('Medication Reminders', true, true),
            _buildFeatureRow('Basic Analytics', true, true),
            _buildFeatureRow('Emergency Contacts', true, true),
            _buildFeatureRow('Caregiver Assignment', false, true),
            _buildFeatureRow('Detailed Analytics', false, true),
            _buildFeatureRow('Priority Notifications', false, true),
            _buildFeatureRow('Family Plan', false, true),
            _buildFeatureRow('Advanced Insights', false, true),
            _buildFeatureRow('Referral Rewards', false, true),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature, bool free, bool premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                free ? Icons.check : Icons.close,
                color: free ? Colors.green : Colors.red,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                premium ? Icons.check : Icons.close,
                color: premium ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 