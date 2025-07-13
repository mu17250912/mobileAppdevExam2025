import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:flutterwave_standard/view/view_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Payment Method')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.blue),
            title: const Text('Pay with PayPal'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayPalPaymentScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.credit_card, color: Colors.purple),
            title: const Text('Pay with Stripe'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StripePaymentScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
            title: const Text('Pay with Flutterwave'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlutterwavePaymentScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone_android, color: Colors.green),
            title: const Text('Pay with MTN Mobile Money'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MTNMobileMoneyPaymentScreen())),
          ),
        ],
      ),
    );
  }
}

class PayPalPaymentScreen extends StatelessWidget {
  const PayPalPaymentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PayPal Payment')),
      body: const Center(child: Text('Integrate PayPal payment flow here.')),
    );
  }
}

class StripePaymentScreen extends StatelessWidget {
  const StripePaymentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stripe Payment')),
      body: const Center(child: Text('Integrate Stripe payment flow here.')),
    );
  }
}

class FlutterwavePaymentScreen extends StatefulWidget {
  const FlutterwavePaymentScreen({super.key});

  @override
  State<FlutterwavePaymentScreen> createState() => _FlutterwavePaymentScreenState();
}

class _FlutterwavePaymentScreenState extends State<FlutterwavePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String amount = '';
  String fullName = '';

  // Replace with your test keys
  final String publicKey = "FLWPUBK-xxxxxxxxxxxxxxxxxxxxx-X";
  final String encryptionKey = "FLWSECK-xxxxxxxxxxxxxxxxxxxxx-X";
  final String currency = "RWF"; // or "USD", "NGN", etc.

  void _startPayment() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final Customer customer = Customer(
      name: fullName,
      phoneNumber: "",
      email: email,
    );

    final Flutterwave flutterwave = Flutterwave(
      context: context,
      publicKey: publicKey,
      currency: currency,
      redirectUrl: "https://www.google.com",
      txRef: "TX- [200~ [200~${DateTime.now().millisecondsSinceEpoch}",
      amount: amount,
      customer: customer,
      paymentOptions: "card, mobilemoneyrwanda, ussd",
      customization: Customization(title: "KaziLink Premium"),
      isTestMode: true,
      encryptionKey: encryptionKey,
    );

    final ChargeResponse response = await flutterwave.charge();
    if (response != null && response.status == "success") {
      // Update Firestore to mark user as premium
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'premium': true,
          'premiumPaidAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment successful! You are now premium.")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed or cancelled.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutterwave Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Full Name"),
                onSaved: (v) => fullName = v ?? '',
                validator: (v) => v == null || v.isEmpty ? "Enter your name" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Email"),
                onSaved: (v) => email = v ?? '',
                validator: (v) => v == null || v.isEmpty ? "Enter your email" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
                onSaved: (v) => amount = v ?? '',
                validator: (v) => v == null || v.isEmpty ? "Enter amount" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startPayment,
                child: const Text("Pay with Flutterwave"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MTNMobileMoneyPaymentScreen extends StatelessWidget {
  const MTNMobileMoneyPaymentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MTN Mobile Money Payment')),
      body: const Center(child: Text('Integrate MTN Mobile Money payment flow here.')),
    );
  }
}