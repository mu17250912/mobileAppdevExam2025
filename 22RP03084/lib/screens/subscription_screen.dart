import 'package:flutter/material.dart';
import '../payment/hdev_payment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../utils/payment_utils.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _statusMessage;
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        _subscribed = (data['subscriptionStatus'] ?? '') == 'active';
      });
    }
  }

  Future<void> _startPayment(String plan, int amount, int durationDays) async {
    setState(() { _loading = true; _statusMessage = 'Initiating payment...'; });
    final phone = _phoneController.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (phone.isEmpty) {
      setState(() { _loading = false; _statusMessage = 'Enter your phone number.'; });
      return;
    }
    // Use HdevPayment Dart class
    final hdevPayment = HdevPayment(apiId: 'YOUR_API_ID', apiKey: 'YOUR_API_KEY');
    final transactionRef = uid + DateTime.now().millisecondsSinceEpoch.toString();
    final result = await hdevPayment.pay(
      tel: phone,
      amount: amount.toString(),
      transactionRef: transactionRef,
    );
    if (result != null && result['status'] == 'success') {
      setState(() { _statusMessage = 'Payment request sent. Please approve on your phone.'; });
      // Optionally poll for payment confirmation using getPay
      // final statusResult = await hdevPayment.getPay(transactionRef: transactionRef);
      // if (statusResult != null && statusResult['status'] == 'success') {
      //   // Payment confirmed
      // }
      final expiry = DateTime.now().add(Duration(days: durationDays));
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'subscriptionStatus': 'active',
        'subscriptionType': plan,
        'subscriptionExpiry': expiry,
      }, SetOptions(merge: true));
      setState(() { _subscribed = true; });
    } else {
      showPaymentError(context, result != null ? result['message'] : 'Payment failed.');
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: kGoldenBrown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subscribe for unlimited messages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_subscribed)
              Text('You are already subscribed!', style: TextStyle(color: Colors.green, fontSize: 16)),
            if (!_subscribed) ...[
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Text('Choose a plan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
                onPressed: _loading ? null : () => _startPayment('weekly', 1500, 7),
                child: _loading ? CircularProgressIndicator(color: Colors.white) : Text('Weekly - 1,500 RWF'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
                onPressed: _loading ? null : () => _startPayment('monthly', 5000, 30),
                child: _loading ? CircularProgressIndicator(color: Colors.white) : Text('Monthly - 5,000 RWF'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
                onPressed: _loading ? null : () => _startPayment('annual', 40000, 365),
                child: _loading ? CircularProgressIndicator(color: Colors.white) : Text('Annual - 40,000 RWF'),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                Text(_statusMessage!, style: TextStyle(color: Colors.red)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
