import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'analytics_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Subscription Product IDs
  static const String basicSubscriptionId = 'commissioner_basic_monthly';
  static const String premiumSubscriptionId = 'commissioner_premium_monthly';
  static const String proSubscriptionId = 'commissioner_pro_monthly';

  // Subscription Tiers
  static const String tierBasic = 'basic';
  static const String tierPremium = 'premium';
  static const String tierPro = 'pro';

  // Subscription Features
  static const Map<String, List<String>> subscriptionFeatures = {
    tierBasic: [
      'Unlimited property views',
      'Basic search filters',
      'Email support',
      '5 purchase requests per month',
    ],
    tierPremium: [
      'All Basic features',
      'Advanced search filters',
      'Priority support',
      'Unlimited purchase requests',
      'Property alerts',
      'Saved searches',
      'No ads',
    ],
    tierPro: [
      'All Premium features',
      'Commissioner dashboard access',
      'Analytics and insights',
      'Priority listing placement',
      'Dedicated support',
      'Custom branding',
      'API access',
    ],
  };

  // Subscription Pricing
  static const Map<String, double> subscriptionPricing = {
    tierBasic: 9.99,
    tierPremium: 19.99,
    tierPro: 49.99,
  };

  Future<void> initialize() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('In-app purchases not available');
        return;
      }

      // Listen to purchase updates
      _inAppPurchase.purchaseStream.listen(_handlePurchaseUpdate);
    } catch (e) {
      debugPrint('Error initializing subscription service: $e');
    }
  }

  // Get available products
  Future<List<ProductDetails>> getAvailableProducts() async {
    try {
      final Set<String> productIds = {
        basicSubscriptionId,
        premiumSubscriptionId,
        proSubscriptionId,
      };

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      return response.productDetails;
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }

  // Purchase subscription
  Future<bool> purchaseSubscription(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      bool success = false;
      if (product.id.contains('subscription')) {
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }

      if (success) {
        debugPrint('Purchase initiated successfully');
        return true;
      } else {
        debugPrint('Purchase failed to initiate');
        return false;
      }
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      return false;
    }
  }

  // Handle purchase updates
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _handlePendingPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _handleFailedPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _handleCanceledPurchase(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void _handlePendingPurchase(PurchaseDetails purchaseDetails) {
    debugPrint('Purchase pending: ${purchaseDetails.productID}');
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final String tier = _getTierFromProductId(purchaseDetails.productID);
      final double price = subscriptionPricing[tier] ?? 0.0;

      // Update user subscription in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionTier': tier,
        'subscriptionStatus': 'active',
        'subscriptionStartDate': FieldValue.serverTimestamp(),
        'subscriptionEndDate': _calculateSubscriptionEndDate(),
        'lastPaymentAmount': price,
        'lastPaymentDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Track subscription purchase
      await AnalyticsService().trackSubscriptionPurchased(
        subscriptionId: purchaseDetails.purchaseID ?? '',
        tier: tier,
        price: price,
        userId: user.uid,
      );

      debugPrint('Subscription purchased successfully: $tier');
    } catch (e) {
      debugPrint('Error handling successful purchase: $e');
    }
  }

  void _handleFailedPurchase(PurchaseDetails purchaseDetails) {
    debugPrint('Purchase failed: ${purchaseDetails.error}');
  }

  void _handleCanceledPurchase(PurchaseDetails purchaseDetails) {
    debugPrint('Purchase canceled: ${purchaseDetails.productID}');
  }

  // Get current user subscription
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return {
        'tier': data['subscriptionTier'] ?? 'free',
        'status': data['subscriptionStatus'] ?? 'inactive',
        'startDate': data['subscriptionStartDate'],
        'endDate': data['subscriptionEndDate'],
        'lastPaymentAmount': data['lastPaymentAmount'] ?? 0.0,
        'lastPaymentDate': data['lastPaymentDate'],
      };
    } catch (e) {
      debugPrint('Error getting current subscription: $e');
      return null;
    }
  }

  // Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    final subscription = await getCurrentSubscription();
    if (subscription == null) return false;

    final status = subscription['status'] as String?;
    final endDate = subscription['endDate'] as Timestamp?;

    if (status != 'active') return false;
    if (endDate == null) return false;

    return DateTime.now().isBefore(endDate.toDate());
  }

  // Check if user has specific subscription tier
  Future<bool> hasSubscriptionTier(String tier) async {
    final subscription = await getCurrentSubscription();
    if (subscription == null) return false;

    final hasActive = await hasActiveSubscription();
    final currentTier = subscription['tier'] as String?;

    return hasActive && currentTier == tier;
  }

  // Get subscription features for tier
  List<String> getSubscriptionFeatures(String tier) {
    return subscriptionFeatures[tier] ?? [];
  }

  // Get subscription price for tier
  double getSubscriptionPrice(String tier) {
    return subscriptionPricing[tier] ?? 0.0;
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionStatus': 'canceling',
        'subscriptionCancelDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Subscription cancellation initiated');
      return true;
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
      return false;
    }
  }

  // Restore purchases
  Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('Purchases restored');
      return true;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  // Helper methods
  String _getTierFromProductId(String productId) {
    if (productId.contains('basic')) return tierBasic;
    if (productId.contains('premium')) return tierPremium;
    if (productId.contains('pro')) return tierPro;
    return tierBasic;
  }

  DateTime _calculateSubscriptionEndDate() {
    return DateTime.now().add(const Duration(days: 30)); // Monthly subscription
  }

  // Get subscription benefits for user
  Future<List<String>> getUserBenefits() async {
    final subscription = await getCurrentSubscription();
    if (subscription == null) return [];

    final tier = subscription['tier'] as String?;
    if (tier == null) return [];

    return getSubscriptionFeatures(tier);
  }

  // Check if feature is available for user
  Future<bool> isFeatureAvailable(String feature) async {
    final subscription = await getCurrentSubscription();
    if (subscription == null) return false;

    final tier = subscription['tier'] as String?;
    if (tier == null) return false;

    final hasActive = await hasActiveSubscription();
    if (!hasActive) return false;

    // Define feature availability by tier
    final Map<String, List<String>> featureAvailability = {
      tierBasic: ['unlimited_views', 'basic_search', 'email_support'],
      tierPremium: ['unlimited_views', 'basic_search', 'email_support', 'advanced_search', 'priority_support', 'unlimited_requests', 'property_alerts', 'saved_searches', 'no_ads'],
      tierPro: ['unlimited_views', 'basic_search', 'email_support', 'advanced_search', 'priority_support', 'unlimited_requests', 'property_alerts', 'saved_searches', 'no_ads', 'commissioner_dashboard', 'analytics', 'priority_listing', 'dedicated_support', 'custom_branding', 'api_access'],
    };

    final availableFeatures = featureAvailability[tier] ?? [];
    return availableFeatures.contains(feature);
  }
} 