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
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: kGoldenBrown,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 48 : 24, vertical: isTablet ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient header with icon
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 32 : 20, horizontal: 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kGoldenBrown, Colors.orange.shade200],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.mobile_friendly,
                          size: isTablet ? 64 : 44, color: Colors.white),
                      const SizedBox(height: 10),
                      const Text(
                        'Subscribe for unlimited messages',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_subscribed) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.verified,
                            color: Colors.green, size: 36),
                        const SizedBox(height: 8),
                        const Text(
                          'You are already subscribed!',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(double.infinity, 48)),
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/home'),
                          icon: const Icon(Icons.home),
                          label: const Text('Continue to App'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!_subscribed) ...[
                  const Text(
                    'Enter your mobile number:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose a plan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 12),
                  // Plan cards
                  _buildPlanCard(
                    context,
                    icon: Icons.calendar_view_day,
                    title: 'Daily',
                    price: '5 RWF',
                    duration: '1 day',
                    onPressed:
                        _loading ? null : () => _startPayment('daily', 5, 1),
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    context,
                    icon: Icons.calendar_view_week,
                    title: 'Weekly',
                    price: '30 RWF',
                    duration: '7 days',
                    onPressed:
                        _loading ? null : () => _startPayment('weekly', 30, 7),
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    context,
                    icon: Icons.calendar_month,
                    title: 'Monthly',
                    price: '100 RWF',
                    duration: '30 days',
                    onPressed: _loading
                        ? null
                        : () => _startPayment('monthly', 100, 30),
                  ),
                  const SizedBox(height: 24),
                  if (_statusMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_statusMessage!,
                                style: const TextStyle(fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String price,
      required String duration,
      required VoidCallback? onPressed}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 36, color: kGoldenBrown),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('$price • $duration',
                      style:
                          const TextStyle(fontSize: 15, color: Colors.black54)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kGoldenBrown,
                minimumSize: const Size(90, 40),
              ),
              onPressed: onPressed,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Subscribe'),
            ),
          ],
        ),
      ),
    );
  }
}
