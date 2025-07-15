import 'package:flutter/material.dart';

import '../services/monetization_service.dart';
import '../services/firebase_analytics_service.dart';
import '../widgets/subscription_card.dart';
import '../widgets/feature_comparison.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final MonetizationService _monetizationService = MonetizationService();
  final FirebaseAnalyticsService _analyticsService = FirebaseAnalyticsService();
  
  SubscriptionTier _currentTier = SubscriptionTier.free;
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _canStartFreeTrial = false;

  @override
  void initState() {
    super.initState();
    _initializeSubscription();
    _analyticsService.trackScreenView(screenName: 'subscription_screen');
  }

  Future<void> _initializeSubscription() async {
    try {
      await _monetizationService.initialize();
      
      // Listen to subscription changes
      _monetizationService.subscriptionStream.listen((tier) {
        setState(() {
          _currentTier = tier;
        });
      });

      // Listen to product updates
      _monetizationService.productsStream.listen((products) {
        setState(() {
          _products = products;
        });
      });

      // Check free trial eligibility
      final canStartTrial = await _monetizationService.canStartFreeTrial();
      setState(() {
        _canStartFreeTrial = canStartTrial;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load subscription options');
    }
  }

  Future<void> _startFreeTrial() async {
    try {
      setState(() {
        _isPurchasing = true;
      });

      final success = await _monetizationService.startFreeTrial();
      
      if (success) {
        _analyticsService.trackSubscriptionEvent(
          eventType: 'trial_started',
          tier: 'premium',
        );
        
        _showSuccessSnackBar('Free trial started! Enjoy premium features for 7 days.');
        setState(() {
          _canStartFreeTrial = false;
        });
      } else {
        _showErrorSnackBar('Failed to start free trial. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred while starting free trial');
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  Future<void> _purchaseSubscription(ProductDetails product) async {
    try {
      setState(() {
        _isPurchasing = true;
      });

      final success = await _monetizationService.purchaseSubscription(product);
      
      if (success) {
        _analyticsService.trackSubscriptionEvent(
          eventType: 'purchased',
          tier: _getTierFromProductId(product.id),
          productId: product.id,
          price: double.tryParse(product.price),
        );
        
        _showSuccessSnackBar('Subscription purchased successfully!');
      } else {
        _showErrorSnackBar('Purchase failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred during purchase');
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  String _getTierFromProductId(String productId) {
    if (productId.contains('family')) {
      return 'family';
    } else if (productId.contains('premium')) {
      return 'premium';
    }
    return 'free';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // Current subscription status
                  _buildCurrentStatus(),
                  const SizedBox(height: 24),
                  
                  // Free trial banner
                  if (_canStartFreeTrial) _buildFreeTrialBanner(),
                  if (_canStartFreeTrial) const SizedBox(height: 24),
                  
                  // Subscription plans
                  _buildSubscriptionPlans(),
                  const SizedBox(height: 24),
                  
                  // Feature comparison
                  _buildFeatureComparison(),
                  const SizedBox(height: 24),
                  
                  // Additional info
                  _buildAdditionalInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unlock advanced features and better medication management',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStatus() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (_currentTier) {
      case SubscriptionTier.free:
        statusText = 'Free Plan';
        statusColor = Colors.blue;
        statusIcon = Icons.person;
        break;
      case SubscriptionTier.premium:
        statusText = 'Premium Plan';
        statusColor = Colors.green;
        statusIcon = Icons.star;
        break;
      case SubscriptionTier.family:
        statusText = 'Family Plan';
        statusColor = Colors.purple;
        statusIcon = Icons.family_restroom;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeTrialBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.card_giftcard, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Trial Available!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Try premium features for 7 days, no commitment required',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isPurchasing ? null : _startFreeTrial,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade600,
            ),
            child: _isPurchasing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start Trial'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Plans',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Free Plan
        SubscriptionCard(
          title: 'Free',
          description: 'Basic medication management',
          price: 'Free',
          features: [
            'Up to 3 medications',
            'Basic reminders',
            'Simple adherence tracking',
            'Emergency contacts',
          ],
          isCurrent: _currentTier == SubscriptionTier.free,
          isPopular: false,
          onTap: null,
          isLoading: false,
        ),
        const SizedBox(height: 16),
        
        // Premium Plan
        if (_products.isNotEmpty)
          SubscriptionCard(
            title: 'Premium',
            description: 'Advanced features for individuals',
            price: _getProductPrice('premium'),
            features: [
              'Unlimited medications',
              'Caregiver assignment',
              'Detailed analytics',
              'Priority notifications',
              'Custom reminders',
              'Data export',
            ],
            isCurrent: _currentTier == SubscriptionTier.premium,
            isPopular: true,
            onTap: _currentTier != SubscriptionTier.premium
                ? () {
                    final product = _getProduct('premium');
                    if (product != null) {
                      _purchaseSubscription(product);
                    }
                  }
                : null,
            isLoading: _isPurchasing,
          ),
        if (_products.isNotEmpty) const SizedBox(height: 16),
        
        // Family Plan
        if (_products.isNotEmpty)
          SubscriptionCard(
            title: 'Family',
            description: 'Complete care for families',
            price: _getProductPrice('family'),
            features: [
              'All Premium features',
              'Unlimited caregivers',
              'Family sharing',
              'Multi-user profiles',
              'Advanced reports',
              'Priority support',
            ],
            isCurrent: _currentTier == SubscriptionTier.family,
            isPopular: false,
            onTap: _currentTier != SubscriptionTier.family
                ? () {
                    final product = _getProduct('family');
                    if (product != null) {
                      _purchaseSubscription(product);
                    }
                  }
                : null,
            isLoading: _isPurchasing,
          ),
      ],
    );
  }

  String _getProductPrice(String type) {
    final product = _getProduct(type);
    if (product != null) {
      return product.price;
    }
    return type == 'premium' ? '\$4.99/month' : '\$9.99/month';
  }

  ProductDetails? _getProduct(String type) {
    try {
      if (type == 'premium') {
        return _products.firstWhere((p) => p.id.contains('premium'));
      } else if (type == 'family') {
        return _products.firstWhere((p) => p.id.contains('family'));
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Widget _buildFeatureComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Comparison',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const FeatureComparison(),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildInfoCard(
          icon: Icons.security,
          title: 'Secure & Private',
          description: 'Your health data is encrypted and never shared with third parties.',
        ),
        const SizedBox(height: 16),
        
        _buildInfoCard(
          icon: Icons.cancel,
          title: 'Cancel Anytime',
          description: 'You can cancel your subscription at any time with no penalties.',
        ),
        const SizedBox(height: 16),
        
        _buildInfoCard(
          icon: Icons.support_agent,
          title: '24/7 Support',
          description: 'Get help whenever you need it with our dedicated support team.',
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 