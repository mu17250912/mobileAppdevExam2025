import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Premium subscription plans
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'monthly': {
      'id': 'premium_monthly',
      'name': 'Premium Monthly',
      'price': 9.99,
      'currency': 'USD',
      'duration': 'month',
      'features': [
        'Priority Listing',
        'Advanced Analytics',
        'Verified Badge',
        'Priority Support',
        'Unlimited Photos',
        'Promoted Listings',
        'Instant Notifications',
        'Market Insights',
      ],
    },
    'yearly': {
      'id': 'premium_yearly',
      'name': 'Premium Yearly',
      'price': 99.00,
      'currency': 'USD',
      'duration': 'year',
      'discount': 17,
      'features': [
        'Priority Listing',
        'Advanced Analytics',
        'Verified Badge',
        'Priority Support',
        'Unlimited Photos',
        'Promoted Listings',
        'Instant Notifications',
        'Market Insights',
        'Early Access to New Features',
        'Dedicated Account Manager',
      ],
    },
  };

  // Check if user is premium
  Future<bool> isUserPremium(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['isPremium'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  // Get user's subscription details
  Future<Map<String, dynamic>?> getUserSubscription(String userId) async {
    try {
      final subscriptionDoc = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();
      
      if (subscriptionDoc.exists) {
        return subscriptionDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting subscription details: $e');
      return null;
    }
  }

  // Process premium subscription
  Future<Map<String, dynamic>> subscribeToPremium({
    required String userId,
    required String planId,
    required String paymentMethod,
  }) async {
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Get plan details
      final plan = subscriptionPlans[planId];
      if (plan == null) {
        throw Exception('Invalid plan ID');
      }

      // Create subscription record
      final subscriptionData = {
        'userId': userId,
        'planId': planId,
        'planName': plan['name'],
        'price': plan['price'],
        'currency': plan['currency'],
        'duration': plan['duration'],
        'paymentMethod': paymentMethod,
        'status': 'active',
        'startDate': FieldValue.serverTimestamp(),
        'endDate': _calculateEndDate(plan['duration']),
        'autoRenew': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save subscription to Firestore
      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .set(subscriptionData);

      // Update user's premium status
      await _firestore.collection('users').doc(userId).update({
        'isPremium': true,
        'premiumPlan': planId,
        'premiumStartDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Premium subscription activated successfully!',
        'subscription': subscriptionData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Subscription failed: $e',
      };
    }
  }

  // Cancel premium subscription
  Future<Map<String, dynamic>> cancelSubscription(String userId) async {
    try {
      // Update subscription status
      await _firestore.collection('subscriptions').doc(userId).update({
        'status': 'cancelled',
        'autoRenew': false,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user's premium status
      await _firestore.collection('users').doc(userId).update({
        'isPremium': false,
        'premiumPlan': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Subscription cancelled successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to cancel subscription: $e',
      };
    }
  }

  // Get premium features for user
  List<String> getPremiumFeatures(String userId, {bool isPremium = false}) {
    if (!isPremium) {
      return [];
    }

    return [
      'Priority Listing',
      'Advanced Analytics',
      'Verified Badge',
      'Priority Support',
      'Unlimited Photos',
      'Promoted Listings',
      'Instant Notifications',
      'Market Insights',
    ];
  }

  // Check if feature is available for user
  bool isFeatureAvailable(String userId, String feature, {bool isPremium = false}) {
    if (!isPremium) {
      return false;
    }

    final premiumFeatures = getPremiumFeatures(userId, isPremium: isPremium);
    return premiumFeatures.contains(feature);
  }

  // Helper methods
  DateTime _calculateEndDate(String duration) {
    final now = DateTime.now();
    switch (duration) {
      case 'month':
        return DateTime(now.year, now.month + 1, now.day);
      case 'year':
        return DateTime(now.year + 1, now.month, now.day);
      default:
        return now.add(const Duration(days: 30));
    }
  }

  Future<void> upgradeToPremium(User user) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));
    // Simulate updating the user's premium status in the backend
    // In a real app, you would update Firestore or your backend here
    // For demo, just print
    print('User ${user.email} upgraded to premium!');
    // You may want to update Firestore here, e.g.:
    // await FirebaseFirestore.instance.collection('users').doc(user.id).update({'isPremium': true});
  }
} 