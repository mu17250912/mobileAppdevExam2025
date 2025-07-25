import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerSubscriptionPage extends StatefulWidget {
  @override
  State<SellerSubscriptionPage> createState() => _SellerSubscriptionPageState();
}

class _SellerSubscriptionPageState extends State<SellerSubscriptionPage> {
  String plan = 'monthly';
  String paymentMethod = 'PayPal';
  final TextEditingController numberController = TextEditingController();
  bool isPaying = false;
  String? resultMessage;

  final List<String> paymentMethods = [
    'PayPal',
    'MTN Mobile Money',
    'Airtel Money',
  ];

  String get inputLabel {
    if (paymentMethod == 'PayPal') return 'PayPal Email';
    return 'Phone Number';
  }

  double get price => plan == 'monthly' ? 9.99 : 99.99;
  int get durationDays => plan == 'monthly' ? 30 : 365;

  Future<void> simulateSubscriptionPayment() async {
    setState(() {
      isPaying = true;
      resultMessage = null;
    });

    await Future.delayed(const Duration(seconds: 2)); // Simulate payment

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final subscriptionUntil = DateTime.now().add(Duration(days: durationDays));
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'subscriptionTier': 'gold',
        'subscriptionPlan': plan,
        'subscriptionUntil': subscriptionUntil,
        'subscriptionPaymentMethod': paymentMethod,
        'subscriptionPaymentNumber': numberController.text.trim(),
      });
    }

    setState(() {
      isPaying = false;
      resultMessage = 'Subscription successful! You are now on the $plan plan.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose Subscription Plan')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 64),
            SizedBox(height: 16),
            Text('Choose Your Plan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ToggleButtons(
              isSelected: [plan == 'monthly', plan == 'annual'],
              onPressed: (index) {
                setState(() {
                  plan = index == 0 ? 'monthly' : 'annual';
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Monthly (\$9.99)'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Annual (\$99.99)'),
                ),
              ],
            ),
            SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: paymentMethod,
              items: paymentMethods.map((method) => DropdownMenuItem(
                value: method,
                child: Text(method),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  paymentMethod = value!;
                  numberController.clear();
                });
              },
              decoration: const InputDecoration(labelText: 'Payment Method'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: numberController,
              keyboardType: paymentMethod == 'PayPal' ? TextInputType.emailAddress : TextInputType.phone,
              decoration: InputDecoration(
                labelText: inputLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            isPaying
                ? CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: Icon(Icons.payment),
                    label: Text('Pay \$${price.toStringAsFixed(2)} (Demo)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                    onPressed: () {
                      if (numberController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter your number or email')),
                        );
                        return;
                      }
                      simulateSubscriptionPayment();
                    },
                  ),
            if (resultMessage != null) ...[
              SizedBox(height: 24),
              Text(resultMessage!, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back to Dashboard'),
              ),
            ]
          ],
        ),
      ),
    );
  }
} 