import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/in_app_purchase_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({Key? key}) : super(key: key);

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  bool _isLoading = true;
  Map<String, bool> _hasFeatures = {};

  @override
  void initState() {
    super.initState();
    _initializePurchaseService();
  }

  Future<void> _initializePurchaseService() async {
    await _purchaseService.initialize();
    await _checkPremiumFeatures();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkPremiumFeatures() async {
    for (final featureId in InAppPurchaseService.premiumFeatures.keys) {
      final hasFeature = await _purchaseService.hasPremiumFeature(featureId);
      setState(() {
        _hasFeatures[featureId] = hasFeature;
      });
    }
  }

  Future<void> _purchaseFeature(String featureId) async {
    final products = _purchaseService.products;
    final product = products.firstWhere(
      (p) => p.id == featureId,
      orElse: () => throw Exception('Product not found'),
    );

    final success = await _purchaseService.purchaseProduct(product);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase initiated for ${InAppPurchaseService.premiumFeatures[featureId]!['name']}')),
      );
      await _checkPremiumFeatures();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase failed. Please try again.')),
      );
    }
  }

  Future<void> _promptPayment(String featureId) async {
    final feature = InAppPurchaseService.premiumFeatures[featureId]!;
    if (kIsWeb) {
      String paymentMethod = 'MTN';
      String phoneNumber = '';
      String? errorText;
      await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text('Mock Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Simulate payment for ${feature['name']} (${feature['price']})?'),
                  const SizedBox(height: 16),
                  const Text('Select payment method:'),
                  DropdownButton<String>(
                    value: paymentMethod,
                    items: [
                      DropdownMenuItem(value: 'MTN', child: Text('MTN')),
                      DropdownMenuItem(value: 'Airtel', child: Text('Airtel')),
                      DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        paymentMethod = val!;
                        errorText = null;
                      });
                    },
                  ),
                  if (paymentMethod == 'MTN') ...[
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'MTN Phone Number',
                        hintText: '07XXXXXXXX',
                        errorText: errorText,
                      ),
                      onChanged: (val) {
                        setState(() {
                          phoneNumber = val;
                          errorText = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (paymentMethod == 'MTN') {
                      if (phoneNumber.isEmpty || phoneNumber.length < 10) {
                        setState(() {
                          errorText = 'Enter a valid MTN number';
                        });
                        return;
                      }
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Pay'),
                ),
              ],
            ),
          );
        },
      ).then((result) {
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mock payment successful for ${feature['name']}!')),
          );
          setState(() {
            _hasFeatures[featureId] = true;
          });
        }
      });
    } else {
      // On mobile, proceed with real purchase
      await _purchaseFeature(featureId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unlock Premium Features',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enhance your BerwaStore experience with premium features',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ...InAppPurchaseService.premiumFeatures.entries.map((entry) {
                    final featureId = entry.key;
                    final feature = entry.value;
                    final hasFeature = _hasFeatures[featureId] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        feature['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        feature['description'],
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasFeature)
                                  const Icon(Icons.check_circle, color: Colors.green, size: 24)
                                else
                                  Text(
                                    feature['price'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...(feature['features'] as List<String>).map((featureText) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check, color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(featureText)),
                                ],
                              ),
                            )),
                            if (!hasFeature) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _promptPayment(featureId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('Purchase'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
} 