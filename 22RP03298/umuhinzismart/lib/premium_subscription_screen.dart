import 'package:flutter/material.dart';
import 'services/premium_service.dart';
import 'services/analytics_service.dart';
import 'services/mtn_mobile_money_service.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  final String username;
  
  const PremiumSubscriptionScreen({
    super.key,
    required this.username,
  });

  @override
  State<PremiumSubscriptionScreen> createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  bool _isLoading = false;
  String? _selectedPlan;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AnalyticsService.trackScreenView('premium_subscription_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Current Status
            _buildCurrentStatus(),
            const SizedBox(height: 24),
            
            // Subscription Plans
            _buildSubscriptionPlans(),
            const SizedBox(height: 24),
            
            // Premium Features
            _buildPremiumFeatures(),
            const SizedBox(height: 24),
            
            // Error Message
            if (_errorMessage != null) _buildErrorMessage(),
            
            // Subscribe Button
            if (_selectedPlan != null) _buildSubscribeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.star,
            size: 60,
            color: Colors.yellow,
          ),
          const SizedBox(height: 16),
          const Text(
            'Upgrade to Premium',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlock unlimited features and grow your business',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus() {
    return FutureBuilder<bool>(
      future: PremiumService.isPremiumUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final isPremium = snapshot.data ?? false;
        
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPremium ? Icons.check_circle : Icons.info_outline,
                      color: isPremium ? Colors.green : Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPremium ? 'Premium Active' : 'Current Plan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isPremium ? 'You are currently on a Premium subscription' : 'You are currently on the Basic (Free) plan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (isPremium) ...[
                  const SizedBox(height: 12),
                  FutureBuilder<int>(
                    future: PremiumService.getDaysRemaining(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final daysRemaining = snapshot.data!;
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: daysRemaining <= 7 ? Colors.orange[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: daysRemaining <= 7 ? Colors.orange[200]! : Colors.green[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: daysRemaining <= 7 ? Colors.orange : Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$daysRemaining days remaining',
                                style: TextStyle(
                                  color: daysRemaining <= 7 ? Colors.orange[700] : Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionPlans() {
    final plans = PremiumService.getSubscriptionPlans();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...plans.map((plan) => _buildPlanCard(plan)),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isSelected = _selectedPlan == plan.id;
    final isCurrentPlan = plan.id == 'basic'; // Basic is always available
    
    return Card(
      elevation: isSelected ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: Colors.deepPurple, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isCurrentPlan ? null : () {
          setState(() {
            _selectedPlan = plan.id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.deepPurple),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan.price == 0 ? 'Free' : 'RWF ${plan.price.toStringAsFixed(0)}/month',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: plan.price == 0 ? Colors.green : Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              ...plan.features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              )),
              if (plan.limitations.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                ...plan.limitations.map((limitation) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.close, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(limitation, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Premium Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: PremiumService.getPremiumFeatures().length,
          itemBuilder: (context, index) {
            final feature = PremiumService.getPremiumFeatures()[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getFeatureIcon(feature),
                      size: 32,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getFeatureIcon(String feature) {
    switch (feature.toLowerCase()) {
      case 'unlimited product listings':
        return Icons.inventory;
      case 'advanced analytics dashboard':
        return Icons.analytics;
      case 'priority customer support':
        return Icons.support_agent;
      case 'featured store placement':
        return Icons.star;
      case 'bulk order management tools':
        return Icons.list_alt;
      case 'express delivery options':
        return Icons.local_shipping;
      case 'custom store branding':
        return Icons.store;
      case 'advanced reporting':
        return Icons.assessment;
      case 'customer insights':
        return Icons.people;
      case 'marketing tools':
        return Icons.campaign;
      default:
        return Icons.featured_play_list;
    }
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _subscribeToPremium,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...'),
                ],
              )
            : const Text(
                'Subscribe Now',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _subscribeToPremium() async {
    if (_selectedPlan == null || _selectedPlan == 'basic') {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Premium Subscription'),
          content: const Text(
            'This will activate your Premium subscription for RWF 5,000/month. '
            'You will have unlimited product listings and access to advanced features. '
            'Do you want to proceed?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text('Subscribe'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Activate premium subscription
      final success = await PremiumService.subscribeToPremium(
        username: widget.username,
        plan: _selectedPlan!,
        amount: 5000, // RWF 5,000
        months: 1,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Premium subscription activated successfully! You now have unlimited product listings.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to activate subscription. Please try again.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Subscription failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 