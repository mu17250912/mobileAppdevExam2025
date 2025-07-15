import 'package:flutter/material.dart';
import '../services/premium_service.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  // final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  // List<ProductDetails> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // _initializeStore();
  }

  // Future<void> _initializeStore() async {
  //   try {
  //     final bool available = await _inAppPurchase.isAvailable();
  //     if (!available) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       return;
  //     }

  //     const Set<String> _kIds = <String>{
  //       'premium_monthly',
  //       'premium_yearly',
  //     };

  //     final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_kIds);
  //     if (response.notFoundIDs.isNotEmpty) {
  //       // Handle products not found
  //     }

  //     setState(() {
  //       _products = response.productDetails;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  // Future<void> _buyProduct(ProductDetails product) async {
  //   try {
  //     final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
  //     await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  //   } catch (e) {
  //     // Handle purchase error
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        backgroundColor: Colors.indigo[400],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.star,
                    size: 60,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unlock Premium Features',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Take your health journey to the next level',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Features Section
            const Text(
              'Premium Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // Feature Cards
            _buildFeatureCard(
              icon: Icons.calculate,
              title: 'Unlimited BMI Calculations',
              description: 'Calculate your BMI as many times as you want, no daily limits.',
              color: Colors.blue,
            ),
            
            _buildFeatureCard(
              icon: Icons.recommend,
              title: 'Personalized Health Advice',
              description: 'Get customized meal plans and exercise recommendations based on your BMI.',
              color: Colors.green,
            ),
            
            _buildFeatureCard(
              icon: Icons.analytics,
              title: 'Advanced Analytics',
              description: 'Detailed progress tracking with charts and trend analysis.',
              color: Colors.orange,
            ),
            
            _buildFeatureCard(
              icon: Icons.download,
              title: 'Data Export',
              description: 'Export your health data in JSON format for backup and analysis.',
              color: Colors.purple,
            ),
            
            _buildFeatureCard(
              icon: Icons.support_agent,
              title: 'Priority Support',
              description: 'Get faster response times and dedicated customer support.',
              color: Colors.red,
            ),
            
            const SizedBox(height: 32),
            
            // Pricing Section
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Special Offer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Only \$4.99/month',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cancel anytime • 7-day free trial',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Upgrade Button
            ElevatedButton(
              onPressed: () {
                _handleUpgrade();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text('Start Free Trial'),
            ),
            
            const SizedBox(height: 16),
            
            // Terms
            const Text(
              'By upgrading, you agree to our Terms of Service and Privacy Policy. You can cancel your subscription at any time.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Upgrading to Premium...'),
          ],
        ),
      ),
    );

    // Check which premium feature to unlock based on context
    // For now, unlock both features when upgrading
    await PremiumService.upgradeToCalculationsPremium();
    await PremiumService.upgradeToAdvicePremium();
    
    // Close loading dialog
    Navigator.of(context).pop();
    
    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Upgrade Successful!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to FitTrack Premium! 🎉',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('You now have access to:'),
            SizedBox(height: 4),
            Text('• Unlimited BMI calculations'),
            Text('• Personalized health advice'),
            Text('• Advanced analytics'),
            Text('• Data export functionality'),
            Text('• Priority support'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Go back to previous screen with result
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Start Using Premium Features'),
          ),
        ],
      ),
    );
  }
} 