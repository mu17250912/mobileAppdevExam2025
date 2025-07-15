import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/analytics_service.dart';
import '../utils/lnpay_service.dart';
import '../utils/payment_tracker.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _loading = false;

  Future<void> _upgrade() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'isPremium': true,
    }, SetOptions(merge: true));
    await AnalyticsService.logUpgradeToPremium();
    if (!mounted) return;
    setState(() => _loading = false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: const Text('You are now a Premium user!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _buyCoinsWithMTN() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Simulate payment process
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MTN Mobile Money Payment'),
        content: const Text('Simulate payment of 2000 Frw for 50 Frw coins?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pay')),
        ],
      ),
    );
    if (confirmed == true) {
      // Add 50 coins to user
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final coins = (userDoc.data()?['coins'] ?? 0) + 50;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'coins': coins,
      }, SetOptions(merge: true));
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Successful'),
            content: const Text('You have received 50 Frw coins!'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _payWithMTN() async {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final phoneResult = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MTN Mobile Money Payment'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone Number'),
            validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(context, true);
          }, child: const Text('Continue')),
        ],
      ),
    );
    if (phoneResult == true) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Payment'),
          content: const Text('You will be charged 2000 Frw via MTN Mobile Money for 1 week of premium access. Do you want to continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pay Now')),
          ],
        ),
      );
      if (confirm == true) {
        setState(() => _loading = true);
        try {
          // Create payment record and initiate payment
          final paymentId = await PaymentTracker().createPaymentRecord(
            amount: 2000,
            phone: phoneController.text.trim(),
            network: 'mtn',
          );
          await PaymentTracker().processPayment(
            amount: 2000,
            phone: phoneController.text.trim(),
            network: 'mtn',
          );
          // Show progress dialog and poll for payment status
          bool isPaid = false;
          int attempts = 0;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Processing Payment'),
              content: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Waiting for payment confirmation...'),
                    ],
                  );
                },
              ),
            ),
          );
          while (!isPaid && attempts < 12) {
            await Future.delayed(const Duration(seconds: 10));
            final latest = await PaymentTracker().getLatestPayment();
            if (latest != null && latest['status'] == 'completed') {
              isPaid = true;
              break;
            }
            attempts++;
          }
          Navigator.of(context, rootNavigator: true).pop(); // Close progress dialog
          if (isPaid) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Payment Successful'),
                  content: const Text('You are now a Premium user!'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ),
              );
            }
          } else {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Payment Timeout'),
                  content: const Text('Payment was not confirmed in time. If you have paid, please contact support.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Payment Failed'),
                content: Text('Error: $e'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
              ),
            );
          }
        } finally {
          setState(() => _loading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Premium')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 64),
              const SizedBox(height: 16),
              const Text('Premium Benefits', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('• Unlimited medications\n• Priority support\n• No ads (future)\n• Support app development!', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              _loading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _upgrade,
                          child: const Text('Simulate Payment & Upgrade'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _buyCoinsWithMTN,
                          icon: const Icon(Icons.phone_android),
                          label: const Text('Buy 50 Frw coins (MTN Mobile Money)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _payWithMTN,
                          icon: const Icon(Icons.payment),
                          label: const Text('Upgrade to Premium (MTN Mobile Money)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('This is a simulated MTN Mobile Money payment for demonstration purposes.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 