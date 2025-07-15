import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum SubscriptionPlan {
  free,
  basic,
  premium,
  enterprise,
}

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Map<SubscriptionPlan, Map<String, dynamic>> plans = {
    SubscriptionPlan.free: {
      'name': 'Free',
      'price': 0,
      'currency': 'RWF',
      'features': [
        'Basic inventory management',
        'Up to 10 products',
        'Up to 5 customers',
        'Basic sales tracking',
      ],
      'limits': {
        'products': 10,
        'customers': 5,
        'sales': 50,
      },
    },
    SubscriptionPlan.basic: {
      'name': 'Basic',
      'price': 2500,
      'currency': 'RWF',
      'features': [
        'Advanced inventory management',
        'Up to 50 products',
        'Up to 25 customers',
        'Advanced sales tracking',
        'Basic reports',
      ],
      'limits': {
        'products': 50,
        'customers': 25,
        'sales': 200,
      },
    },
    SubscriptionPlan.premium: {
      'name': 'Premium',
      'price': 5000,
      'currency': 'RWF',
      'features': [
        'Unlimited inventory management',
        'Unlimited products',
        'Unlimited customers',
        'Advanced analytics',
        'AI-powered insights',
        'Detailed reports',
        'Priority support',
      ],
      'limits': {
        'products': -1, // Unlimited
        'customers': -1, // Unlimited
        'sales': -1, // Unlimited
      },
    },
    SubscriptionPlan.enterprise: {
      'name': 'Enterprise',
      'price': 10000,
      'currency': 'RWF',
      'features': [
        'Everything in Premium',
        'Multi-location support',
        'Advanced integrations',
        'Custom reporting',
        'Dedicated support',
        'API access',
      ],
      'limits': {
        'products': -1, // Unlimited
        'customers': -1, // Unlimited
        'sales': -1, // Unlimited
      },
    },
  };

  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscription')
          .doc('current')
          .get();

      if (doc.exists) {
        return doc.data();
      } else {
        // Return default free plan
        return {
          'plan': 'free',
          'isActive': true,
          'startDate': Timestamp.now(),
          'expiresAt': null,
        };
      }
    } catch (e) {
      print('Error getting current subscription: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUsageStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get counts from Firestore
      final productsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('products')
          .get();

      final customersSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('customers')
          .get();

      final salesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sales')
          .where('date', isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 30))))
          .get();

      final currentSubscription = await getCurrentSubscription();
      final plan = currentSubscription?['plan'] ?? 'free';
      final planData = plans[SubscriptionPlan.values.firstWhere(
          (p) => p.name == plan, orElse: () => SubscriptionPlan.free)];

      final limits = planData?['limits'] ?? {'products': 10, 'customers': 5, 'sales': 50};

      return {
        'products': {
          'used': productsSnapshot.docs.length,
          'limit': limits['products'],
          'percentage': limits['products'] == -1 
              ? 0 
              : (productsSnapshot.docs.length / limits['products']) * 100,
        },
        'customers': {
          'used': customersSnapshot.docs.length,
          'limit': limits['customers'],
          'percentage': limits['customers'] == -1 
              ? 0 
              : (customersSnapshot.docs.length / limits['customers']) * 100,
        },
        'sales': {
          'used': salesSnapshot.docs.length,
          'limit': limits['sales'],
          'percentage': limits['sales'] == -1 
              ? 0 
              : (salesSnapshot.docs.length / limits['sales']) * 100,
        },
      };
    } catch (e) {
      print('Error getting usage statistics: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'amount': data['amount'],
          'currency': data['currency'] ?? 'RWF',
          'plan': data['plan'],
          'paymentDate': data['paymentDate'],
          'status': data['status'] ?? 'completed',
          'paymentMethod': data['paymentMethod'] ?? 'mobile_money',
        };
      }).toList();
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }

  Future<bool> upgradeSubscription(SubscriptionPlan plan) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final planData = plans[plan];
      if (planData == null) return false;

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Record payment
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('payments')
          .add({
        'amount': planData['price'],
        'currency': planData['currency'],
        'plan': plan.name,
        'paymentDate': Timestamp.now(),
        'status': 'completed',
        'paymentMethod': 'mobile_money',
      });

      // Update subscription
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscription')
          .doc('current')
          .set({
        'plan': plan.name,
        'isActive': true,
        'startDate': Timestamp.now(),
        'expiresAt': plan == SubscriptionPlan.free 
            ? null 
            : Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      });

      return true;
    } catch (e) {
      print('Error upgrading subscription: $e');
      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscription')
          .doc('current')
          .update({
        'isActive': false,
        'cancelledAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }

  String formatCurrency(double amount, String currency) {
    return '${amount.toStringAsFixed(0)} $currency';
  }
} 