import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final AnalyticsService _instance = AnalyticsService._internal();
  
  factory AnalyticsService() {
    return _instance;
  }
  
  AnalyticsService._internal();

  // Initialize analytics
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  // Set user properties
  Future<void> setUserProperties({
    required String userId,
    required String userEmail,
    String? userType,
    bool? isPremium,
    String? subscriptionPlan,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'user_email', value: userEmail);
    await _analytics.setUserProperty(name: 'user_type', value: userType ?? 'free');
    await _analytics.setUserProperty(name: 'is_premium', value: isPremium?.toString() ?? 'false');
    await _analytics.setUserProperty(name: 'subscription_plan', value: subscriptionPlan ?? 'free');
  }

  // Track user registration
  Future<void> trackUserRegistration({
    required String method,
    required String userId,
    String? userEmail,
  }) async {
    await _analytics.logEvent(
      name: 'user_registration',
      parameters: {
        'registration_method': method,
        'user_id': userId,
        'user_email': userEmail ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track user login
  Future<void> trackUserLogin({
    required String method,
    required String userId,
  }) async {
    await _analytics.logEvent(
      name: 'user_login',
      parameters: {
        'login_method': method,
        'user_id': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track subscription events
  Future<void> trackSubscriptionStarted({
    required String userId,
    required String planId,
    required double amount,
    required String currency,
    String? paymentMethod,
  }) async {
    await _analytics.logEvent(
      name: 'subscription_started',
      parameters: {
        'user_id': userId,
        'plan_id': planId,
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod ?? 'unknown',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> trackSubscriptionRenewed({
    required String userId,
    required String planId,
    required double amount,
    required String currency,
  }) async {
    await _analytics.logEvent(
      name: 'subscription_renewed',
      parameters: {
        'user_id': userId,
        'plan_id': planId,
        'amount': amount,
        'currency': currency,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> trackSubscriptionCancelled({
    required String userId,
    required String planId,
    String? reason,
  }) async {
    await _analytics.logEvent(
      name: 'subscription_cancelled',
      parameters: {
        'user_id': userId,
        'plan_id': planId,
        'cancellation_reason': reason ?? 'user_requested',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> trackSubscriptionExpired({
    required String userId,
    required String planId,
  }) async {
    await _analytics.logEvent(
      name: 'subscription_expired',
      parameters: {
        'user_id': userId,
        'plan_id': planId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track revenue events
  Future<void> trackRevenue({
    required String userId,
    required double amount,
    required String currency,
    required String source,
    String? planId,
    String? transactionId,
  }) async {
    await _analytics.logEvent(
      name: 'revenue_generated',
      parameters: {
        'user_id': userId,
        'amount': amount,
        'currency': currency,
        'source': source,
        'plan_id': planId ?? '',
        'transaction_id': transactionId ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track feature usage
  Future<void> trackFeatureUsage({
    required String userId,
    required String featureName,
    String? additionalData,
  }) async {
    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {
        'user_id': userId,
        'feature_name': featureName,
        'additional_data': additionalData ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track task events
  Future<void> trackTaskCreated({
    required String userId,
    required String taskCategory,
    bool isPremium = false,
  }) async {
    await _analytics.logEvent(
      name: 'task_created',
      parameters: {
        'user_id': userId,
        'task_category': taskCategory,
        'is_premium': isPremium,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> trackTaskCompleted({
    required String userId,
    required String taskCategory,
    bool isPremium = false,
  }) async {
    await _analytics.logEvent(
      name: 'task_completed',
      parameters: {
        'user_id': userId,
        'task_category': taskCategory,
        'is_premium': isPremium,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track note events
  Future<void> trackNoteCreated({
    required String userId,
    bool isPremium = false,
  }) async {
    await _analytics.logEvent(
      name: 'note_created',
      parameters: {
        'user_id': userId,
        'is_premium': isPremium,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track screen views
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // Track user engagement
  Future<void> trackUserEngagement({
    required String userId,
    required String action,
    String? screenName,
    Map<String, dynamic>? additionalData,
  }) async {
    await _analytics.logEvent(
      name: 'user_engagement',
      parameters: {
        'user_id': userId,
        'action': action,
        'screen_name': screenName ?? '',
        'additional_data': additionalData?.toString() ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track conversion events
  Future<void> trackConversion({
    required String userId,
    required String conversionType,
    String? source,
    double? value,
    String? currency,
  }) async {
    await _analytics.logEvent(
      name: 'conversion',
      parameters: {
        'user_id': userId,
        'conversion_type': conversionType,
        'source': source ?? '',
        'value': value ?? 0.0,
        'currency': currency ?? 'USD',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track error events
  Future<void> trackError({
    required String userId,
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'user_id': userId,
        'error_type': errorType,
        'error_message': errorMessage,
        'screen_name': screenName ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track app performance
  Future<void> trackPerformance({
    required String userId,
    required String metricName,
    required double value,
    String? unit,
  }) async {
    await _analytics.logEvent(
      name: 'performance_metric',
      parameters: {
        'user_id': userId,
        'metric_name': metricName,
        'value': value,
        'unit': unit ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Get analytics instance for custom events
  FirebaseAnalytics get analytics => _analytics;

  // Track custom events
  Future<void> trackCustomEvent({
    required String eventName,
    required Map<String, Object> parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }
} 