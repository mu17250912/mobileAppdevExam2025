import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize analytics
  Future<void> initialize() async {
    try {
      // Enable analytics collection
      await _analytics.setAnalyticsCollectionEnabled(true);
      
      // Set user properties
      await _setUserProperties();
      
      // Track app open
      await _analytics.logAppOpen();
    } catch (e) {
      print('Error initializing Firebase Analytics: $e');
    }
  }

  // Set user properties
  Future<void> _setUserProperties() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _analytics.setUserId(id: user.uid);
        
        // Get user role from Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final role = userData['role'] ?? 'unknown';
          await _analytics.setUserProperty(name: 'user_role', value: role);
        }
      }
    } catch (e) {
      print('Error setting user properties: $e');
    }
  }

  // Track user registration
  Future<void> trackUserRegistration({
    required String method,
    required String role,
  }) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      await _analytics.logEvent(
        name: 'user_registration',
        parameters: {
          'registration_method': method,
          'user_role': role,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking user registration: $e');
    }
  }

  // Track user login
  Future<void> trackUserLogin({
    required String method,
    required String role,
  }) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      await _analytics.logEvent(
        name: 'user_login',
        parameters: {
          'login_method': method,
          'user_role': role,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking user login: $e');
    }
  }

  // Track medication management events
  Future<void> trackMedicationEvent({
    required String eventType,
    required String medicationName,
    String? frequency,
    int? dosage,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'medication_management',
        parameters: {
          'event_type': eventType, // add, edit, delete, schedule
          'medication_name': medicationName,
          'frequency': frequency,
          'dosage': dosage,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking medication event: $e');
    }
  }

  // Track adherence events
  Future<void> trackAdherenceEvent({
    required String eventType,
    required String medicationName,
    required bool taken,
    String? reason,
    int? streak,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'medication_adherence',
        parameters: {
          'event_type': eventType, // reminder, taken, missed, streak
          'medication_name': medicationName,
          'taken': taken,
          'reason': reason,
          'streak': streak,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking adherence event: $e');
    }
  }

  // Track notification events
  Future<void> trackNotificationEvent({
    required String eventType,
    required String notificationType,
    bool? actionTaken,
    String? actionType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'notification_interaction',
        parameters: {
          'event_type': eventType, // received, opened, dismissed, action
          'notification_type': notificationType, // reminder, re_reminder, emergency
          'action_taken': actionTaken,
          'action_type': actionType, // mark_taken, view_details, call_emergency
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking notification event: $e');
    }
  }

  // Track caregiver events
  Future<void> trackCaregiverEvent({
    required String eventType,
    String? patientId,
    String? actionType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'caregiver_activity',
        parameters: {
          'event_type': eventType, // patient_assigned, patient_removed, adherence_check
          'patient_id': patientId,
          'action_type': actionType,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking caregiver event: $e');
    }
  }

  // Track emergency contact events
  Future<void> trackEmergencyEvent({
    required String eventType,
    String? contactType,
    bool? callInitiated,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'emergency_contact',
        parameters: {
          'event_type': eventType, // contact_added, contact_called, contact_shared
          'contact_type': contactType, // family, doctor, emergency
          'call_initiated': callInitiated,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking emergency event: $e');
    }
  }

  // Track voice reminder events
  Future<void> trackVoiceEvent({
    required String eventType,
    String? medicationName,
    bool? success,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'voice_reminder',
        parameters: {
          'event_type': eventType, // reminder_played, instruction_read, error
          'medication_name': medicationName,
          'success': success,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking voice event: $e');
    }
  }

  // Track offline mode events
  Future<void> trackOfflineEvent({
    required String eventType,
    bool? syncSuccess,
    int? dataCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'offline_mode',
        parameters: {
          'event_type': eventType, // mode_entered, mode_exited, data_synced
          'sync_success': syncSuccess,
          'data_count': dataCount,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking offline event: $e');
    }
  }

  // Track analytics usage
  Future<void> trackAnalyticsUsage({
    required String reportType,
    required String timeRange,
    bool? exported,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'analytics_usage',
        parameters: {
          'report_type': reportType, // adherence, medication_breakdown, streaks
          'time_range': timeRange, // daily, weekly, monthly, yearly
          'exported': exported,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking analytics usage: $e');
    }
  }

  // Track settings changes
  Future<void> trackSettingsChange({
    required String settingType,
    required String oldValue,
    required String newValue,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'settings_change',
        parameters: {
          'setting_type': settingType, // notification, theme, language, accessibility
          'old_value': oldValue,
          'new_value': newValue,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking settings change: $e');
    }
  }

  // Track subscription events
  Future<void> trackSubscriptionEvent({
    required String eventType,
    required String tier,
    String? productId,
    double? price,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'subscription_event',
        parameters: {
          'event_type': eventType, // trial_started, purchased, renewed, canceled
          'tier': tier, // free, premium, family
          'product_id': productId,
          'price': price,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking subscription event: $e');
    }
  }

  // Track feature usage
  Future<void> trackFeatureUsage({
    required String featureName,
    required String action,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final parameters = {
        'feature_name': featureName,
        'action': action,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (additionalParams != null) {
        parameters.addAll(Map<String, Object>.from(additionalParams));
      }

      await _analytics.logEvent(
        name: 'feature_usage',
        parameters: parameters,
      );
    } catch (e) {
      print('Error tracking feature usage: $e');
    }
  }

  // Track app performance
  Future<void> trackAppPerformance({
    required String metric,
    required double value,
    String? unit,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'app_performance',
        parameters: {
          'metric': metric, // load_time, response_time, memory_usage
          'value': value,
          'unit': unit,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking app performance: $e');
    }
  }

  // Track user engagement
  Future<void> trackUserEngagement({
    required String engagementType,
    required int duration,
    String? screenName,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'user_engagement',
        parameters: {
          'engagement_type': engagementType, // session, screen_view, feature_use
          'duration_seconds': duration,
          'screen_name': screenName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking user engagement: $e');
    }
  }

  // Track error events
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'error_message': errorMessage,
          'stack_trace': stackTrace,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking error event: $e');
    }
  }

  // Track screen views
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      print('Error tracking screen view: $e');
    }
  }

  // Track custom events
  Future<void> trackCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e) {
      print('Error tracking custom event: $e');
    }
  }

  // Set user properties
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      print('Error setting user property: $e');
    }
  }

  // Get analytics instance for direct access
  FirebaseAnalytics get analytics => _analytics;
} 