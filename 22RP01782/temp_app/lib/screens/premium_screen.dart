// lib/screens/premium_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'simulated_payment_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isPremiumUser = false;
  bool _isLoading = true;
  final InAppPurchase _iap = InAppPurchase.instance;
  final String _premiumProductId = 'premium_access';
  List<ProductDetails> _products = [];
  bool _purchasePending = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _initializeIAP();
  }

  Future<void> _checkPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _isPremiumUser = doc.data()?['premium'] ?? false;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isPremiumUser = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeIAP() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    final response = await _iap.queryProductDetails({_premiumProductId});
    if (response.notFoundIDs.isEmpty && response.productDetails.isNotEmpty) {
      setState(() {
        _products = response.productDetails.toList();
      });
    }
    _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'premium': true,
              'premiumPurchaseDate': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            setState(() {
              _isPremiumUser = true;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Premium access unlocked!')),
            );
          }
        }
      }
    });
  }

  Future<void> _buyPremium() async {
    if (_products.isEmpty) return;
    final product = _products.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    setState(() => _purchasePending = true);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    setState(() => _purchasePending = false);
  }

  Future<void> _simulatePurchase() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SimulatedPaymentScreen()),
    );

    if (!mounted) return;

    if (result == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _isLoading = true);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'premium': true,
        'premiumPurchaseDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _isPremiumUser = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium access unlocked!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cancelled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Go Premium')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Go Premium')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Unlock premium features:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_isPremiumUser)
              Card(
                color: Colors.green[100],
                child: const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('You already have Premium access'),
                ),
              )
            else
              if (_products.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _purchasePending ? null : _buyPremium,
                  icon: const Icon(Icons.lock_open),
                  label: Text(_purchasePending ? 'Processing...' : 'Buy Premium'),
                )
              else
                ElevatedButton.icon(
                  onPressed: _simulatePurchase,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Buy Premium (Simulated Payment)'),
                ),
          ],
        ),
      ),
    );
  }
}
