import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kGoldenBrown = Color(0xFFB6862C);

/// Dart class for HDEV Payment Gateway API integration.
class HdevPayment {
  final String apiId;
  final String apiKey;

  HdevPayment({required this.apiId, required this.apiKey});

  /// Initiate a payment request
  Future<Map<String, dynamic>?> pay({
    required String tel,
    required String amount,
    required String transactionRef,
    String link = '',
  }) async {
    final url = 'https://payment.hdevtech.cloud/api_pay/api/$apiId/$apiKey';
    final response = await http.post(
      Uri.parse(url),
      body: {
        'ref': 'pay',
        'tel': tel,
        'tx_ref': transactionRef,
        'amount': amount,
        'link': link,
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Check payment status
  Future<Map<String, dynamic>?> getPay({
    required String transactionRef,
  }) async {
    final url = 'https://payment.hdevtech.cloud/api_pay/api/$apiId/$apiKey';
    final response = await http.post(
      Uri.parse(url),
      body: {
        'ref': 'read',
        'tx_ref': transactionRef,
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

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
    _listenToSubscriptionChanges();
  }

  void _listenToSubscriptionChanges() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final subscriptionStatus = data['subscriptionStatus'] as String?;
        final subscriptionExpiry = data['subscriptionExpiry'] as Timestamp?;

        bool isActive = false;
        if (subscriptionStatus == 'active' && subscriptionExpiry != null) {
          final expiryDate = subscriptionExpiry.toDate();
          final now = DateTime.now();
          isActive = expiryDate.isAfter(now);
        }

        if (mounted) {
          setState(() {
            _subscribed = isActive;
          });
        }
      }
    });
  }

  Future<void> _checkSubscription() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        _subscribed = (data['subscriptionStatus'] ?? '') == 'active';
      });
    }
  }

  Future<void> _startPayment(String plan, int amount, int durationDays) async {
    setState(() {
      _loading = true;
      _statusMessage = 'Initiating payment...';
    });
    final phone = _phoneController.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (phone.isEmpty) {
      setState(() {
        _loading = false;
        _statusMessage = 'Enter your phone number.';
      });
      return;
    }
    final hdevPayment = HdevPayment(
      apiId: 'HDEV-2f7b3554-eb27-477b-8ebb-2ca799f03412-ID',
      apiKey: 'HDEV-28407ece-5d24-438d-a9e8-73105c905a7d-KEY',
    );
    final transactionRef =
        uid + DateTime.now().millisecondsSinceEpoch.toString();
    final result = await hdevPayment.pay(
      tel: phone,
      amount: amount.toString(),
      transactionRef: transactionRef,
    );
    if (result != null && result['status'] == 'success') {
      setState(() {
        _statusMessage = 'Payment request sent. Please approve on your phone.';
      });
      final expiry = DateTime.now().add(Duration(days: durationDays));
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'subscriptionStatus': 'active',
        'subscriptionType': plan,
        'subscriptionExpiry': expiry,
      }, SetOptions(merge: true));
      setState(() {
        _subscribed = true;
      });

      // Show success message and navigate to home
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to home screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          }
        });
      }
    } else {
      setState(() {
        _statusMessage = result != null && result['message'] != null
            ? 'Payment failed: ${result['message']}'
            : 'Payment failed. Try again.';
      });
    }
    setState(() {
      _loading = false;
    });
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
            const Text(
              'Subscribe for unlimited messages',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_subscribed) ...[
              const Text(
                'You are already subscribed!',
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
                child: const Text('Continue to App'),
              ),
            ],
            if (!_subscribed) ...[
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose a plan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
                onPressed: _loading ? null : () => _startPayment('daily', 5, 1),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Daily - 5 RWF'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
                onPressed:
                    _loading ? null : () => _startPayment('weekly', 30, 7),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Weekly - 30 RWF'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
                onPressed:
                    _loading ? null : () => _startPayment('monthly', 100, 30),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Monthly - 100 RWF'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
                onPressed:
                    _loading ? null : () => _startPayment('annual', 1000, 365),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Annual - 1,000 RWF'),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                Text(_statusMessage!,
                    style: const TextStyle(color: Colors.red)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
