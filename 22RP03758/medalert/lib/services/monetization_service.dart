import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';


enum SubscriptionTier {
  free,
  premium,
  family
}

enum PremiumFeature {
  caregiverAssignment,
  detailedAnalytics,
  priorityNotifications,
  unlimitedMedications,
  advancedReports,
  familySharing,
  customReminders,
  dataExport
}

class MonetizationService {
  static final MonetizationService _instance = MonetizationService._internal();
  factory MonetizationService() => _instance;
  MonetizationService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Product IDs
  static const String _premiumMonthlyId = 'medalert_premium_monthly';
  static const String _premiumYearlyId = 'medalert_premium_yearly';
  static const String _familyMonthlyId = 'medalert_family_monthly';
  static const String _familyYearlyId = 'medalert_family_yearly';

  // Stream controllers
  final StreamController<SubscriptionTier> _subscriptionController = 
      StreamController<SubscriptionTier>.broadcast();
  final StreamController<List<ProductDetails>> _productsController = 
      StreamController<List<ProductDetails>>.broadcast();
  final StreamController<bool> _purchaseStatusController = 
      StreamController<bool>.broadcast();

  // Current state
  SubscriptionTier _currentTier = SubscriptionTier.free;
  List<ProductDetails> _availableProducts = [];
  bool _isInitialized = false;

  // Getters
  Stream<SubscriptionTier> get subscriptionStream => _subscriptionController.stream;
  Stream<List<ProductDetails>> get productsStream => _productsController.stream;
  Stream<bool> get purchaseStatusStream => _purchaseStatusController.stream;
  SubscriptionTier get currentTier => _currentTier;
  List<ProductDetails> get availableProducts => _availableProducts;
  bool get isInitialized => _isInitialized;

  // Initialize the monetization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // For web platform, skip in-app purchase initialization
      if (kIsWeb) {
        print('Running on web - skipping in-app purchase initialization');
        _isInitialized = true;
        return;
      }

      // Check if in-app purchases are available
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        print('In-app purchases not available');
        _isInitialized = true; // Mark as initialized even if not available
        return;
      }

      // Load products
      await _loadProducts();

      // Restore purchases
      await _restorePurchases();

      // Check user's subscription status
      await _checkSubscriptionStatus();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing monetization service: $e');
      _isInitialized = true; // Mark as initialized even on error to prevent repeated attempts
    }
  }

  // Load available products
  Future<void> _loadProducts() async {
    try {
      final Set<String> productIds = {
        _premiumMonthlyId,
        _premiumYearlyId,
        _familyMonthlyId,
        _familyYearlyId,
      };

      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }

      _availableProducts = response.productDetails;
      _productsController.add(_availableProducts);
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  // Restore purchases
  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  // Check subscription status
  Future<void> _checkSubscriptionStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final tier = SubscriptionTier.values.firstWhere(
          (t) => t.toString() == data['tier'],
          orElse: () => SubscriptionTier.free,
        );
        
        final expiryDate = (data['expiryDate'] as Timestamp).toDate();
        final now = DateTime.now();

        if (expiryDate.isAfter(now)) {
          _currentTier = tier;
        } else {
          _currentTier = SubscriptionTier.free;
          await _updateSubscriptionInFirestore(SubscriptionTier.free);
        }
      } else {
        _currentTier = SubscriptionTier.free;
      }

      _subscriptionController.add(_currentTier);
    } catch (e) {
      print('Error checking subscription status: $e');
    }
  }

  // Purchase a subscription
  Future<bool> purchaseSubscription(ProductDetails product) async {
    try {
      _purchaseStatusController.add(false);

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      bool success = false;
      if (product.id.contains('family')) {
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }

      if (success) {
        _purchaseStatusController.add(true);
        return true;
      }
      return false;
    } catch (e) {
      print('Error purchasing subscription: $e');
      return false;
    }
  }

  // Handle purchase updates
  void handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchase
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _handlePurchaseError(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _handlePurchaseCanceled(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      SubscriptionTier tier;
      DateTime expiryDate;

      switch (purchaseDetails.productID) {
        case _premiumMonthlyId:
          tier = SubscriptionTier.premium;
          expiryDate = DateTime.now().add(const Duration(days: 30));
          break;
        case _premiumYearlyId:
          tier = SubscriptionTier.premium;
          expiryDate = DateTime.now().add(const Duration(days: 365));
          break;
        case _familyMonthlyId:
          tier = SubscriptionTier.family;
          expiryDate = DateTime.now().add(const Duration(days: 30));
          break;
        case _familyYearlyId:
          tier = SubscriptionTier.family;
          expiryDate = DateTime.now().add(const Duration(days: 365));
          break;
        default:
          return;
      }

      await _updateSubscriptionInFirestore(tier, expiryDate);
      _currentTier = tier;
      _subscriptionController.add(_currentTier);

      // Track purchase event
      await _trackPurchaseEvent(purchaseDetails.productID, tier);
    } catch (e) {
      print('Error handling successful purchase: $e');
    }
  }

  // Handle purchase error
  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    print('Purchase error: ${purchaseDetails.error}');
    _purchaseStatusController.add(false);
  }

  // Handle purchase canceled
  void _handlePurchaseCanceled(PurchaseDetails purchaseDetails) {
    print('Purchase canceled: ${purchaseDetails.productID}');
    _purchaseStatusController.add(false);
  }

  // Update subscription in Firestore
  Future<void> _updateSubscriptionInFirestore(
    SubscriptionTier tier, [
    DateTime? expiryDate,
  ]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final data = {
        'tier': tier.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (expiryDate != null) {
        data['expiryDate'] = Timestamp.fromDate(expiryDate);
      }

      await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error updating subscription in Firestore: $e');
    }
  }

  // Track purchase event
  Future<void> _trackPurchaseEvent(String productId, SubscriptionTier tier) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('purchase_events').add({
        'userId': user.uid,
        'productId': productId,
        'tier': tier.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });
    } catch (e) {
      print('Error tracking purchase event: $e');
    }
  }

  // Check if user has access to a premium feature
  bool hasAccessToFeature(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.caregiverAssignment:
        return _currentTier != SubscriptionTier.free;
      case PremiumFeature.detailedAnalytics:
        return _currentTier != SubscriptionTier.free;
      case PremiumFeature.priorityNotifications:
        return _currentTier != SubscriptionTier.free;
      case PremiumFeature.unlimitedMedications:
        return _currentTier != SubscriptionTier.free;
      case PremiumFeature.advancedReports:
        return _currentTier == SubscriptionTier.premium || 
               _currentTier == SubscriptionTier.family;
      case PremiumFeature.familySharing:
        return _currentTier == SubscriptionTier.family;
      case PremiumFeature.customReminders:
        return _currentTier != SubscriptionTier.free;
      case PremiumFeature.dataExport:
        return _currentTier == SubscriptionTier.premium || 
               _currentTier == SubscriptionTier.family;
    }
  }

  // Get feature limits for current tier
  Map<String, dynamic> getFeatureLimits() {
    switch (_currentTier) {
      case SubscriptionTier.free:
        return {
          'medications': 3,
          'caregivers': 0,
          'analytics': 'basic',
          'notifications': 'standard',
          'export': false,
          'familySharing': false,
        };
      case SubscriptionTier.premium:
        return {
          'medications': -1, // unlimited
          'caregivers': 2,
          'analytics': 'detailed',
          'notifications': 'priority',
          'export': true,
          'familySharing': false,
        };
      case SubscriptionTier.family:
        return {
          'medications': -1, // unlimited
          'caregivers': -1, // unlimited
          'analytics': 'detailed',
          'notifications': 'priority',
          'export': true,
          'familySharing': true,
        };
    }
  }

  // Start free trial
  Future<bool> startFreeTrial() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user has already used free trial
      final doc = await _firestore
          .collection('free_trials')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return false; // Already used free trial
      }

      // Start 7-day free trial
      final trialEndDate = DateTime.now().add(const Duration(days: 7));
      
      await _firestore.collection('free_trials').doc(user.uid).set({
        'startDate': FieldValue.serverTimestamp(),
        'endDate': Timestamp.fromDate(trialEndDate),
        'used': true,
      });

      await _updateSubscriptionInFirestore(SubscriptionTier.premium, trialEndDate);
      _currentTier = SubscriptionTier.premium;
      _subscriptionController.add(_currentTier);

      return true;
    } catch (e) {
      print('Error starting free trial: $e');
      return false;
    }
  }

  // Check if user can start free trial
  Future<bool> canStartFreeTrial() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('free_trials')
          .doc(user.uid)
          .get();

      return !doc.exists;
    } catch (e) {
      print('Error checking free trial eligibility: $e');
      return false;
    }
  }

  // Get subscription info
  Future<Map<String, dynamic>?> getSubscriptionInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'tier': data['tier'],
        'expiryDate': (data['expiryDate'] as Timestamp).toDate(),
        'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
      };
    } catch (e) {
      print('Error getting subscription info: $e');
      return null;
    }
  }

  // Dispose resources
  void dispose() {
    _subscriptionController.close();
    _productsController.close();
    _purchaseStatusController.close();
  }
} 