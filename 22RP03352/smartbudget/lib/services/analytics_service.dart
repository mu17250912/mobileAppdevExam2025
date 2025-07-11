import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Debug logging for development
  static void _debugLog(String eventName, Map<String, Object>? parameters) {
    if (kDebugMode) {
      print('📊 ANALYTICS EVENT: $eventName');
      if (parameters != null) {
        parameters.forEach((key, value) {
          print('   $key: $value');
        });
      }
      print('---');
    }
  }

  // Initialize analytics for the current user
  static Future<void> setUserProperties() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _analytics.setUserId(id: user.uid);
      await _analytics.setUserProperty(name: 'user_email', value: user.email);
      await _analytics.setUserProperty(name: 'registration_date', value: user.metadata.creationTime?.toIso8601String());
      
      if (kDebugMode) {
        print('👤 USER PROPERTIES SET:');
        print('   User ID: ${user.uid}');
        print('   Email: ${user.email}');
        print('   Registration: ${user.metadata.creationTime}');
        print('---');
      }
    }
  }

  // Track app open
  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
    _debugLog('app_open', null);
  }

  // Track screen views
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
    _debugLog('screen_view', {
      'screen_name': screenName,
      'screen_class': screenClass ?? 'unknown',
    });
  }

  // Track user login
  static Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
    _debugLog('login', {'method': method});
  }

  // Track user sign up
  static Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
    _debugLog('sign_up', {'method': method});
  }

  // Track budget creation
  static Future<void> logBudgetCreated({
    required String category,
    required double amount,
  }) async {
    final parameters = {
      'category': category,
      'amount': amount,
      'currency': 'RWF',
    };
    await _analytics.logEvent(
      name: 'budget_created',
      parameters: parameters,
    );
    _debugLog('budget_created', parameters);
  }

  // Track expense added
  static Future<void> logExpenseAdded({
    required String category,
    required double amount,
    required String note,
  }) async {
    final parameters = {
      'category': category,
      'amount': amount,
      'note_length': note.length,
      'currency': 'RWF',
    };
    await _analytics.logEvent(
      name: 'expense_added',
      parameters: parameters,
    );
    _debugLog('expense_added', parameters);
  }

  // Track budget exceeded
  static Future<void> logBudgetExceeded({
    required String category,
    required double budgetAmount,
    required double spentAmount,
  }) async {
    final parameters = {
      'category': category,
      'budget_amount': budgetAmount,
      'spent_amount': spentAmount,
      'excess_amount': spentAmount - budgetAmount,
      'currency': 'RWF',
    };
    await _analytics.logEvent(
      name: 'budget_exceeded',
      parameters: parameters,
    );
    _debugLog('budget_exceeded', parameters);
  }

  // Track premium subscription
  static Future<void> logPremiumSubscription({
    required String planType,
    required double price,
  }) async {
    final parameters = {
      'plan_type': planType,
      'price': price,
      'currency': 'USD',
    };
    await _analytics.logEvent(
      name: 'premium_subscription',
      parameters: parameters,
    );
    _debugLog('premium_subscription', parameters);
  }

  // Track ad interaction
  static Future<void> logAdInteraction({
    required String adType,
    required String action,
  }) async {
    final parameters = {
      'ad_type': adType,
      'action': action,
    };
    await _analytics.logEvent(
      name: 'ad_interaction',
      parameters: parameters,
    );
    _debugLog('ad_interaction', parameters);
  }

  // Track feature usage
  static Future<void> logFeatureUsage({
    required String featureName,
    Map<String, Object>? additionalParams,
  }) async {
    Map<String, Object> parameters = {
      'feature_name': featureName,
    };
    if (additionalParams != null) {
      parameters.addAll(additionalParams);
    }
    
    await _analytics.logEvent(
      name: 'feature_usage',
      parameters: parameters,
    );
    _debugLog('feature_usage', parameters);
  }

  // Track user engagement
  static Future<void> logUserEngagement({
    required String engagementType,
    required int duration,
  }) async {
    final parameters = {
      'engagement_type': engagementType,
      'duration_seconds': duration,
    };
    await _analytics.logEvent(
      name: 'user_engagement',
      parameters: parameters,
    );
    _debugLog('user_engagement', parameters);
  }

  // Track app performance
  static Future<void> logAppPerformance({
    required String metric,
    required double value,
    String? unit,
  }) async {
    Map<String, Object> parameters = {
      'metric': metric,
      'value': value,
    };
    if (unit != null) {
      parameters['unit'] = unit;
    }
    
    await _analytics.logEvent(
      name: 'app_performance',
      parameters: parameters,
    );
    _debugLog('app_performance', parameters);
  }

  // Track error events
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    Map<String, Object> parameters = {
      'error_type': errorType,
      'error_message': errorMessage,
    };
    if (screenName != null) {
      parameters['screen_name'] = screenName;
    }
    
    await _analytics.logEvent(
      name: 'app_error',
      parameters: parameters,
    );
    _debugLog('app_error', parameters);
  }

  // Track user retention
  static Future<void> logUserRetention({
    required int daysSinceFirstOpen,
    required int daysSinceLastOpen,
  }) async {
    final parameters = {
      'days_since_first_open': daysSinceFirstOpen,
      'days_since_last_open': daysSinceLastOpen,
    };
    await _analytics.logEvent(
      name: 'user_retention',
      parameters: parameters,
    );
    _debugLog('user_retention', parameters);
  }

  // Track conversion events
  static Future<void> logConversion({
    required String conversionType,
    required double value,
    String? currency,
  }) async {
    Map<String, Object> parameters = {
      'conversion_type': conversionType,
      'value': value,
    };
    if (currency != null) {
      parameters['currency'] = currency;
    }
    
    await _analytics.logEvent(
      name: 'conversion',
      parameters: parameters,
    );
    _debugLog('conversion', parameters);
  }

  // Test analytics function
  static Future<void> testAnalytics() async {
    if (kDebugMode) {
      print('🧪 TESTING ANALYTICS EVENTS...');
      
      await logAppOpen();
      await logScreenView(screenName: 'test_screen');
      await logFeatureUsage(featureName: 'test_feature');
      await logBudgetCreated(category: 'Test Category', amount: 1000.0);
      await logExpenseAdded(category: 'Test Category', amount: 500.0, note: 'Test expense');
      await logBudgetExceeded(category: 'Test Category', budgetAmount: 1000.0, spentAmount: 1200.0);
      await logAdInteraction(adType: 'banner', action: 'clicked');
      await logPremiumSubscription(planType: 'monthly', price: 4.99);
      
      print('✅ ANALYTICS TEST COMPLETED!');
    }
  }

  // Get analytics instance for custom events
  static FirebaseAnalytics get instance => _analytics;
} 