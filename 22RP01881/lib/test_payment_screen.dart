import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mobile_money_payment.dart';
import 'simple_momo_payment.dart';
import 'premium_features_summary.dart';

class TestPaymentScreen extends StatefulWidget {
  const TestPaymentScreen({super.key});

  @override
  State<TestPaymentScreen> createState() => _TestPaymentScreenState();
}

class _TestPaymentScreenState extends State<TestPaymentScreen> {
  String selectedPaymentMethod = 'Mobile Money';
  double testAmount = 100.0;
  bool isProcessing = false;
  String? lastTestResult;

  final List<String> paymentMethods = [
    'Mobile Money',
    'Credit Card',
    'Bank Transfer',
    'PayPal',
    'Crypto',
  ];

  void _navigateToMobileMoneyPayment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileMoneyPaymentScreen(
          productId: 'premium_monthly',
          productName: 'Premium Subscription',
          amount: testAmount,
          currency: 'FRW',
        ),
      ),
    );
  }

  void _navigateToSimpleMoMoPayment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SimpleMoMoPaymentScreen(),
      ),
    );
  }

  Future<void> _simulatePayment() async {
    setState(() {
      isProcessing = true;
      lastTestResult = null;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Simulate random success/failure
    final bool success = DateTime.now().millisecondsSinceEpoch % 2 == 0;

    setState(() {
      isProcessing = false;
      lastTestResult = success ? 'Payment Successful!' : 'Payment Failed - Try Again';
    });

    if (success) {
      // Unlock premium features for successful test payment
      try {
        final premiumManager = PremiumFeaturesManager();
        await premiumManager.grantPremiumAccess('test_payment', 'test_${DateTime.now().millisecondsSinceEpoch}');
        print('Premium features unlocked for test payment');
      } catch (e) {
        print('Error unlocking premium features for test payment: $e');
      }
      _showSuccessDialog();
    } else {
      _showFailureDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Payment Success!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(
              'Test payment of ${testAmount.toStringAsFixed(0)} FRW was successful.',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Unlocked Features:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUnlockedFeature('🎯 Saving Goals & Tracking'),
                  _buildUnlockedFeature('🔔 Smart Reminders'),
                  _buildUnlockedFeature('📊 Advanced Reports'),
                  _buildUnlockedFeature('🤖 AI Insights'),
                  _buildUnlockedFeature('🏷️ Unlimited Categories'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Payment Failed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Test payment failed. This is expected behavior for testing.',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Options',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star,
                        size: 48,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Premium Subscription',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${testAmount.toStringAsFixed(0)} FRW',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '30 days of premium access',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Real Payment Options
              Text(
                'Choose Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Mobile Money Payment Button
              Card(
                child: InkWell(
                  onTap: _navigateToMobileMoneyPayment,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.phone_android,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mobile Money',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'MTN • Airtel Money',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Simple Mobile Money Payment Button
              Card(
                child: InkWell(
                  onTap: _navigateToSimpleMoMoPayment,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Simple Mobile Money',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quick and easy payment',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Test Payment Section
              Text(
                'Test Payment (Simulation)',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use this to test payment flows without real transactions',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              // Amount Selection for Test
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Amount',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: testAmount,
                              min: 1.0,
                              max: 1000.0,
                              divisions: 999,
                              label: '\$${testAmount.toStringAsFixed(2)}',
                              onChanged: (value) {
                                setState(() {
                                  testAmount = value;
                                });
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '\$${testAmount.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Test Result Display
              if (lastTestResult != null)
                Card(
                  color: lastTestResult!.contains('Success') ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          lastTestResult!.contains('Success') ? Icons.check_circle : Icons.error,
                          color: lastTestResult!.contains('Success') ? Colors.green : Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lastTestResult!,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: lastTestResult!.contains('Success') ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (lastTestResult != null) const SizedBox(height: 16),

              // Test Payment Button
              ElevatedButton(
                onPressed: isProcessing ? null : _simulatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : Text(
                        'Simulate Payment',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Quick Test Buttons
              Text(
                'Quick Tests',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickTestButton('Success', Colors.green, () async {
                    setState(() {
                      testAmount = 9.99;
                      lastTestResult = 'Payment Successful!';
                    });
                    // Unlock premium features for successful test
                    try {
                      final premiumManager = PremiumFeaturesManager();
                      await premiumManager.grantPremiumAccess('test_payment', 'quick_success_${DateTime.now().millisecondsSinceEpoch}');
                      print('Premium features unlocked for quick success test');
                    } catch (e) {
                      print('Error unlocking premium features for quick success test: $e');
                    }
                    _showSuccessDialog();
                  }),
                  _buildQuickTestButton('Failure', Colors.red, () {
                    setState(() {
                      testAmount = 5.00;
                      lastTestResult = 'Payment Failed - Try Again';
                    });
                    _showFailureDialog();
                  }),
                  _buildQuickTestButton('Network Error', Colors.orange, () {
                    setState(() {
                      testAmount = 15.00;
                      lastTestResult = 'Network Error - Check Connection';
                    });
                    _showNetworkErrorDialog();
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Back Button
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Back to App',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTestButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showNetworkErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Network Error',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              'Network connection error. Please check your internet connection and try again.',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade800,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
} 