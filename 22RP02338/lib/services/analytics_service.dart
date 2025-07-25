import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _firebaseAnalytics;
  late Mixpanel _mixpanel;
  bool _isInitialized = false;

  // Analytics Events
  static const String eventUserSignUp = 'user_sign_up';
  static const String eventUserLogin = 'user_login';
  static const String eventPropertyViewed = 'property_viewed';
  static const String eventPropertyFavorited = 'property_favorited';
  static const String eventPurchaseRequestSubmitted = 'purchase_request_submitted';
  static const String eventPaymentCompleted = 'payment_completed';
  static const String eventSubscriptionPurchased = 'subscription_purchased';
  static const String eventAdViewed = 'ad_viewed';
  static const String eventAdClicked = 'ad_clicked';
  static const String eventSearchPerformed = 'search_performed';
  static const String eventCommissionerDashboardAccessed = 'commissioner_dashboard_accessed';
  static const String eventPropertyAdded = 'property_added';
  static const String eventUserProfileUpdated = 'user_profile_updated';

  // User Properties
  static const String userPropertyUserType = 'user_type';
  static const String userPropertySubscriptionTier = 'subscription_tier';
  static const String userPropertyTotalRequests = 'total_requests';
  static const String userPropertyTotalPayments = 'total_payments';
  static const String userPropertyJoinDate = 'join_date';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase Analytics
      _firebaseAnalytics = FirebaseAnalytics.instance;
      await _firebaseAnalytics.setAnalyticsCollectionEnabled(true);

      // Initialize Mixpanel
      _mixpanel = await Mixpanel.init('YOUR_MIXPANEL_TOKEN', trackAutomaticEvents: true);

      _isInitialized = true;
      debugPrint('Analytics services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing analytics: $e');
    }
  }

  // Track user sign up
  Future<void> trackUserSignUp({
    required String userId,
    required String userType,
    required String email,
  }) async {
    if (!_isInitialized) return;

    final eventData = {
      'user_id': userId,
      'user_type': userType,
      'email': email,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firebaseAnalytics.logEvent(
      name: eventUserSignUp,
      parameters: eventData.map((key, value) => MapEntry(key, value.toString())),
    );

    _mixpanel.track(eventUserSignUp);
  }

  // Track user login
  Future<void> trackUserLogin({
    required String userId,
    required String userType,
  }) async {
    if (!_isInitialized) return;

    final eventData = {
      'user_id': userId,
      'user_type': userType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firebaseAnalytics.logEvent(
      name: eventUserLogin,
      parameters: eventData.map((key, value) => MapEntry(key, value.toString())),
    );

    _mixpanel.track(eventUserLogin);
  }

  // Track property view
  Future<void> trackPropertyViewed({
    required String propertyId,
    required String propertyTitle,
    required double propertyPrice,
    required String propertyType,
  }) async {
    if (!_isInitialized) return;

    final eventData = {
      'property_id': propertyId,
      'property_title': propertyTitle,
      'property_price': propertyPrice,
      'property_type': propertyType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firebaseAnalytics.logEvent(
      name: eventPropertyViewed,
      parameters: eventData.map((key, value) => MapEntry(key, value.toString())),
    );

    _mixpanel.track(eventPropertyViewed);
  }

  // Track purchase request submission
  Future<void> trackPurchaseRequestSubmitted({
    required String propertyId,
    required String propertyTitle,
    required double offerAmount,
    required String buyerId,
  }) async {
    if (!_isInitialized) return;

    final eventData = {
      'property_id': propertyId,
      'property_title': propertyTitle,
      'offer_amount': offerAmount,
      'buyer_id': buyerId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firebaseAnalytics.logEvent(
      name: eventPurchaseRequestSubmitted,
      parameters: eventData.map((key, value) => MapEntry(key, value.toString())),
    );

    _mixpanel.track(eventPurchaseRequestSubmitted);
  }

  // Track payment completion
  Future<void> trackPaymentCompleted({
    required String requestId,
    required double amount,
    required String paymentMethod,
    required String buyerId,
  }) async {
    if (!_isInitialized) return;

    final eventData = {
      'request_id': requestId,
      'amount': amount,
      'payment_method': paymentMethod,
      'buyer_id': buyerId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firebaseAnalytics.logEvent(
      name: eventPaymentCompleted,
      parameters: eventData.map((key, value) => MapEntry(key, value.toString())),
    );

    _mixpanel.track(eventPaymentCompleted);
  }

  // Track subscription purchase
  Future<void> trackSubscriptionPurchased({
    required String subscriptionId,
    required String tier,
    required double price,
    required String userId,
  }) async {
    if (!_isInitialized) return;

    final eventData = {
      'subscription_id': subscriptionId,
      'tier': tier,
      'price': price,
      'user_id': userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firebaseAnalytics.logEvent(
      name: eventSubscriptionPurchased,
      parameters: eventData.map((key, value) => MapEntry(key, value.toString())),
    );

    _mixpanel.track(eventSubscriptionPurchased);
  }

  // Track ad interactions
  Future<void> trackAdViewed({
    required String adUnitId,
    required String adType,
  }) async {
    if (!_isInitialized) return;

    final eventData = {
      'ad_unit_id': adUnitId,
      'ad_type': adType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firebaseAnalytics.logEvent(
      name: eventAdViewed,
      parameters: eventData.map((key, value) => MapEntry(key, value.toString())),
    );

    _mixpanel.track(eventAdViewed);
  }

  Future<void> trackAdClicked({
    required String adUnitId,
    required String adType,
  }) async {
    if (!_isInitialized) return;

    final eventData = {
      'ad_unit_id': adUnitId,
      'ad_type': adType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firebaseAnalytics.logEvent(
      name: eventAdClicked,
      parameters: eventData.map((key, value) => MapEntry(key, value.toString())),
    );

    _mixpanel.track(eventAdClicked);
  }

  // Set user properties
  Future<void> setUserProperties({
    required String userId,
    required String userType,
    String? subscriptionTier,
    int? totalRequests,
    int? totalPayments,
  }) async {
    if (!_isInitialized) return;

    final userProperties = {
      userPropertyUserType: userType,
      if (subscriptionTier != null) userPropertySubscriptionTier: subscriptionTier,
      if (totalRequests != null) userPropertyTotalRequests: totalRequests,
      if (totalPayments != null) userPropertyTotalPayments: totalPayments,
      userPropertyJoinDate: DateTime.now().millisecondsSinceEpoch,
    };

    for (final entry in userProperties.entries) {
      await _firebaseAnalytics.setUserProperty(name: entry.key, value: entry.value.toString());
      _mixpanel.getPeople().set(entry.key, entry.value);
    }
    await _firebaseAnalytics.setUserId(id: userId);
  }

  // Track custom events
  Future<void> trackCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) return;

    final eventData = {
      ...?parameters,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firebaseAnalytics.logEvent(
      name: eventName,
      parameters: eventData.map((key, value) => MapEntry(key, value.toString())),
    );

    _mixpanel.track(eventName);
  }

  // Get analytics data for dashboard
  Future<Map<String, dynamic>> getAnalyticsData() async {
    if (!_isInitialized) return {};

    try {
      // This would typically involve API calls to get aggregated data
      // For now, we'll return a mock structure
      return {
        'total_users': 0,
        'total_properties': 0,
        'total_requests': 0,
        'total_revenue': 0.0,
        'conversion_rate': 0.0,
        'average_session_duration': 0,
        'top_properties': [],
        'user_growth': [],
        'revenue_trends': [],
      };
    } catch (e) {
      debugPrint('Error getting analytics data: $e');
      return {};
    }
  }

  // Track app performance
  Future<void> trackPerformance({
    required String metricName,
    required int value,
    String? category,
  }) async {
    if (!_isInitialized) return;

    final eventData = {
      'metric_name': metricName,
      'value': value,
      if (category != null) 'category': category,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firebaseAnalytics.logEvent(
      name: 'performance_metric',
      parameters: eventData.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  // Track errors
  Future<void> trackError({
    required String errorMessage,
    required String errorType,
    String? stackTrace,
  }) async {
    if (!_isInitialized) return;

    final eventData = {
      'error_message': errorMessage,
      'error_type': errorType,
      if (stackTrace != null) 'stack_trace': stackTrace,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firebaseAnalytics.logEvent(
      name: 'app_error',
      parameters: eventData.map((key, value) => MapEntry(key, value.toString())),
    );

    _mixpanel.track('app_error');
  }
} 