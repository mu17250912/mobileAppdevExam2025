import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_service.dart';

class PremiumService {
  static const String _premiumKey = 'premium_user';
  static const String _subscriptionTypeKey = 'subscription_type';
  static const String _subscriptionExpiryKey = 'subscription_expiry';
  static const String _productLimitKey = 'product_limit';

  /// Check if user has premium subscription
  static Future<bool> isPremiumUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(_premiumKey) ?? false;
    
    if (isPremium) {
      // Check if subscription hasn't expired
      final expiryDate = prefs.getString(_subscriptionExpiryKey);
      if (expiryDate != null) {
        final expiry = DateTime.parse(expiryDate);
        if (DateTime.now().isAfter(expiry)) {
          // Subscription expired, downgrade to free
          await _downgradeToFree();
          return false;
        }
      }
    }
    
    return isPremium;
  }

  /// Get subscription type
  static Future<String> getSubscriptionType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subscriptionTypeKey) ?? 'free';
  }

  /// Get product limit based on subscription
  static Future<int> getProductLimit() async {
    final isPremium = await isPremiumUser();
    return isPremium ? -1 : 5; // -1 means unlimited
  }

  /// Get current product count for user
  static Future<int> getCurrentProductCount(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('dealer', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting product count: $e');
      return 0;
    }
  }

  /// Check if user can add more products
  static Future<bool> canAddProduct(String userId) async {
    try {
      final limit = await getProductLimit();
      if (limit == -1) return true; // Unlimited
      
      final currentCount = await getCurrentProductCount(userId);
      return currentCount < limit;
    } catch (e) {
      print('Error checking if user can add product: $e');
      return false;
    }
  }

  /// Subscribe to premium plan
  static Future<bool> subscribeToPremium({
    required String username,
    required String plan,
    required double amount,
    required int months,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryDate = DateTime.now().add(Duration(days: months * 30));
      
      // Update local preferences
      await prefs.setBool(_premiumKey, true);
      await prefs.setString(_subscriptionTypeKey, plan);
      await prefs.setString(_subscriptionExpiryKey, expiryDate.toIso8601String());
      
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({
            'premium': true,
            'subscription_type': plan,
            'subscription_expiry': Timestamp.fromDate(expiryDate),
            'subscription_amount': amount,
          });
        }
      });
      
      // Track analytics
      await AnalyticsService.trackPremiumSubscription(
        userId: username,
        userRole: 'dealer',
        planType: plan,
        amount: amount,
        success: true,
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cancel premium subscription
  static Future<bool> cancelPremium(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update local preferences
      await prefs.setBool(_premiumKey, false);
      await prefs.setString(_subscriptionTypeKey, 'free');
      await prefs.remove(_subscriptionExpiryKey);
      
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({
            'premium': false,
            'subscription_type': 'free',
            'subscription_expiry': null,
          });
        }
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Downgrade to free tier
  static Future<void> _downgradeToFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, false);
    await prefs.setString(_subscriptionTypeKey, 'free');
    await prefs.remove(_subscriptionExpiryKey);
  }

  /// Get subscription plans
  static List<SubscriptionPlan> getSubscriptionPlans() {
    return [
      SubscriptionPlan(
        id: 'basic',
        name: 'Basic (Free)',
        price: 0,
        features: [
          'Access to marketplace',
          'Up to 5 product listings',
          'Basic customer support',
          'Standard delivery',
        ],
        limitations: [
          'Limited product listings',
          'No priority support',
          'No advanced analytics',
        ],
      ),
      SubscriptionPlan(
        id: 'premium',
        name: 'Premium',
        price: 5000,
        features: [
          'Unlimited product listings',
          'Advanced analytics dashboard',
          'Priority customer support',
          'Featured store placement',
          'Bulk order management',
          'Express delivery options',
          'Custom store branding',
        ],
        limitations: [],
      ),
    ];
  }

  /// Get premium features
  static List<String> getPremiumFeatures() {
    return [
      'Unlimited product listings',
      'Advanced analytics dashboard',
      'Priority customer support',
      'Featured store placement',
      'Bulk order management tools',
      'Express delivery options',
      'Custom store branding',
      'Advanced reporting',
      'Customer insights',
      'Marketing tools',
    ];
  }

  /// Check if feature is available for user
  static Future<bool> hasFeature(String feature) async {
    final isPremium = await isPremiumUser();
    
    switch (feature) {
      case 'unlimited_products':
        return isPremium;
      case 'advanced_analytics':
        return isPremium;
      case 'priority_support':
        return isPremium;
      case 'featured_placement':
        return isPremium;
      case 'bulk_management':
        return isPremium;
      case 'express_delivery':
        return isPremium;
      default:
        return true; // Basic features available to all
    }
  }

  /// Get subscription expiry date
  static Future<DateTime?> getSubscriptionExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_subscriptionExpiryKey);
    if (expiryString != null) {
      return DateTime.parse(expiryString);
    }
    return null;
  }

  /// Get days remaining in subscription
  static Future<int> getDaysRemaining() async {
    final expiry = await getSubscriptionExpiry();
    if (expiry != null) {
      final now = DateTime.now();
      final difference = expiry.difference(now);
      return difference.inDays;
    }
    return 0;
  }

  /// Check if subscription is expiring soon (within 7 days)
  static Future<bool> isExpiringSoon() async {
    final daysRemaining = await getDaysRemaining();
    return daysRemaining <= 7 && daysRemaining > 0;
  }
}

/// Subscription plan model
class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final List<String> features;
  final List<String> limitations;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
    required this.limitations,
  });
}

/// Premium feature model
class PremiumFeature {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isAvailable;

  PremiumFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isAvailable,
  });
} 