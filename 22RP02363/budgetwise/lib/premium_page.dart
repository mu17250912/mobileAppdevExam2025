import 'package:flutter/material.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Features')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Upgrade to Premium!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'Unlock advanced features and remove ads. Choose your preferred plan:',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildPremiumOption(
                context,
                title: 'One-time Purchase',
                description: 'Pay once and enjoy premium features forever.',
                price: 'RWF 10,000',
                onPressed: () => _showPaymentDialog(context, 'One-time Purchase'),
              ),
              const SizedBox(height: 20),
              _buildPremiumOption(
                context,
                title: 'Monthly Subscription',
                description: 'Get premium features for a month. Renews automatically.',
                price: 'RWF 1,500/month',
                onPressed: () => _showPaymentDialog(context, 'Monthly Subscription'),
              ),
              const SizedBox(height: 20),
              _buildPremiumOption(
                context,
                title: 'Annual Subscription',
                description: 'Save more with a yearly plan.',
                price: 'RWF 15,000/year',
                onPressed: () => _showPaymentDialog(context, 'Annual Subscription'),
              ),
              const SizedBox(height: 20),
              _buildPremiumOption(
                context,
                title: 'Remove Ads',
                description: 'Enjoy an ad-free experience.',
                price: 'RWF 3,000 (one-time)',
                onPressed: () => _showPaymentDialog(context, 'Remove Ads'),
              ),
              const SizedBox(height: 32),
              Card(
                color: Colors.green[50],
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Freemium Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 8),
                      Text('• Free: Basic budgeting, expense tracking, and notifications.'),
                      Text('• Premium: Advanced reports, export, multi-device sync, and no ads.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumOption(BuildContext context, {required String title, required String description, required String price, required VoidCallback onPressed}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, String plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Simulated Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose a payment method for $plan:'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.phone_android),
              label: const Text('MTN Mobile Money (Simulated)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
              onPressed: () {
                Navigator.of(context).pop();
                _showMomoPhoneDialog(context);
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('PayPal (Simulated)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessDialog(context, 'PayPal');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMomoPhoneDialog(BuildContext context) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MTN Mobile Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your phone number:'),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.trim().isEmpty) return;
              Navigator.of(context).pop();
              _showSuccessDialog(context, 'MTN Mobile Money');
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful!'),
        content: Text('Thank you for upgrading with $method. Premium features are now unlocked (simulation).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 