import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_plan.dart';
import 'user_service.dart';

class MonetizationService {
  static final MonetizationService _instance = MonetizationService._internal();
  factory MonetizationService() => _instance;
  MonetizationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Subscription Plans
  static const List<SubscriptionPlan> _subscriptionPlans = [
    SubscriptionPlan(
      id: 'basic_monthly',
      name: 'Basic Monthly',
      description: 'Essential features for casual users',
      price: 4.99,
      currency: 'USD',
      billingPeriod: 'monthly',
      features: [
        'Ad-free experience',
        'Priority customer support',
        'Advanced search filters',
        'Order tracking',
      ],
      productId: 'basic_monthly_subscription',
    ),
    SubscriptionPlan(
      id: 'premium_monthly',
      name: 'Premium Monthly',
      description: 'Best value for active users',
      price: 9.99,
      currency: 'USD',
      billingPeriod: 'monthly',
      features: [
        'All Basic features',
        'Unlimited orders',
        'Exclusive deals',
        'Free delivery',
        'Early access to new features',
        'Priority listing in search',
      ],
      isPopular: true,
      productId: 'premium_monthly_subscription',
    ),
    SubscriptionPlan(
      id: 'premium_yearly',
      name: 'Premium Yearly',
      description: 'Save 40% with annual billing',
      price: 59.99,
      currency: 'USD',
      billingPeriod: 'yearly',
      features: [
        'All Premium features',
        '2 months free',
        'VIP customer support',
        'Exclusive member events',
      ],
      productId: 'premium_yearly_subscription',
    ),
  ];

  // In-App Products
  static const List<InAppProduct> _inAppProducts = [
    InAppProduct(
      id: 'premium_delivery',
      name: 'Premium Delivery',
      description: 'Get your orders delivered within 2 hours',
      price: 2.99,
      currency: 'USD',
      type: 'consumable',
    ),
    InAppProduct(
      id: 'featured_listing',
      name: 'Featured Listing',
      description: 'Boost your product visibility for 7 days',
      price: 4.99,
      currency: 'USD',
      type: 'consumable',
    ),
    InAppProduct(
      id: 'analytics_package',
      name: 'Analytics Package',
      description: 'Advanced sales analytics and insights',
      price: 19.99,
      currency: 'USD',
      type: 'non_consumable',
    ),
  ];

  // Commission rates
  static const double _commissionRate = 0.05; // 5% commission
  static const double _premiumCommissionRate = 0.03; // 3% for premium users

  // Ad units
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test ad unit
  static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // Test ad unit

  // Development mode flag
  static const bool _isDevelopmentMode = true; // Set to false for production

  // Initialize monetization
  Future<void> initialize() async {
    await _initializeInAppPurchase();
    await _initializeAds();
    await _loadUserSubscription();
  }

  // In-App Purchase Methods
  Future<void> _initializeInAppPurchase() async {
    if (_isDevelopmentMode) {
      print('Running in development mode - in-app purchases will be simulated');
      return;
    }

    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print('In-app purchase not available');
      return;
    }

    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('Error in purchase stream: $error'),
    );
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        print('Purchase successful: ${purchaseDetails.productID}');
        _handleSuccessfulPurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    final user = UserService.currentUser;
    if (user == null) return;

    try {
      // Verify purchase with server
      final isValid = await _verifyPurchase(purchaseDetails);
      if (!isValid) {
        print('Purchase verification failed');
        return;
      }

      // Process the purchase
      if (purchaseDetails.productID.contains('subscription')) {
        await _processSubscriptionPurchase(purchaseDetails);
      } else {
        await _processInAppPurchase(purchaseDetails);
      }

      // Complete the purchase
      await _inAppPurchase.completePurchase(purchaseDetails);
      print('Purchase completed successfully: ${purchaseDetails.productID}');
    } catch (e) {
      print('Error handling purchase: $e');
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In a real app, you would verify the purchase with your server
    // For now, we'll assume it's valid
    return true;
  }

  Future<void> _processSubscriptionPurchase(PurchaseDetails purchaseDetails) async {
    final user = UserService.currentUser;
    if (user == null) return;

    try {
      final plan = _subscriptionPlans.firstWhere(
        (plan) => plan.productId == purchaseDetails.productID,
        orElse: () => _subscriptionPlans.first,
      );

      final subscription = UserSubscription(
        userId: user.id,
        planId: plan.id,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        status: 'active',
        transactionId: purchaseDetails.purchaseID,
      );

      await _saveUserSubscription(subscription);
      print('Subscription saved: ${plan.name}');
    } catch (e) {
      print('Error processing subscription: $e');
      rethrow;
    }
  }

  Future<void> _processInAppPurchase(PurchaseDetails purchaseDetails) async {
    final user = UserService.currentUser;
    if (user == null) return;

    try {
      final product = _inAppProducts.firstWhere(
        (product) => product.id == purchaseDetails.productID,
        orElse: () => _inAppProducts.first,
      );

      // Apply the purchased feature
      await _applyInAppPurchase(product);
      print('In-app purchase applied: ${product.name}');
    } catch (e) {
      print('Error processing in-app purchase: $e');
      rethrow;
    }
  }

  Future<void> _applyInAppPurchase(InAppProduct product) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (product.id) {
      case 'premium_delivery':
        await prefs.setBool('premium_delivery_enabled', true);
        break;
      case 'featured_listing':
        await prefs.setBool('featured_listing_enabled', true);
        break;
      case 'analytics_package':
        await prefs.setBool('analytics_enabled', true);
        break;
    }
  }

  // Subscription Methods
  List<SubscriptionPlan> getSubscriptionPlans() => _subscriptionPlans;

  Future<SubscriptionPlan?> getCurrentUserPlan() async {
    final user = UserService.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.id)
          .where('isActive', isEqualTo: true)
          .get();

      if (doc.docs.isEmpty) return null;

      final subscription = UserSubscription.fromJson(doc.docs.first.data());
      return _subscriptionPlans.firstWhere(
        (plan) => plan.id == subscription.planId,
        orElse: () => _subscriptionPlans.first,
      );
    } catch (e) {
      print('Error getting current user plan: $e');
      return null;
    }
  }

  Future<bool> isUserPremium() async {
    try {
      final plan = await getCurrentUserPlan();
      return plan != null && plan.id.contains('premium');
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  Future<void> _saveUserSubscription(UserSubscription subscription) async {
    try {
      await _firestore
          .collection('subscriptions')
          .doc(subscription.userId)
          .set(subscription.toJson());
      print('User subscription saved to Firestore');
    } catch (e) {
      print('Error saving subscription: $e');
      rethrow;
    }
  }

  Future<void> _loadUserSubscription() async {
    final user = UserService.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('subscriptions')
          .doc(user.id)
          .get();

      if (doc.exists) {
        final subscription = UserSubscription.fromJson(doc.data()!);
        if (subscription.endDate.isBefore(DateTime.now())) {
          // Subscription expired
          await _firestore
              .collection('subscriptions')
              .doc(user.id)
              .update({'isActive': false, 'status': 'expired'});
          print('Subscription expired and updated');
        }
      }
    } catch (e) {
      print('Error loading user subscription: $e');
    }
  }

  // In-App Purchase Methods
  List<InAppProduct> getInAppProducts() => _inAppProducts;

  Future<void> purchaseProduct(String productId) async {
    if (_isDevelopmentMode) {
      await _simulatePurchase(productId);
      return;
    }

    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});
      
      if (response.notFoundIDs.isNotEmpty) {
        throw Exception('Product not found: ${response.notFoundIDs}');
      }

      if (response.productDetails.isEmpty) {
        throw Exception('No product details available');
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
      );

      final bool success = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      
      if (!success) {
        throw Exception('Failed to initiate purchase');
      }
    } catch (e) {
      print('Purchase error: $e');
      rethrow;
    }
  }

  Future<void> purchaseSubscription(String productId) async {
    if (_isDevelopmentMode) {
      await _simulateSubscriptionPurchase(productId);
      return;
    }

    try {
      print('Attempting to purchase subscription: $productId');
      
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});
      
      if (response.notFoundIDs.isNotEmpty) {
        throw Exception('Product not found: ${response.notFoundIDs}');
      }

      if (response.productDetails.isEmpty) {
        throw Exception('No product details available');
      }

      print('Product details found: ${response.productDetails.first.title}');

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
      );

      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (!success) {
        throw Exception('Failed to initiate purchase');
      }
      
      print('Purchase initiated successfully');
    } catch (e) {
      print('Purchase error: $e');
      rethrow;
    }
  }

  // Development mode simulation methods
  Future<void> _simulatePurchase(String productId) async {
    print('Simulating purchase for: $productId');
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    final user = UserService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final product = _inAppProducts.firstWhere(
      (product) => product.id == productId,
      orElse: () => throw Exception('Product not found'),
    );

    await _applyInAppPurchase(product);
    print('Simulated purchase completed: ${product.name}');
  }

  Future<void> _simulateSubscriptionPurchase(String productId) async {
    print('Simulating subscription purchase for: $productId');
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    final user = UserService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final plan = _subscriptionPlans.firstWhere(
      (plan) => plan.productId == productId,
      orElse: () => throw Exception('Subscription plan not found'),
    );

    final subscription = UserSubscription(
      userId: user.id,
      planId: plan.id,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
      status: 'active',
      transactionId: 'dev_${DateTime.now().millisecondsSinceEpoch}',
    );

    await _saveUserSubscription(subscription);
    print('Simulated subscription completed: ${plan.name}');
  }

  // Ad Methods
  Future<void> _initializeAds() async {
    await MobileAds.instance.initialize();
  }

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('Banner ad loaded'),
        onAdFailedToLoad: (ad, error) => print('Banner ad failed to load: $error'),
      ),
    );
  }

  InterstitialAd? _interstitialAd;

  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  // Commission Methods
  Future<double> calculateCommission(double orderAmount, String userId) async {
    final isPremium = await isUserPremium();
    final commissionRate = isPremium ? _premiumCommissionRate : _commissionRate;
    return orderAmount * commissionRate;
  }

  Future<void> recordCommission(double amount, String orderId, String userId) async {
    await _firestore.collection('commissions').add({
      'userId': userId,
      'orderId': orderId,
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // Utility Methods
  Future<bool> shouldShowAds() async {
    final isPremium = await isUserPremium();
    return !isPremium;
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _interstitialAd?.dispose();
  }
} 