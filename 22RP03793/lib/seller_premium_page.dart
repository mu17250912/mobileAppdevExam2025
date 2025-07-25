import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerPremiumPage extends StatefulWidget {
  @override
  State<SellerPremiumPage> createState() => _SellerPremiumPageState();
}

class _SellerPremiumPageState extends State<SellerPremiumPage> {
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

  Future<void> simulatePremiumPayment() async {
    setState(() {
      isPaying = true;
      resultMessage = null;
    });

    await Future.delayed(const Duration(seconds: 2)); // Simulate payment

    // Update Firestore: set isPremium to true and premiumUntil to 30 days from now
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final premiumUntil = DateTime.now().add(Duration(days: 30));
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isPremium': true,
        'premiumUntil': premiumUntil,
        'premiumPaymentMethod': paymentMethod,
        'premiumPaymentNumber': numberController.text.trim(),
      });
    }

    setState(() {
      isPaying = false;
      resultMessage = 'Congratulations! You are now a Premium Seller for 30 days.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upgrade to Premium')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 64),
            SizedBox(height: 16),
            Text('Become a Premium Seller!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Enjoy unlimited listings, advanced analytics, and featured placement for just \$9.99/month (demo).'),
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
                    label: Text('Pay Now (Demo)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                    onPressed: () {
                      if (numberController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter your number or email')),
                        );
                        return;
                      }
                      simulatePremiumPayment();
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