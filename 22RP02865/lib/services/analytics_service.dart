import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Track app opens
  Future<void> trackAppOpen() async {
    await _analytics.logAppOpen();
  }

  // Track task creation
  Future<void> trackTaskCreated(String subject) async {
    await _analytics.logEvent(
      name: 'task_created',
      parameters: {
        'subject': subject,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track task completion
  Future<void> trackTaskCompleted(String subject) async {
    await _analytics.logEvent(
      name: 'task_completed',
      parameters: {
        'subject': subject,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track goal creation
  Future<void> trackGoalCreated(String goalTitle) async {
    await _analytics.logEvent(
      name: 'goal_created',
      parameters: {
        'goal_title': goalTitle,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track goal completion
  Future<void> trackGoalCompleted(String goalTitle) async {
    await _analytics.logEvent(
      name: 'goal_completed',
      parameters: {
        'goal_title': goalTitle,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track premium upgrade
  Future<void> trackPremiumUpgrade(String planType) async {
    await _analytics.logEvent(
      name: 'premium_upgrade',
      parameters: {
        'plan_type': planType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track ad click
  Future<void> trackAdClick(String adType) async {
    await _analytics.logEvent(
      name: 'ad_clicked',
      parameters: {
        'ad_type': adType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track ad loaded
  Future<void> trackAdLoaded(String adType) async {
    await _analytics.logEvent(
      name: 'ad_loaded',
      parameters: {
        'ad_type': adType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track ad shown
  Future<void> trackAdShown(String adType) async {
    await _analytics.logEvent(
      name: 'ad_shown',
      parameters: {
        'ad_type': adType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track ad reward earned
  Future<void> trackAdRewardEarned(String rewardAmount) async {
    await _analytics.logEvent(
      name: 'ad_reward_earned',
      parameters: {
        'reward_amount': rewardAmount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track general events
  Future<void> trackEvent(String eventName, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: {
        ...parameters,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track user engagement
  Future<void> trackUserEngagement(String feature) async {
    await _analytics.logEvent(
      name: 'user_engagement',
      parameters: {
        'feature': feature,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track study session
  Future<void> trackStudySession(int durationMinutes) async {
    await _analytics.logEvent(
      name: 'study_session',
      parameters: {
        'duration_minutes': durationMinutes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Track feedback submission
  Future<void> trackFeedbackSubmitted() async {
    await _analytics.logEvent(
      name: 'feedback_submitted',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Set user properties
  Future<void> setUserProperties({
    required String userId,
    required bool isPremium,
    required String userType,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'is_premium', value: isPremium.toString());
    await _analytics.setUserProperty(name: 'user_type', value: userType);
  }
} 