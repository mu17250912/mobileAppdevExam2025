import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InAppPurchaseService {
  static const Set<String> _productIds = {
    'premium_analytics',
    'unlimited_products',
    'export_reports',
  };

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  // Premium features configuration
  static const Map<String, Map<String, dynamic>> premiumFeatures = {
    'premium_analytics': {
      'name': 'Premium Analytics',
      'description': 'Advanced stock reports and sales analytics',
      'price': 'RWF 1,000',
      'features': [
        'Advanced sales reports',
        'Stock forecasting',
        'Customer analytics',
        'Revenue trends'
      ]
    },
    'unlimited_products': {
      'name': 'Unlimited Products',
      'description': 'Add unlimited products to your store',
      'price': 'RWF 2,000',
      'features': [
        'No product limit',
        'Bulk import/export',
        'Advanced product categories',
        'Product variants'
      ]
    },
    'export_reports': {
      'name': 'Export Reports',
      'description': 'Export data to Excel and PDF',
      'price': 'RWF 800',
      'features': [
        'Excel export',
        'PDF reports',
        'Data backup',
        'Custom reports'
      ]
    },
  };

  Future<void> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      if (_isAvailable) {
        final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint('Products not found: ${response.notFoundIDs}');
        }
        _products = response.productDetails;
        
        // Listen to purchase updates
        _subscription = _inAppPurchase.purchaseStream.listen(
          _handlePurchaseUpdates,
          onDone: () => _subscription?.cancel(),
          onError: (error) => debugPrint('Purchase stream error: $error'),
        );
      }
    } catch (e) {
      debugPrint('Error initializing in-app purchases: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        _unlockPremiumFeature(purchase.productID);
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
      }
    }
  }

  Future<void> _unlockPremiumFeature(String productId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'premiumFeatures': FieldValue.arrayUnion([productId]),
        'lastPurchase': FieldValue.serverTimestamp(),
      });

      debugPrint('Premium feature unlocked: $productId');
    } catch (e) {
      debugPrint('Error unlocking premium feature: $e');
    }
  }

  Future<bool> purchaseProduct(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      bool success = false;
      if (product.id.contains('analytics') || product.id.contains('unlimited') || 
          product.id.contains('export')) {
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        success = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }

      return success;
    } catch (e) {
      debugPrint('Error purchasing product: $e');
      return false;
    }
  }

  Future<bool> hasPremiumFeature(String featureId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final premiumFeatures = List<String>.from(doc.data()?['premiumFeatures'] ?? []);
      return premiumFeatures.contains(featureId);
    } catch (e) {
      debugPrint('Error checking premium feature: $e');
      return false;
    }
  }

  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;

  void dispose() {
    _subscription?.cancel();
  }
} 