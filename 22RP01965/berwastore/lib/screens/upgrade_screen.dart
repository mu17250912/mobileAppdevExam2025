import 'package:flutter/material.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BerwaStore Premium',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'RWF 2,000/month',
              style: TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Premium Features:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('Unlimited product uploads'),
            _buildFeatureItem('Advanced sales analytics'),
            _buildFeatureItem('Priority customer support'),
            _buildFeatureItem('Export reports to Excel/PDF'),
            _buildFeatureItem('Bulk import/export functionality'),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Simulated Payment"),
                      content: const Text("Payment successful via MTN Mobile Money."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            // Unlock premium features here (simulate)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Upgraded to premium!")),
                            );
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Pop upgrade screen
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text("Upgrade Now (RWF 2,000)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recurring monthly payment. Cancel anytime.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text("Feature Comparison", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildComparisonRow('Product Upload Limit', '10', 'Unlimited'),
            _buildComparisonRow('Reports', 'Basic', 'Advanced Analytics'),
            _buildComparisonRow('Support', 'Email only', 'WhatsApp / Call'),
            _buildComparisonRow('Export', 'Not available', 'Excel/PDF'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, String free, String premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(feature)),
          Expanded(child: Text(free, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(premium, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
} 