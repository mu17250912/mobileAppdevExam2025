import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: _analytics);

  // Track user registration
  static Future<void> trackUserRegistration(String method) async {
    await _analytics.logEvent(
      name: 'user_registration',
      parameters: {
        'method': method, // 'email' or 'google'
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track user login
  static Future<void> trackUserLogin(String method) async {
    await _analytics.logEvent(
      name: 'user_login',
      parameters: {
        'method': method,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track car view
  static Future<void> trackCarView(String carId, String carName, String category) async {
    await _analytics.logEvent(
      name: 'car_view',
      parameters: {
        'car_id': carId,
        'car_name': carName,
        'category': category,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track booking initiation
  static Future<void> trackBookingInitiated(String carId, String carName, double amount) async {
    await _analytics.logEvent(
      name: 'booking_initiated',
      parameters: {
        'car_id': carId,
        'car_name': carName,
        'amount': amount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track payment attempt
  static Future<void> trackPaymentAttempt(String paymentMethod, double amount, String bookingId) async {
    await _analytics.logEvent(
      name: 'payment_attempt',
      parameters: {
        'payment_method': paymentMethod,
        'amount': amount,
        'booking_id': bookingId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track successful payment
  static Future<void> trackPaymentSuccess(String paymentMethod, double amount, String bookingId) async {
    await _analytics.logEvent(
      name: 'payment_success',
      parameters: {
        'payment_method': paymentMethod,
        'amount': amount,
        'booking_id': bookingId,
        'currency': 'FRW',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track subscription purchase
  static Future<void> trackSubscriptionPurchase(String planId, String planName, double price) async {
    await _analytics.logEvent(
      name: 'subscription_purchase',
      parameters: {
        'plan_id': planId,
        'plan_name': planName,
        'price': price,
        'currency': 'FRW',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track in-app purchase
  static Future<void> trackInAppPurchase(String productId, String productName, double price) async {
    await _analytics.logEvent(
      name: 'in_app_purchase',
      parameters: {
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'currency': 'FRW',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track screen view
  static Future<void> trackScreenView(String screenName) async {
    await _analytics.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': screenName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track user engagement
  static Future<void> trackUserEngagement(String action, String details) async {
    await _analytics.logEvent(
      name: 'user_engagement',
      parameters: {
        'action': action,
        'details': details,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track error events
  static Future<void> trackError(String errorType, String errorMessage) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Set user properties
  static Future<void> setUserProperties() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _analytics.setUserId(id: user.uid);
      await _analytics.setUserProperty(name: 'user_email', value: user.email);
      await _analytics.setUserProperty(name: 'registration_date', value: DateTime.now().toIso8601String());
    }
  }

  // Track conversion funnel
  static Future<void> trackConversionFunnel(String step, String userId) async {
    await _analytics.logEvent(
      name: 'conversion_funnel',
      parameters: {
        'step': step, // 'view_car', 'initiate_booking', 'payment', 'confirmation'
        'user_id': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track revenue metrics
  static Future<void> trackRevenue(double amount, String source) async {
    await _analytics.logEvent(
      name: 'revenue',
      parameters: {
        'amount': amount,
        'source': source, // 'subscription', 'in_app_purchase', 'booking'
        'currency': 'FRW',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track user retention
  static Future<void> trackUserRetention(String userId, int daysSinceRegistration) async {
    await _analytics.logEvent(
      name: 'user_retention',
      parameters: {
        'user_id': userId,
        'days_since_registration': daysSinceRegistration,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
} 