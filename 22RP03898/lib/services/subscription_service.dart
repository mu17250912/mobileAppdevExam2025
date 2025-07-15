/// Subscription Service for SafeRide
///
/// Handles all subscription-related operations including premium features,
/// in-app purchases, and freemium model management. This service manages
/// the subscription-based monetization aspects of the SafeRide platform.
///
/// Features:
/// - Multiple subscription tiers (Basic, Premium, Driver Premium)
/// - In-app purchases for virtual goods
/// - Freemium model with feature gating
/// - Subscription lifecycle management
/// - Automatic renewal handling
/// - Subscription analytics
///
/// Monetization Models:
/// 1. Freemium: Basic features free, premium features paid
/// 2. Subscription: Monthly/annual recurring payments
/// 3. In-app purchases: One-time purchases for virtual goods
/// 4. Commission-based: Platform takes % of ride bookings
/// 5. Ad-supported: Free users see ads, premium users don't
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';

enum SubscriptionTier {
  free,
  basic,
  premium,
  driverPremium,
}

enum InAppPurchaseType {
  priorityBooking,
  featuredListing,
  advancedAnalytics,
  premiumSupport,
  adFree,
  customProfile,
  bulkDiscount,
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int durationDays;
  final List<String> features;
  final SubscriptionTier tier;
  final bool isRecurring;
  final double? originalPrice;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.features,
    required this.tier,
    required this.isRecurring,
    this.originalPrice,
    this.isPopular = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'durationDays': durationDays,
      'features': features,
      'tier': tier.name,
      'isRecurring': isRecurring,
      'originalPrice': originalPrice,
      'isPopular': isPopular,
    };
  }

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'FRW',
      durationDays: map['durationDays'] ?? 30,
      features: List<String>.from(map['features'] ?? []),
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.name == map['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      isRecurring: map['isRecurring'] ?? false,
      originalPrice: map['originalPrice']?.toDouble(),
      isPopular: map['isPopular'] ?? false,
    );
  }
}

class InAppPurchase {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final InAppPurchaseType type;
  final Map<String, dynamic> benefits;
  final bool isConsumable;
  final String? imageUrl;

  const InAppPurchase({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.type,
    required this.benefits,
    required this.isConsumable,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'type': type.name,
      'benefits': benefits,
      'isConsumable': isConsumable,
      'imageUrl': imageUrl,
    };
  }

  factory InAppPurchase.fromMap(Map<String, dynamic> map) {
    return InAppPurchase(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'FRW',
      type: InAppPurchaseType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InAppPurchaseType.priorityBooking,
      ),
      benefits: Map<String, dynamic>.from(map['benefits'] ?? {}),
      isConsumable: map['isConsumable'] ?? false,
      imageUrl: map['imageUrl'],
    );
  }
}

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Available subscription plans
  static const List<SubscriptionPlan> availablePlans = [
    SubscriptionPlan(
      id: 'basic_monthly',
      name: 'Basic Monthly',
      description: 'Essential features for regular users',
      price: 5000.0,
      currency: 'FRW',
      durationDays: 30,
      features: [
        'Unlimited bookings',
        'Basic ride search',
        'Standard support',
        'Basic analytics',
      ],
      tier: SubscriptionTier.basic,
      isRecurring: true,
    ),
    SubscriptionPlan(
      id: 'premium_monthly',
      name: 'Premium Monthly',
      description: 'Advanced features for power users',
      price: 10000.0,
      currency: 'FRW',
      durationDays: 30,
      features: [
        'All Basic features',
        'Priority booking',
        'Advanced analytics',
        'Premium support',
        'Ad-free experience',
        'Custom notifications',
        'Ride history export',
      ],
      tier: SubscriptionTier.premium,
      isRecurring: true,
      isPopular: true,
    ),
    SubscriptionPlan(
      id: 'driver_premium_monthly',
      name: 'Driver Premium Monthly',
      description: 'Complete features for professional drivers',
      price: 15000.0,
      currency: 'FRW',
      durationDays: 30,
      features: [
        'All Premium features',
        'Featured listings',
        'Higher commission rates',
        'Advanced driver analytics',
        'Bulk booking management',
        'Custom branding',
        'Priority customer support',
      ],
      tier: SubscriptionTier.driverPremium,
      isRecurring: true,
    ),
    SubscriptionPlan(
      id: 'premium_yearly',
      name: 'Premium Yearly',
      description: 'Best value - Save 20% with annual billing',
      price: 96000.0,
      currency: 'FRW',
      durationDays: 365,
      features: [
        'All Premium features',
        'Priority booking',
        'Advanced analytics',
        'Premium support',
        'Ad-free experience',
        'Custom notifications',
        'Ride history export',
        '20% discount',
      ],
      tier: SubscriptionTier.premium,
      isRecurring: true,
      originalPrice: 120000.0,
      isPopular: true,
    ),
  ];

  // Available in-app purchases
  static const List<InAppPurchase> availablePurchases = [
    InAppPurchase(
      id: 'priority_booking',
      name: 'Priority Booking',
      description: 'Skip the queue and get priority booking for 30 days',
      price: 2000.0,
      currency: 'FRW',
      type: InAppPurchaseType.priorityBooking,
      benefits: {
        'priority_booking_days': 30,
        'skip_queue': true,
        'instant_confirmation': true,
      },
      isConsumable: true,
    ),
    InAppPurchase(
      id: 'featured_listing',
      name: 'Featured Listing',
      description:
          'Make your ride appear at the top of search results for 7 days',
      price: 3000.0,
      currency: 'FRW',
      type: InAppPurchaseType.featuredListing,
      benefits: {
        'featured_days': 7,
        'top_search_results': true,
        'highlighted_listing': true,
      },
      isConsumable: true,
    ),
    InAppPurchase(
      id: 'advanced_analytics',
      name: 'Advanced Analytics',
      description: 'Access detailed analytics and insights for 30 days',
      price: 1500.0,
      currency: 'FRW',
      type: InAppPurchaseType.advancedAnalytics,
      benefits: {
        'analytics_days': 30,
        'detailed_reports': true,
        'performance_insights': true,
        'trend_analysis': true,
      },
      isConsumable: true,
    ),
    InAppPurchase(
      id: 'ad_free_month',
      name: 'Ad-Free Experience',
      description: 'Remove all ads from the app for 30 days',
      price: 1000.0,
      currency: 'FRW',
      type: InAppPurchaseType.adFree,
      benefits: {
        'ad_free_days': 30,
        'no_banner_ads': true,
        'no_interstitial_ads': true,
        'clean_interface': true,
      },
      isConsumable: true,
    ),
    InAppPurchase(
      id: 'custom_profile',
      name: 'Custom Profile',
      description: 'Unlock custom profile themes and badges',
      price: 500.0,
      currency: 'FRW',
      type: InAppPurchaseType.customProfile,
      benefits: {
        'custom_themes': true,
        'profile_badges': true,
        'custom_avatar_frames': true,
        'profile_animations': true,
      },
      isConsumable: false,
    ),
  ];

  /// Get current user's subscription status
  Future<Map<String, dynamic>> getUserSubscriptionStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return _getDefaultSubscriptionStatus();
      }

      final userData = userDoc.data()!;
      final isPremium = userData['isPremium'] ?? false;
      final premiumExpiry = userData['premiumExpiry'] as Timestamp?;
      final subscriptionTier = userData['subscriptionTier'] ?? 'free';
      final purchasedItems =
          List<String>.from(userData['purchasedItems'] ?? []);

      final now = DateTime.now();
      final isActive = isPremium &&
          (premiumExpiry == null || premiumExpiry.toDate().isAfter(now));

      return {
        'isPremium': isActive,
        'tier': subscriptionTier,
        'expiresAt': premiumExpiry?.toDate().toIso8601String(),
        'daysRemaining': premiumExpiry != null
            ? premiumExpiry.toDate().difference(now).inDays
            : 0,
        'purchasedItems': purchasedItems,
        'features': _getFeaturesForTier(subscriptionTier),
      };
    } catch (e) {
      _logger.e('Error getting subscription status: $e');
      return _getDefaultSubscriptionStatus();
    }
  }

  /// Subscribe user to a plan
  Future<Map<String, dynamic>> subscribeToPlan({
    required String userId,
    required String planId,
    required String paymentMethod,
    String currency = 'FRW',
  }) async {
    try {
      final plan = availablePlans.firstWhere((p) => p.id == planId);
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: plan.durationDays));

      // Update user subscription
      await _firestore.collection('users').doc(userId).update({
        'isPremium': true,
        'subscriptionTier': plan.tier.name,
        'premiumExpiry': Timestamp.fromDate(expiryDate),
        'currentPlan': planId,
        'subscriptionStartDate': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Record subscription transaction
      await _firestore.collection('subscriptions').add({
        'userId': userId,
        'planId': planId,
        'planName': plan.name,
        'amount': plan.price,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'startDate': Timestamp.fromDate(now),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'status': 'active',
        'isRecurring': plan.isRecurring,
        'createdAt': Timestamp.fromDate(now),
      });

      _logger.i('User $userId subscribed to plan $planId');

      return {
        'success': true,
        'planId': planId,
        'planName': plan.name,
        'expiresAt': expiryDate.toIso8601String(),
        'features': plan.features,
      };
    } catch (e) {
      _logger.e('Error subscribing to plan: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Purchase in-app item
  Future<Map<String, dynamic>> purchaseInAppItem({
    required String userId,
    required String itemId,
    required String paymentMethod,
    String currency = 'FRW',
  }) async {
    try {
      final item = availablePurchases.firstWhere((p) => p.id == itemId);
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final now = DateTime.now();
      final userData = userDoc.data()!;
      final currentPurchases =
          List<String>.from(userData['purchasedItems'] ?? []);

      // Add item to user's purchases
      if (!currentPurchases.contains(itemId)) {
        currentPurchases.add(itemId);
      }

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'purchasedItems': currentPurchases,
        'lastPurchaseDate': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Record purchase transaction
      await _firestore.collection('in_app_purchases').add({
        'userId': userId,
        'itemId': itemId,
        'itemName': item.name,
        'amount': item.price,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'purchaseDate': Timestamp.fromDate(now),
        'benefits': item.benefits,
        'isConsumable': item.isConsumable,
      });

      _logger.i('User $userId purchased item $itemId');

      return {
        'success': true,
        'itemId': itemId,
        'itemName': item.name,
        'benefits': item.benefits,
      };
    } catch (e) {
      _logger.e('Error purchasing item: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if user has access to a specific feature
  Future<bool> hasFeatureAccess(String userId, String feature) async {
    try {
      final status = await getUserSubscriptionStatus(userId);
      final features = status['features'] as List<String>;
      return features.contains(feature);
    } catch (e) {
      _logger.e('Error checking feature access: $e');
      return false;
    }
  }

  /// Get subscription analytics
  Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    try {
      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('status', isEqualTo: 'active')
          .get();

      final purchasesSnapshot =
          await _firestore.collection('in_app_purchases').get();

      int totalSubscribers = subscriptionsSnapshot.docs.length;
      int totalPurchases = purchasesSnapshot.docs.length;
      double totalRevenue = 0.0;

      // Calculate revenue from subscriptions
      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['amount'] ?? 0).toDouble();
      }

      // Calculate revenue from in-app purchases
      for (var doc in purchasesSnapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['amount'] ?? 0).toDouble();
      }

      return {
        'totalSubscribers': totalSubscribers,
        'totalPurchases': totalPurchases,
        'totalRevenue': totalRevenue,
        'averageRevenuePerUser':
            totalSubscribers > 0 ? totalRevenue / totalSubscribers : 0.0,
      };
    } catch (e) {
      _logger.e('Error getting subscription analytics: $e');
      return {};
    }
  }

  /// Get default subscription status for free users
  Map<String, dynamic> _getDefaultSubscriptionStatus() {
    return {
      'isPremium': false,
      'tier': 'free',
      'expiresAt': null,
      'daysRemaining': 0,
      'purchasedItems': [],
      'features': _getFeaturesForTier('free'),
    };
  }

  /// Get features for a specific subscription tier
  List<String> _getFeaturesForTier(String tier) {
    switch (tier) {
      case 'free':
        return [
          'basic_booking',
          'view_rides',
          'basic_search',
          'standard_support',
        ];
      case 'basic':
        return [
          'basic_booking',
          'view_rides',
          'basic_search',
          'standard_support',
          'unlimited_bookings',
          'basic_analytics',
        ];
      case 'premium':
        return [
          'basic_booking',
          'view_rides',
          'basic_search',
          'standard_support',
          'unlimited_bookings',
          'basic_analytics',
          'priority_booking',
          'advanced_analytics',
          'premium_support',
          'ad_free',
          'custom_notifications',
          'ride_history_export',
        ];
      case 'driverPremium':
        return [
          'basic_booking',
          'view_rides',
          'basic_search',
          'standard_support',
          'unlimited_bookings',
          'basic_analytics',
          'priority_booking',
          'advanced_analytics',
          'premium_support',
          'ad_free',
          'custom_notifications',
          'ride_history_export',
          'featured_listings',
          'higher_commission',
          'advanced_driver_analytics',
          'bulk_booking_management',
          'custom_branding',
          'priority_customer_support',
        ];
      default:
        return _getFeaturesForTier('free');
    }
  }
}
