import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/premium_provider.dart';
import '../services/payment_service.dart';
import '../theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PaymentService _paymentService = PaymentService();
  String? _selectedPlan;
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Premium', style: AppTextStyles.heading),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<PremiumProvider>(
        builder: (context, premiumProvider, child) {
          if (premiumProvider.isPremium) {
            return _buildPremiumActiveView(premiumProvider);
          }
          return _buildPremiumPlansView();
        },
      ),
    );
  }

  Widget _buildPremiumActiveView(PremiumProvider premiumProvider) {
    final status = premiumProvider.getPremiumStatus();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Premium Status Card
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.amber[600]!, Colors.amber[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.star,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Premium Active!',
                    style: AppTextStyles.heading.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plan: ${status['plan'] ?? 'Unknown'}',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (status['daysRemaining'] > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${status['daysRemaining']} days remaining',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Premium Features
          Text(
            'Your Premium Features',
            style: AppTextStyles.subheading.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...premiumProvider.getPremiumFeatures().map((feature) => 
            _buildFeatureCard(feature, true)
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showExtendPremiumDialog(premiumProvider),
                  icon: const Icon(Icons.add),
                  label: const Text('Extend Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRemovePremiumDialog(premiumProvider),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Remove Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPlansView() {
    final plans = _paymentService.getPremiumPlans();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.amber[600]!, Colors.amber[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.star,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upgrade to Premium',
                    style: AppTextStyles.heading.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock all features and remove limitations',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Features Comparison
          Text(
            'Premium Features',
            style: AppTextStyles.subheading.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeaturesComparison(),
          const SizedBox(height: 24),

          // Plans
          Text(
            'Choose Your Plan',
            style: AppTextStyles.subheading.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...plans.entries.map((entry) => _buildPlanCard(entry.key, entry.value)),
          const SizedBox(height: 24),

          // Payment Method
          if (_selectedPlan != null) ...[
            Text(
              'Payment Method',
              style: AppTextStyles.subheading.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodSelector(),
            const SizedBox(height: 24),

            // Upgrade Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Upgrade Now',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],

          // Free Trial Info
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Start with a 7-day free trial. Cancel anytime.',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesComparison() {
    final features = [
      {'name': 'Unlimited Tasks', 'free': false, 'premium': true},
      {'name': 'Advanced Analytics', 'free': false, 'premium': true},
      {'name': 'Custom Themes', 'free': false, 'premium': true},
      {'name': 'Ad-Free Experience', 'free': false, 'premium': true},
      {'name': 'Cloud Backup', 'free': false, 'premium': true},
      {'name': 'Priority Support', 'free': false, 'premium': true},
      {'name': 'Export Data', 'free': false, 'premium': true},
      {'name': 'Study Reminders', 'free': true, 'premium': true},
      {'name': 'Basic Progress Tracking', 'free': true, 'premium': true},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Feature',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Free',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Premium',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const Divider(),
            // Features
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      feature['name'] as String,
                      style: AppTextStyles.body,
                    ),
                  ),
                  Expanded(
                    child: Icon(
                      feature['free'] as bool ? Icons.check : Icons.close,
                      color: feature['free'] as bool ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Icon(
                      feature['premium'] as bool ? Icons.check : Icons.close,
                      color: feature['premium'] as bool ? Colors.green : Colors.red,
                      size: 20,
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

  Widget _buildFeatureCard(Map<String, dynamic> feature, bool isActive) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          feature['icon'] as IconData,
          color: isActive ? Colors.green : Colors.grey,
          size: 28,
        ),
        title: Text(
          feature['name'] as String,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          feature['description'] as String,
          style: AppTextStyles.body.copyWith(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          isActive ? Icons.check_circle : Icons.lock,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPlanCard(String planId, Map<String, dynamic> plan) {
    final isSelected = _selectedPlan == planId;
    final isPopular = planId == 'yearly';
    
    return Card(
      elevation: isSelected ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected 
            ? BorderSide(color: Colors.amber[600]!, width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[600],
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          InkWell(
            onTap: () {
              setState(() {
                _selectedPlan = planId;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plan['name'],
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Colors.amber[600],
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${plan['price']}',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 32,
                          color: Colors.amber[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        planId == 'monthly' ? '/month' : planId == 'yearly' ? '/year' : '',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (planId == 'yearly') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Save 33%',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ...(plan['features'] as List<String>).map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final paymentMethods = _paymentService.getPaymentMethods();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: paymentMethods.map((method) => RadioListTile<String>(
            title: Text(method),
            value: method,
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
            activeColor: Colors.amber[600],
          )).toList(),
        ),
      ),
    );
  }

  void _showExtendPremiumDialog(PremiumProvider premiumProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How many additional days would you like to add?'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Days',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                final days = int.tryParse(value);
                if (days != null && days > 0) {
                  premiumProvider.extendPremium(days);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle extension
              Navigator.pop(context);
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  void _showRemovePremiumDialog(PremiumProvider premiumProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Premium'),
        content: const Text(
          'Are you sure you want to remove premium? You will lose access to all premium features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await premiumProvider.removePremium();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _processUpgrade() async {
    if (_selectedPlan == null || _selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan and payment method')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      final result = await _paymentService.processPayment(
        planId: _selectedPlan!,
        paymentMethod: _selectedPaymentMethod!,
        cardNumber: '1234567890123456',
        expiryDate: '12/25',
        cvv: '123',
      );

      if (result.success) {
        final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
        await premiumProvider.upgradeToPremium(plan: _selectedPlan!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium upgrade successful!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
} 