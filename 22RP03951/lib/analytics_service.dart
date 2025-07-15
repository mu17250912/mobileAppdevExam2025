import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track user login
  static Future<void> trackLogin(String method) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('analytics').add({
          'event': 'user_login',
          'method': method,
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'userEmail': user.email,
        });
      }
    } catch (e) {
      print('Error tracking login: $e');
    }
  }

  // Track product view
  static Future<void> trackProductView(String productId, String productName) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('analytics').add({
        'event': 'product_view',
        'productId': productId,
        'productName': productName,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'userEmail': user?.email,
      });
    } catch (e) {
      print('Error tracking product view: $e');
    }
  }

  // Track order placement
  static Future<void> trackOrderPlacement(String orderId, double totalAmount) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('analytics').add({
        'event': 'order_placed',
        'orderId': orderId,
        'totalAmount': totalAmount,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'userEmail': user?.email,
      });
    } catch (e) {
      print('Error tracking order placement: $e');
    }
  }

  // Track subscription
  static Future<void> trackSubscription(String planName, double amount) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('analytics').add({
        'event': 'subscription_purchased',
        'planName': planName,
        'amount': amount,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'userEmail': user?.email,
      });
    } catch (e) {
      print('Error tracking subscription: $e');
    }
  }

  // Track app usage time
  static Future<void> trackAppUsage(Duration usageTime) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('analytics').add({
        'event': 'app_usage',
        'usageTimeMinutes': usageTime.inMinutes,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'userEmail': user?.email,
      });
    } catch (e) {
      print('Error tracking app usage: $e');
    }
  }

  // Track feature usage
  static Future<void> trackFeatureUsage(String featureName) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('analytics').add({
        'event': 'feature_used',
        'featureName': featureName,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'userEmail': user?.email,
      });
    } catch (e) {
      print('Error tracking feature usage: $e');
    }
  }

  // Get analytics summary for admin
  static Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, now.day);

      // Get login events
      final loginQuery = await _firestore
          .collection('analytics')
          .where('event', isEqualTo: 'user_login')
          .where('timestamp', isGreaterThan: lastMonth)
          .get();

      // Get order events
      final orderQuery = await _firestore
          .collection('analytics')
          .where('event', isEqualTo: 'order_placed')
          .where('timestamp', isGreaterThan: lastMonth)
          .get();

      // Get subscription events
      final subscriptionQuery = await _firestore
          .collection('analytics')
          .where('event', isEqualTo: 'subscription_purchased')
          .where('timestamp', isGreaterThan: lastMonth)
          .get();

      double totalRevenue = 0;
      for (var doc in orderQuery.docs) {
        totalRevenue += (doc.data()['totalAmount'] ?? 0).toDouble();
      }

      for (var doc in subscriptionQuery.docs) {
        totalRevenue += (doc.data()['amount'] ?? 0).toDouble();
      }

      return {
        'totalLogins': loginQuery.docs.length,
        'totalOrders': orderQuery.docs.length,
        'totalSubscriptions': subscriptionQuery.docs.length,
        'totalRevenue': totalRevenue,
        'period': 'Last 30 days',
      };
    } catch (e) {
      print('Error getting analytics summary: $e');
      return {
        'totalLogins': 0,
        'totalOrders': 0,
        'totalSubscriptions': 0,
        'totalRevenue': 0.0,
        'period': 'Last 30 days',
      };
    }
  }
} 