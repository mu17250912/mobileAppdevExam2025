import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Track user registration
  static Future<void> trackRegistration({
    required String username,
    required String role,
    String? email,
    String? phone,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'user_registration',
        'username': username,
        'role': role,
        'email': email,
        'phone': phone,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Registration tracked for $username');
    } catch (e) {
      print('❌ Analytics: Failed to track registration: $e');
    }
  }

  /// Track user login
  static Future<void> trackLogin({
    required String username,
    required String role,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'user_login',
        'username': username,
        'role': role,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Login tracked for $username');
    } catch (e) {
      print('❌ Analytics: Failed to track login: $e');
    }
  }

  /// Track product view
  static Future<void> trackProductView({
    required String productId,
    required String productName,
    required String dealer,
    required String viewerRole,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'product_view',
        'productId': productId,
        'productName': productName,
        'dealer': dealer,
        'viewerRole': viewerRole,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Product view tracked for $productName');
    } catch (e) {
      print('❌ Analytics: Failed to track product view: $e');
    }
  }

  /// Track cart addition
  static Future<void> trackCartAddition({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
    required String buyerRole,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'cart_addition',
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
        'totalValue': price * quantity,
        'buyerRole': buyerRole,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Cart addition tracked for $productName');
    } catch (e) {
      print('❌ Analytics: Failed to track cart addition: $e');
    }
  }

  /// Track order placement
  static Future<void> trackOrderPlacement({
    required String orderId,
    required String buyerId,
    required String buyerRole,
    required double totalAmount,
    required int itemCount,
    required String paymentMethod,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'order_placed',
        'orderId': orderId,
        'buyerId': buyerId,
        'buyerRole': buyerRole,
        'totalAmount': totalAmount,
        'itemCount': itemCount,
        'paymentMethod': paymentMethod,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Order placement tracked for order $orderId');
    } catch (e) {
      print('❌ Analytics: Failed to track order placement: $e');
    }
  }

  /// Track payment completion
  static Future<void> trackPaymentCompletion({
    required String orderId,
    required String buyerId,
    required double amount,
    required String paymentMethod,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'payment_completed',
        'orderId': orderId,
        'buyerId': buyerId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'success': success,
        'errorMessage': errorMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Payment completion tracked for order $orderId');
    } catch (e) {
      print('❌ Analytics: Failed to track payment completion: $e');
    }
  }

  /// Track premium subscription
  static Future<void> trackPremiumSubscription({
    required String userId,
    required String userRole,
    required String planType,
    required double amount,
    required bool success,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'premium_subscription',
        'userId': userId,
        'userRole': userRole,
        'planType': planType,
        'amount': amount,
        'success': success,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Premium subscription tracked for user $userId');
    } catch (e) {
      print('❌ Analytics: Failed to track premium subscription: $e');
    }
  }

  /// Track app feature usage
  static Future<void> trackFeatureUsage({
    required String feature,
    required String userRole,
    String? additionalData,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'feature_usage',
        'feature': feature,
        'userRole': userRole,
        'additionalData': additionalData,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Feature usage tracked for $feature');
    } catch (e) {
      print('❌ Analytics: Failed to track feature usage: $e');
    }
  }

  /// Track error occurrences
  static Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? screen,
    String? userRole,
    String? stackTrace,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'error_occurred',
        'errorType': errorType,
        'errorMessage': errorMessage,
        'screen': screen,
        'userRole': userRole,
        'stackTrace': stackTrace,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Error tracked: $errorType');
    } catch (e) {
      print('❌ Analytics: Failed to track error: $e');
    }
  }

  /// Track app performance metrics
  static Future<void> trackPerformance({
    required String metric,
    required double value,
    String? unit,
    String? context,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'performance_metric',
        'metric': metric,
        'value': value,
        'unit': unit,
        'context': context,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Performance metric tracked: $metric = $value');
    } catch (e) {
      print('❌ Analytics: Failed to track performance metric: $e');
    }
  }

  /// Get analytics summary for dashboard
  static Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final registrations = await _firestore
          .collection('analytics')
          .where('event', isEqualTo: 'user_registration')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth)
          .get();

      final logins = await _firestore
          .collection('analytics')
          .where('event', isEqualTo: 'user_login')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth)
          .get();

      final orders = await _firestore
          .collection('analytics')
          .where('event', isEqualTo: 'order_placed')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth)
          .get();

      final revenue = orders.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc.data()['totalAmount'] ?? 0.0),
      );

      return {
        'monthlyRegistrations': registrations.docs.length,
        'monthlyLogins': logins.docs.length,
        'monthlyOrders': orders.docs.length,
        'monthlyRevenue': revenue,
        'lastUpdated': now.toIso8601String(),
      };
    } catch (e) {
      print('❌ Analytics: Failed to get analytics summary: $e');
      return {
        'monthlyRegistrations': 0,
        'monthlyLogins': 0,
        'monthlyOrders': 0,
        'monthlyRevenue': 0.0,
        'lastUpdated': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// Track add to cart
  static Future<void> trackAddToCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
    required String buyerRole,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'add_to_cart',
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
        'totalValue': price * quantity,
        'buyerRole': buyerRole,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Add to cart tracked for $productName');
    } catch (e) {
      print('❌ Analytics: Failed to track add to cart: $e');
    }
  }

  /// Track product add (legacy method)
  static Future<void> trackProductAdd({
    required String productId,
    required String productName,
    required String dealer,
    required String category,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'product_add',
        'productId': productId,
        'productName': productName,
        'dealer': dealer,
        'category': category,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Product add tracked for $productName');
    } catch (e) {
      print('❌ Analytics: Failed to track product add: $e');
    }
  }

  /// Track product update (legacy method)
  static Future<void> trackProductUpdate({
    required String productId,
    required String productName,
    required String dealer,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'product_update',
        'productId': productId,
        'productName': productName,
        'dealer': dealer,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Product update tracked for $productName');
    } catch (e) {
      print('❌ Analytics: Failed to track product update: $e');
    }
  }

  /// Track payment success (legacy method)
  static Future<void> trackPaymentSuccess({
    required String orderId,
    required double amount,
    required String paymentMethod,
    required String referenceId,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'payment_success',
        'orderId': orderId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'referenceId': referenceId,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Payment success tracked for order $orderId');
    } catch (e) {
      print('❌ Analytics: Failed to track payment success: $e');
    }
  }

  /// Track payment failure (legacy method)
  static Future<void> trackPaymentFailure({
    required String orderId,
    required double amount,
    required String paymentMethod,
    required String errorMessage,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'payment_failure',
        'orderId': orderId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'errorMessage': errorMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Payment failure tracked for order $orderId');
    } catch (e) {
      print('❌ Analytics: Failed to track payment failure: $e');
    }
  }

  /// Track order placed (legacy method)
  static Future<void> trackOrderPlaced({
    required String orderId,
    required String buyerId,
    required double amount,
  }) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'order_placed',
        'orderId': orderId,
        'buyerId': buyerId,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Order placed tracked for order $orderId');
    } catch (e) {
      print('❌ Analytics: Failed to track order placed: $e');
    }
  }

  /// Set user property (legacy method)
  static Future<void> setUserProperty(String name, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(name, value);
      print('✅ Analytics: User property set: $name = $value');
    } catch (e) {
      print('❌ Analytics: Failed to set user property: $e');
    }
  }

  /// Track screen view (legacy method)
  static Future<void> trackScreenView(String screenName) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'screen_view',
        'screenName': screenName,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Screen view tracked for $screenName');
    } catch (e) {
      print('❌ Analytics: Failed to track screen view: $e');
    }
  }

  /// Track custom event (legacy method)
  static Future<void> trackEvent(String eventName, {Map<String, Object>? parameters}) async {
    try {
      final eventData = {
        'event': eventName,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      };
      
      if (parameters != null) {
        eventData.addAll(parameters.map((key, value) => MapEntry(key, value.toString())));
      }
      
      await _firestore.collection('analytics').add(eventData);
      print('✅ Analytics: Custom event tracked: $eventName');
    } catch (e) {
      print('❌ Analytics: Failed to track custom event: $e');
    }
  }

  /// Track user engagement (legacy method)
  static Future<void> trackUserEngagement({
    required String action,
    required String screen,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final eventData = {
        'event': 'user_engagement',
        'action': action,
        'screen': screen,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      };
      
      if (additionalParams != null) {
        eventData.addAll(additionalParams.map((key, value) => MapEntry(key, value.toString())));
      }
      
      await _firestore.collection('analytics').add(eventData);
      print('✅ Analytics: User engagement tracked: $action on $screen');
    } catch (e) {
      print('❌ Analytics: Failed to track user engagement: $e');
    }
  }

  /// Track logout (legacy method)
  static Future<void> trackLogout({required String username, required String role}) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'user_logout',
        'username': username,
        'role': role,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Logout tracked for $username');
    } catch (e) {
      print('❌ Analytics: Failed to track logout: $e');
    }
  }

  /// Track search (legacy method)
  static Future<void> trackSearch({required String query, required String category}) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'search',
        'query': query,
        'category': category,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      print('✅ Analytics: Search tracked: $query in $category');
    } catch (e) {
      print('❌ Analytics: Failed to track search: $e');
    }
  }
} 