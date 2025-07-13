import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import 'package:flutter/services.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? _selectedPlan;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _subscriptionPlans = [
    {
      'id': 'basic',
      'name': 'Basic',
      'price': 'Free',
      'period': 'Forever',
      'features': [
        'Up to 3 bookings per month',
        'Basic car selection',
        'Standard support',
        'No priority booking',
      ],
      'color': Colors.blue,
    },
    {
      'id': 'premium',
      'name': 'Premium',
      'price': r'FRW19.99',
      'period': 'per month',
      'features': [
        'Unlimited bookings',
        'Premium car selection',
        'Priority booking',
        '24/7 support',
        'Free cancellation',
        'Luxury car access',
      ],
      'color': Colors.orange,
      'popular': true,
    },
    {
      'id': 'pro',
      'name': 'Pro',
      'price': r'FRW49.99',
      'period': 'per month',
      'features': [
        'Everything in Premium',
        'Exclusive car collection',
        'Personal concierge',
        'Custom decorations',
        'Event planning assistance',
        'VIP treatment',
      ],
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/available_cars_screen',
              (route) => false,
            );
          },
        ),
        title: const Text('Choose a Subscription Plan'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compare plans and subscribe for more benefits.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _subscriptionPlans.length,
                  itemBuilder: (context, index) {
                    final plan = _subscriptionPlans[index];
                    final isSelected = _selectedPlan == plan['id'];
                    final isPopular = plan['popular'] == true;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                            ? plan['color'] 
                            : theme.colorScheme.outline.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                                  color: plan['color'],
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'MOST POPULAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      plan['name'],
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: plan['color'],
                                      ),
                                    ),
                                    Radio<String>(
                                      value: plan['id'],
                                      groupValue: _selectedPlan,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPlan = value;
                                        });
                                      },
                                      activeColor: plan['color'],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      plan['price'],
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      plan['period'],
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...plan['features'].map<Widget>((feature) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: plan['color'],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedPlan != null) ...[
                FilledButton(
                  onPressed: _isProcessing ? null : _processSubscription,
                  style: FilledButton.styleFrom(
                    backgroundColor: _subscriptionPlans.firstWhere(
                      (plan) => plan['id'] == _selectedPlan
                    )['color'],
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('Subscribe Now'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cancel anytime. No commitment required.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showSimulatedPaymentDialog(double amount, String planName) async {
    String paymentMethod = 'card';
    final cardController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final phoneController = TextEditingController();
    bool isProcessing = false;
    bool paymentSuccess = false;
    String? error;
    bool isCardValid() {
      return cardController.text.length == 16 &&
        RegExp(r'^[0-9]{16}?$').hasMatch(cardController.text) &&
        RegExp(r'^[0-9]{2}/[0-9]{2}?$').hasMatch(expiryController.text) &&
        cvvController.text.length == 3 &&
        RegExp(r'^[0-9]{3}?$').hasMatch(cvvController.text);
    }
    bool isPhoneValid() {
      return phoneController.text.length >= 10 && phoneController.text.length <= 12 && RegExp(r'^[0-9]{10,12}?$').hasMatch(phoneController.text);
    }
    bool canPay() {
      if (paymentMethod == 'card') return isCardValid();
      if (paymentMethod == 'mobile') return isPhoneValid();
      return true;
    }
    final result = await showDialog(
      context: context,
      barrierDismissible: !isProcessing,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.payment, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Pay for $planName'),
                ],
              ),
              content: isProcessing
                  ? SizedBox(
                      height: 120,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 16),
                            Text('Processing payment...'),
                          ],
                        ),
                      ),
                    )
                  : paymentSuccess
                      ? SizedBox(
                          height: 120,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 64),
                                const SizedBox(height: 12),
                                Text('Payment successful!', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Amount: FRW${amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'card',
                                  groupValue: paymentMethod,
                                  onChanged: (v) => setState(() => paymentMethod = v!),
                                ),
                                const Icon(Icons.credit_card),
                                const SizedBox(width: 4),
                                const Text('Card'),
                                Radio<String>(
                                  value: 'mobile',
                                  groupValue: paymentMethod,
                                  onChanged: (v) => setState(() => paymentMethod = v!),
                                ),
                                const Icon(Icons.phone_android),
                                const SizedBox(width: 4),
                                const Text('Mobile Money'),
                              ],
                            ),
                            if (paymentMethod == 'card') ...[
                              TextField(
                                controller: cardController,
                                decoration: const InputDecoration(labelText: 'Card Number'),
                                keyboardType: TextInputType.number,
                                maxLength: 16,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: expiryController,
                                      decoration: const InputDecoration(labelText: 'MM/YY'),
                                      keyboardType: TextInputType.number,
                                      maxLength: 5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: cvvController,
                                      decoration: const InputDecoration(labelText: 'CVV'),
                                      keyboardType: TextInputType.number,
                                      maxLength: 3,
                                    ),
                                  ),
                                ],
                              ),
                              if (error != null && paymentMethod == 'card')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                                ),
                            ] else ...[
                              TextField(
                                controller: phoneController,
                                decoration: const InputDecoration(labelText: 'Mobile Number'),
                                keyboardType: TextInputType.phone,
                                maxLength: 12,
                              ),
                              if (error != null && paymentMethod == 'mobile')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                                ),
                            ],
                          ],
                        ),
              actions: isProcessing || paymentSuccess
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: !canPay() || isProcessing ? null : () async {
                          setState(() => error = null);
                          if (paymentMethod == 'card' && !isCardValid()) {
                            setState(() => error = 'Enter valid card details.');
                            return;
                          }
                          if (paymentMethod == 'mobile' && !isPhoneValid()) {
                            setState(() => error = 'Enter a valid phone number.');
                            return;
                          }
                          setState(() => isProcessing = true);
                          await Future.delayed(const Duration(seconds: 2));
                          setState(() {
                            isProcessing = false;
                            paymentSuccess = true;
                          });
                          await Future.delayed(const Duration(seconds: 1));
                          Navigator.pop(context, true);
                        },
                        child: isProcessing
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                          : Text('Pay FRW${amount.toStringAsFixed(2)}'),
                      ),
                    ],
            );
          },
        );
      },
    );
    return result == true;
  }

  Future<void> _processSubscription() async {
    if (_selectedPlan == null) return;
    setState(() { _isProcessing = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      // Find plan details
      final plan = _subscriptionPlans.firstWhere((p) => p['id'] == _selectedPlan);
      final planName = plan['name'];
      final priceStr = plan['price'].toString().replaceAll(RegExp(r'[^\d.]'), '');
      final price = double.tryParse(priceStr) ?? 0;
      // Show simulated payment dialog
      final paid = await _showSimulatedPaymentDialog(price, planName);
      if (paid != true) {
        setState(() { _isProcessing = false; });
        return;
      }
      // Update user subscription in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'subscription': {
          'plan': _selectedPlan,
          'startDate': FieldValue.serverTimestamp(),
          'status': 'active',
        },
      }, SetOptions(merge: true));
      // After updating user subscription in Firestore, before showing the success dialog:
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'title': 'Subscription Activated',
        'message': 'Your subscription to the $planName plan is now active. Enjoy premium features!',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });
      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Subscription Successful!'),
            content: Text(
              'You have successfully subscribed to the $planName plan.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }
} 