import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'analytics_service.dart';
import 'subscription_payment_instructions_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? selectedPlan;

  final List<Map<String, dynamic>> subscriptionPlans = [
    {
      'name': 'Basic',
      'price': 'Rwf 0',
      'period': 'Free',
      'features': [
        'Browse products',
        'Basic order management',
        'Standard support'
      ],
      'color': Colors.grey,
    },
    {
      'name': 'Premium',
      'price': 'Rwf 12,000',
      'period': 'per month',
      'features': [
        'All Basic features',
        'Priority customer support',
        'Advanced analytics',
        'Premium product listings',
        'No commission fees'
      ],
      'color': Colors.green,
    },
    {
      'name': 'Enterprise',
      'price': 'Rwf 35,000',
      'period': 'per month',
      'features': [
        'All Premium features',
        'Bulk order discounts',
        'Dedicated account manager',
        'Custom integrations',
        'White-label options'
      ],
      'color': Colors.blue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upgrade to unlock premium features and grow your business',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: subscriptionPlans.length,
                itemBuilder: (context, index) {
                  final plan = subscriptionPlans[index];
                  final isSelected = selectedPlan == plan['name'];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: isSelected ? 8 : 2,
                    color: isSelected ? plan['color'].withOpacity(0.1) : null,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedPlan = plan['name'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: isSelected
                              ? Border.all(color: plan['color'], width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  plan['name'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: plan['color'],
                                    size: 24,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  plan['price'],
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: plan['color'],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  plan['period'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...plan['features'].map<Widget>((feature) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check,
                                      color: plan['color'],
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
                              );
                            }).toList(),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: plan['name'] == 'Basic'
                                  ? ElevatedButton(
                                      onPressed: null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: plan['color'],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Current Plan'),
                                    )
                                  : ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SubscriptionPaymentInstructionsScreen(
                                              planName: plan['name'],
                                              planPrice: plan['price'],
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: plan['color'],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Subscribe'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Map<String, dynamic> plan) {
    if (plan['name'] == 'Basic') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already on the Basic plan'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Subscribe to ${plan['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Price: ${plan['price']} ${plan['period']}'),
              const SizedBox(height: 16),
              const Text(
                'This is a simulated payment. In a real app, this would integrate with payment gateways like Stripe, PayPal, or mobile money.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
                Navigator.of(context).pop();
                _processSubscription(plan);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: plan['color'],
                foregroundColor: Colors.white,
              ),
              child: const Text('Subscribe'),
            ),
          ],
        );
      },
    );
  }

  void _processSubscription(Map<String, dynamic> plan) {
    // Simulate payment processing
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing payment...'),
            ],
          ),
        );
      },
    );

    // Simulate payment delay
    Future.delayed(const Duration(seconds: 2), () async {
      Navigator.of(context).pop(); // Close loading dialog
      
      // Track subscription analytics
      double amount = 0.0;
      if (plan['name'] == 'Premium') amount = 12000.0;
      if (plan['name'] == 'Enterprise') amount = 35000.0;
      await AnalyticsService.trackSubscription(plan['name'], amount);
      
      // Update user subscription plan
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateSubscriptionPlan(plan['name']);
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Subscription Successful!'),
            content: Text('You have successfully subscribed to ${plan['name']} plan.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan['color'],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    });
  }
} 