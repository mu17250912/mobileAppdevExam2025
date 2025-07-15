import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';
import '../utils/constants.dart';

class SubscriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Subscription plans
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'basic': {
      'name': 'Basic',
      'price': 0.0,
      'currency': 'RWF',
      'duration': 30, // days
      'features': [
        'Create up to 3 events',
        'Basic service provider search',
        'Standard support',
        'Basic notifications',
      ],
    },
    'premium': {
      'name': 'Premium',
      'price': 15000.0,
      'currency': 'RWF',
      'duration': 30, // days
      'features': [
        'Unlimited events',
        'Priority service provider listing',
        'Advanced search filters',
        'Premium support',
        'Priority notifications',
        'Event analytics',
        'Custom event themes',
        'Photo gallery',
      ],
    },
    'business': {
      'name': 'Business',
      'price': 50000.0,
      'currency': 'RWF',
      'duration': 30, // days
      'features': [
        'All Premium features',
        'Multiple event coordinators',
        'Advanced analytics',
        'Custom branding',
        'Priority booking',
        'Dedicated support',
        'API access',
        'White-label options',
      ],
    },
  };

  // Create subscription
  static Future<SubscriptionModel> createSubscription({
    required String planType,
    required String paymentMethod,
    bool autoRenew = false,
  }) async {
    if (currentUserId == null) throw 'User not authenticated';

    final plan = subscriptionPlans[planType];
    if (plan == null) throw 'Invalid plan type';

    final now = DateTime.now();
    final endDate = now.add(Duration(days: plan['duration']));

    final subscription = SubscriptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUserId!,
      planType: planType,
      status: 'pending',
      startDate: now,
      endDate: endDate,
      amount: plan['price'],
      currency: plan['currency'],
      paymentMethod: paymentMethod,
      autoRenew: autoRenew,
      features: {'features': plan['features']},
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(AppConstants.subscriptionsCollection)
        .doc(subscription.id)
        .set(subscription.toJson());

    return subscription;
  }

  // Get user subscription
  static Future<SubscriptionModel?> getUserSubscription() async {
    if (currentUserId == null) return null;

    try {
      final query = await _firestore
          .collection(AppConstants.subscriptionsCollection)
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'active')
          .get();

      if (query.docs.isEmpty) return null;

      // Sort in memory instead of using orderBy to avoid index requirement
      final docs = query.docs.toList();
      docs.sort((a, b) {
        final aDate = DateTime.parse(a.data()['createdAt'] ?? '');
        final bDate = DateTime.parse(b.data()['createdAt'] ?? '');
        return bDate.compareTo(aDate); // descending
      });

      return SubscriptionModel.fromJson(docs.first.data());
    } catch (e) {
      // print('Error getting user subscription: $e');
      return null;
    }
  }

  // Get subscription by ID
  static Future<SubscriptionModel?> getSubscriptionById(String subscriptionId) async {
    final doc = await _firestore
        .collection(AppConstants.subscriptionsCollection)
        .doc(subscriptionId)
        .get();

    if (!doc.exists) return null;

    return SubscriptionModel.fromJson(doc.data()!);
  }

  // Update subscription status
  static Future<void> updateSubscriptionStatus(String subscriptionId, String status) async {
    await _firestore
        .collection(AppConstants.subscriptionsCollection)
        .doc(subscriptionId)
        .update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Cancel subscription
  static Future<void> cancelSubscription(String subscriptionId) async {
    await _firestore
        .collection(AppConstants.subscriptionsCollection)
        .doc(subscriptionId)
        .update({
      'status': 'cancelled',
      'autoRenew': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Renew subscription
  static Future<void> renewSubscription(String subscriptionId) async {
    final subscription = await getSubscriptionById(subscriptionId);
    if (subscription == null) throw 'Subscription not found';

    final plan = subscriptionPlans[subscription.planType];
    if (plan == null) throw 'Invalid plan type';

    final newEndDate = subscription.endDate.add(Duration(days: plan['duration']));

    await _firestore
        .collection(AppConstants.subscriptionsCollection)
        .doc(subscriptionId)
        .update({
      'endDate': newEndDate.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Get subscription history
  static Stream<List<SubscriptionModel>> getSubscriptionHistory() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection(AppConstants.subscriptionsCollection)
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      final subscriptions = snapshot.docs.map((doc) {
        return SubscriptionModel.fromJson(doc.data());
      }).toList();
      
      // Sort in memory instead of using orderBy to avoid index requirement
      subscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return subscriptions;
    });
  }

  // Check if user has active subscription
  static Future<bool> hasActiveSubscription() async {
    final subscription = await getUserSubscription();
    return subscription?.isActive ?? false;
  }

  // Check if user has premium features
  static Future<bool> hasPremiumFeatures() async {
    final subscription = await getUserSubscription();
    return subscription?.isPremium ?? false;
  }

  // Get available features for user
  static Future<List<String>> getUserFeatures() async {
    final subscription = await getUserSubscription();
    
    if (subscription == null) {
      // Return basic features
      return subscriptionPlans['basic']!['features'] as List<String>;
    }

    return subscription.features['features'] as List<String>;
  }

  // Get subscription plan details
  static Map<String, dynamic>? getPlanDetails(String planType) {
    return subscriptionPlans[planType];
  }

  // Get all available plans
  static Map<String, Map<String, dynamic>> getAllPlans() {
    return subscriptionPlans;
  }

  // Upgrade subscription
  static Future<SubscriptionModel> upgradeSubscription({
    required String newPlanType,
    required String paymentMethod,
    bool autoRenew = false,
  }) async {
    // Cancel current subscription if exists
    final currentSubscription = await getUserSubscription();
    if (currentSubscription != null) {
      await cancelSubscription(currentSubscription.id);
    }

    // Create new subscription
    return await createSubscription(
      planType: newPlanType,
      paymentMethod: paymentMethod,
      autoRenew: autoRenew,
    );
  }

  // Process payment (mock implementation)
  static Future<bool> processPayment({
    required double amount,
    required String currency,
    required String paymentMethod,
  }) async {
    // TODO: Integrate with actual payment gateway
    // For now, simulate successful payment
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  // Get subscription analytics
  static Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    final query = await _firestore
        .collection(AppConstants.subscriptionsCollection)
        .get();

    final subscriptions = query.docs.map((doc) {
      return SubscriptionModel.fromJson(doc.data());
    }).toList();

    final totalSubscriptions = subscriptions.length;
    final activeSubscriptions = subscriptions.where((s) => s.isActive).length;
    final premiumSubscriptions = subscriptions.where((s) => s.isPremium).length;
    final businessSubscriptions = subscriptions.where((s) => s.isBusiness).length;

    final totalRevenue = subscriptions
        .where((s) => s.isActive)
        .fold(0.0, (total, s) => total + s.amount);

    return {
      'totalSubscriptions': totalSubscriptions,
      'activeSubscriptions': activeSubscriptions,
      'premiumSubscriptions': premiumSubscriptions,
      'businessSubscriptions': businessSubscriptions,
      'totalRevenue': totalRevenue,
      'averageRevenuePerUser': activeSubscriptions > 0 ? totalRevenue / activeSubscriptions : 0,
    };
  }

  // Check subscription expiration
  static Future<void> checkSubscriptionExpiration() async {
    final query = await _firestore
        .collection(AppConstants.subscriptionsCollection)
        .where('status', isEqualTo: 'active')
        .get();

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final doc in query.docs) {
      final subscription = SubscriptionModel.fromJson(doc.data());
      if (subscription.isExpired) {
        batch.update(doc.reference, {
          'status': 'expired',
          'updatedAt': now.toIso8601String(),
        });
      }
    }

    await batch.commit();
  }
} 