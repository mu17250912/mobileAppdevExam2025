import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_provider.dart';
import '../models/subscription.dart';
import 'payment_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    // Load user subscription when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      if (userProvider.userProfile != null) {
        subscriptionProvider.loadUserSubscription(userProvider.userProfile!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Plans'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer2<SubscriptionProvider, UserProvider>(
        builder: (context, subscriptionProvider, userProvider, _) {
          if (subscriptionProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Subscription Status
                if (subscriptionProvider.hasActiveSubscription) ...[
                  _buildCurrentSubscriptionCard(subscriptionProvider),
                  SizedBox(height: 24),
                ],

                // Header
                Text(
                  'Choose Your Plan',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Unlock premium features and boost your productivity',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32),

                // Subscription Plans
                ...subscriptionProvider.availablePlans
                    .where((plan) => plan.type != SubscriptionType.free)
                    .map((plan) => _buildPlanCard(context, plan, subscriptionProvider, userProvider))
                    .toList(),

                SizedBox(height: 32),

                // Features Section
                _buildFeaturesSection(),

                SizedBox(height: 16),
                Text(
                  'This is a demo. Integrate real payment processing for production.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard(SubscriptionProvider subscriptionProvider) {
    final subscription = subscriptionProvider.currentSubscription;
    final statusText = subscriptionProvider.getSubscriptionStatusText();
    final progress = subscriptionProvider.getSubscriptionProgress();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription?.plan.name ?? 'Current Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (subscription != null && subscription.plan.type != SubscriptionType.free) ...[
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 8),
            Text(
              '${subscription.daysRemaining} days remaining',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionProvider subscriptionProvider,
    UserProvider userProvider,
  ) {
    final isCurrentPlan = subscriptionProvider.currentSubscription?.planId == plan.id;
    final isPopular = plan.isPopular;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isPopular ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isPopular
              ? BorderSide(color: Colors.blue.shade300, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          plan.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPopular)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'POPULAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 16),

              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${plan.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.type == SubscriptionType.annual ? '/year' : '/month',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (plan.originalPrice != null) ...[
                        Text(
                          'was \$${plan.originalPrice!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              if (plan.savingsPercentage != null) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Save ${plan.savingsPercentage!.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 20),

              // Features
              ...plan.features.map((feature) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),

              SizedBox(height: 20),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCurrentPlan
                      ? null
                      : () => _handleSubscribe(context, plan, subscriptionProvider, userProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentPlan ? Colors.grey : Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isCurrentPlan ? 'Current Plan' : 'Subscribe Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s included in all plans:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          _buildFeatureItem('✓ Unlimited tasks and notes'),
          _buildFeatureItem('✓ Premium calendar features'),
          _buildFeatureItem('✓ Advanced task categories'),
          _buildFeatureItem('✓ Priority customer support'),
          _buildFeatureItem('✓ Cloud sync across devices'),
          _buildFeatureItem('✓ Data export and backup'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  void _handleSubscribe(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionProvider subscriptionProvider,
    UserProvider userProvider,
  ) {
    if (userProvider.userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to subscribe')),
      );
      return;
    }

    // For demo purposes, create subscription directly
    // In production, this would go through payment processing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscribe to ${plan.name}'),
        content: Text('This is a demo. In production, this would process payment for \$${plan.price.toStringAsFixed(2)}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createDemoSubscription(plan, subscriptionProvider, userProvider);
            },
            child: Text('Subscribe (Demo)'),
          ),
        ],
      ),
    );
  }

  Future<void> _createDemoSubscription(
    SubscriptionPlan plan,
    SubscriptionProvider subscriptionProvider,
    UserProvider userProvider,
  ) async {
    try {
      await subscriptionProvider.createSubscription(
        userId: userProvider.userProfile!.uid,
        planId: plan.id,
        transactionId: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod: 'demo',
        amountPaid: plan.price,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully subscribed to ${plan.name}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to subscribe: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 