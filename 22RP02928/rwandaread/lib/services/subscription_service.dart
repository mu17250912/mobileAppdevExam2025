import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_plan.dart';
import '../models/user_subscription.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  // List<ProductDetails> _products = [];

  // Subscription plans
  static const List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      id: 'rwandaread_basic_monthly',
      name: 'Basic Monthly',
      description: 'Access to basic features',
      price: 4.99,
      currency: 'USD',
      billingPeriod: 'monthly',
      features: [
        'Unlimited book reading',
        'Basic bookmarks',
        'Reading progress tracking',
        'Ad-free experience',
      ],
    ),
    SubscriptionPlan(
      id: 'rwandaread_premium_monthly',
      name: 'Premium Monthly',
      description: 'Full access to all features',
      price: 9.99,
      currency: 'USD',
      billingPeriod: 'monthly',
      features: [
        'Unlimited book reading',
        'Unlimited downloads',
        'Advanced bookmarks',
        'Reading progress tracking',
        'Ad-free experience',
        'Priority support',
        'Exclusive content access',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      id: 'rwandaread_premium_yearly',
      name: 'Premium Yearly',
      description: 'Full access to all features with 40% savings',
      price: 59.99,
      currency: 'USD',
      billingPeriod: 'yearly',
      features: [
        'Unlimited book reading',
        'Unlimited downloads',
        'Advanced bookmarks',
        'Reading progress tracking',
        'Ad-free experience',
        'Priority support',
        'Exclusive content access',
        'Early access to new features',
      ],
      isPopular: false,
      discountText: 'Save 40%',
      originalPrice: 99.99,
    ),
  ];

  List<SubscriptionPlan> get plans => _plans;

  Future<void> initialize() async {
    // _isAvailable = await _inAppPurchase.isAvailable();
    _isAvailable = true; // Temporarily set to true for testing
    
    // if (_isAvailable) {
    //   _subscription = _inAppPurchase.purchaseStream.listen(
    //     _onPurchaseUpdate,
    //     onDone: () => _subscription?.cancel(),
    //     onError: (error) => print('Error in purchase stream: $error'),
    //   );

    //   await _loadProducts();
    // }
  }

  Future<void> _loadProducts() async {
    // final Set<String> productIds = _plans.map((plan) => plan.id).toSet();
    // final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
    
    // if (response.notFoundIDs.isNotEmpty) {
    //   print('Products not found: ${response.notFoundIDs}');
    // }
    
    // _products = response.productDetails;
  }

  Future<void> _onPurchaseUpdate(List<dynamic> purchaseDetailsList) async {
    // for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
    //   if (purchaseDetails.status == PurchaseStatus.pending) {
    //     // Handle pending purchase
    //   } else if (purchaseDetails.status == PurchaseStatus.purchased ||
    //              purchaseDetails.status == PurchaseStatus.restored) {
    //     await _handleSuccessfulPurchase(purchaseDetails);
    //   } else if (purchaseDetails.status == PurchaseStatus.error) {
    //     // Handle error
    //     print('Purchase error: ${purchaseDetails.error}');
    //   }
      
    //   if (purchaseDetails.pendingCompletePurchase) {
    //     await _inAppPurchase.completePurchase(purchaseDetails);
    //   }
    // }
  }

  Future<void> _handleSuccessfulPurchase(dynamic purchaseDetails) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // final plan = _plans.firstWhere(
    //   (plan) => plan.id == purchaseDetails.productID,
    //   orElse: () => _plans.first,
    // );

    // final subscription = UserSubscription(
    //   userId: user.uid,
    //   planId: plan.id,
    //   planName: plan.name,
    //   startDate: DateTime.now(),
    //   endDate: _calculateEndDate(plan.billingPeriod),
    //   isActive: true,
    //   status: 'active',
    //   transactionId: purchaseDetails.purchaseID,
    //   amount: plan.price,
    //   currency: plan.currency,
    //   billingPeriod: plan.billingPeriod,
    // );

    // await _saveSubscriptionToFirebase(subscription);
    // await _updateLocalSubscriptionStatus(true);
  }

  DateTime _calculateEndDate(String billingPeriod) {
    final now = DateTime.now();
    switch (billingPeriod) {
      case 'monthly':
        return DateTime(now.year, now.month + 1, now.day);
      case 'yearly':
        return DateTime(now.year + 1, now.month, now.day);
      default:
        return DateTime(now.year, now.month + 1, now.day);
    }
  }

  Future<void> _saveSubscriptionToFirebase(UserSubscription subscription) async {
    await _firestore
        .collection('subscriptions')
        .doc(subscription.userId)
        .set(subscription.toJson());
  }

  Future<void> _updateLocalSubscriptionStatus(bool isSubscribed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_subscribed', isSubscribed);
  }

  Future<bool> purchaseSubscription(SubscriptionPlan plan) async {
    if (!_isAvailable) {
      print('In-app purchases not available');
      return false;
    }

    // final product = _products.firstWhere(
    //   (product) => product.id == plan.id,
    //   orElse: () => throw Exception('Product not found'),
    // );

    // final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      // final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      // return success;
      
      // Temporarily simulate successful purchase for testing
      final user = _auth.currentUser;
      if (user != null) {
        final subscription = UserSubscription(
          userId: user.uid,
          planId: plan.id,
          planName: plan.name,
          startDate: DateTime.now(),
          endDate: _calculateEndDate(plan.billingPeriod),
          isActive: true,
          status: 'active',
          transactionId: 'test_${DateTime.now().millisecondsSinceEpoch}',
          amount: plan.price,
          currency: plan.currency,
          billingPeriod: plan.billingPeriod,
        );
        await _saveSubscriptionToFirebase(subscription);
        await _updateLocalSubscriptionStatus(true);
        return true;
      }
      return false;
    } catch (e) {
      print('Error purchasing subscription: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      // await _inAppPurchase.restorePurchases();
      // return true;
      
      // Temporarily simulate restore for testing
      return true;
    } catch (e) {
      print('Error restoring purchases: $e');
      return false;
    }
  }

  Future<UserSubscription?> getCurrentSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return UserSubscription.fromJson(doc.data()!);
      }
    } catch (e) {
      print('Error getting subscription: $e');
    }
    return null;
  }

  Future<bool> isUserSubscribed() async {
    final subscription = await getCurrentSubscription();
    return subscription?.isActive == true && !subscription!.isExpired;
  }

  Future<void> cancelSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .update({
        'isActive': false,
        'status': 'cancelled',
      });

      await _updateLocalSubscriptionStatus(false);
    } catch (e) {
      print('Error cancelling subscription: $e');
    }
  }

  void dispose() {
    // _subscription?.cancel();
  }
} 