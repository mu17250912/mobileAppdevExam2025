import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'models.dart';

class SubscriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Premium features configuration
  static const Map<String, dynamic> premiumFeatures = {
    'maxBetAmount': {
      'free': 10000.0, // 10,000 RWF for free users
      'premium': 1000000.0, // 1,000,000 RWF for premium users
    },
    'maxSelections': {
      'free': 5, // Max 5 selections for free users
      'premium': 15, // Max 15 selections for premium users
    },
    'exclusiveOdds': {
      'free': false,
      'premium': true,
    },
    'advancedStats': {
      'free': false,
      'premium': true,
    },
    'prioritySupport': {
      'free': false,
      'premium': true,
    },
    'noAds': {
      'free': false,
      'premium': true,
    },
    'earlyAccess': {
      'free': false,
      'premium': true,
    },
  };

  // Subscription plans
  static const List<Map<String, dynamic>> subscriptionPlans = [
    {
      'id': 'monthly_premium',
      'name': 'Monthly Premium',
      'price': 5000.0, // 5,000 RWF per month
      'duration': 30, // 30 days
      'description': 'Access to all premium features for 30 days',
      'features': [
        'Higher betting limits (up to 1M RWF)',
        'More bet selections (up to 15)',
        'Exclusive odds and markets',
        'Advanced statistics',
        'Priority customer support',
        'Ad-free experience',
        'Early access to new features',
      ],
    },
    {
      'id': 'yearly_premium',
      'name': 'Yearly Premium',
      'price': 50000.0, // 50,000 RWF per year (2 months free)
      'duration': 365, // 365 days
      'description': 'Access to all premium features for 1 year',
      'features': [
        'Higher betting limits (up to 1M RWF)',
        'More bet selections (up to 15)',
        'Exclusive odds and markets',
        'Advanced statistics',
        'Priority customer support',
        'Ad-free experience',
        'Early access to new features',
        '2 months free compared to monthly',
      ],
    },
  ];

  // Get current user's subscription status
  static Future<User?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return User.fromMap(doc.id, doc.data()!);
  }

  // Check if user has access to a specific feature
  static Future<bool> hasFeatureAccess(String featureName) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    final tier = user.hasActiveSubscription ? 'premium' : 'free';
    return premiumFeatures[featureName]?[tier] ?? false;
  }

  // Get feature limit for current user
  static Future<dynamic> getFeatureLimit(String featureName) async {
    final user = await getCurrentUser();
    if (user == null) return premiumFeatures[featureName]?['free'];

    final tier = user.hasActiveSubscription ? 'premium' : 'free';
    return premiumFeatures[featureName]?[tier];
  }

  // Subscribe to premium plan
  static Future<bool> subscribeToPlan(String planId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final plan = subscriptionPlans.firstWhere((p) => p['id'] == planId);
    final duration = plan['duration'] as int;
    final expiryDate = DateTime.now().add(Duration(days: duration));

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionTier': 'premium',
        'subscriptionExpiry': Timestamp.fromDate(expiryDate),
        'isPremiumActive': true,
      });

      // Log subscription event
      await _firestore.collection('subscription_events').add({
        'userId': user.uid,
        'planId': planId,
        'planName': plan['name'],
        'price': plan['price'],
        'duration': duration,
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'subscribe',
      });

      return true;
    } catch (e) {
      print('Error subscribing to plan: $e');
      return false;
    }
  }

  // Cancel subscription
  static Future<bool> cancelSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isPremiumActive': false,
      });

      // Log cancellation event
      await _firestore.collection('subscription_events').add({
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'cancel',
      });

      return true;
    } catch (e) {
      print('Error canceling subscription: $e');
      return false;
    }
  }

  // Check if user can place a bet with given amount and selections
  static Future<Map<String, dynamic>> validateBetPlacement(double amount, int selectionsCount) async {
    final user = await getCurrentUser();
    if (user == null) {
      return {
        'canPlace': false,
        'reason': 'User not logged in',
        'upgradeRequired': false,
      };
    }

    final maxAmount = await getFeatureLimit('maxBetAmount') as double? ?? 10000.0;
    final maxSelections = await getFeatureLimit('maxSelections') as int? ?? 5;

    if (amount > maxAmount) {
      return {
        'canPlace': false,
        'reason': 'Bet amount exceeds limit for your plan',
        'upgradeRequired': true,
        'currentLimit': maxAmount,
        'requestedAmount': amount,
      };
    }

    if (selectionsCount > maxSelections) {
      return {
        'canPlace': false,
        'reason': 'Number of selections exceeds limit for your plan',
        'upgradeRequired': true,
        'currentLimit': maxSelections,
        'requestedSelections': selectionsCount,
      };
    }

    return {
      'canPlace': true,
      'reason': 'Bet placement allowed',
      'upgradeRequired': false,
    };
  }

  // Get subscription statistics
  static Future<Map<String, dynamic>> getSubscriptionStats() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final subscriptionEventsSnapshot = await _firestore.collection('subscription_events').get();

    int totalUsers = 0;
    int premiumUsers = 0;
    int activeSubscriptions = 0;
    double totalRevenue = 0.0;

    for (var doc in usersSnapshot.docs) {
      totalUsers++;
      final user = User.fromMap(doc.id, doc.data());
      if (user.subscriptionTier == 'premium') {
        premiumUsers++;
        if (user.hasActiveSubscription) {
          activeSubscriptions++;
        }
      }
    }

    for (var doc in subscriptionEventsSnapshot.docs) {
      final data = doc.data();
      if (data['action'] == 'subscribe' && data['price'] != null) {
        totalRevenue += (data['price'] as num).toDouble();
      }
    }

    return {
      'totalUsers': totalUsers,
      'premiumUsers': premiumUsers,
      'activeSubscriptions': activeSubscriptions,
      'conversionRate': totalUsers > 0 ? (premiumUsers / totalUsers * 100) : 0.0,
      'totalRevenue': totalRevenue,
    };
  }
} 