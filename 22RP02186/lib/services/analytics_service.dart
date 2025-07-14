import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Track user registration
  Future<void> trackUserRegistration(String userEmail, String userRole) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'user_registration',
        'userEmail': userEmail,
        'userRole': userRole,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking user registration: $e');
    }
  }

  // Track user login
  Future<void> trackUserLogin(String userEmail, String userRole) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'user_login',
        'userEmail': userEmail,
        'userRole': userRole,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking user login: $e');
    }
  }

  // Track course creation
  Future<void> trackCourseCreation(String trainerEmail, String courseTitle) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'course_creation',
        'trainerEmail': trainerEmail,
        'courseTitle': courseTitle,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking course creation: $e');
    }
  }

  // Track course completion
  Future<void> trackCourseCompletion(String userEmail, String courseTitle) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'course_completion',
        'userEmail': userEmail,
        'courseTitle': courseTitle,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking course completion: $e');
    }
  }

  // Track skill addition
  Future<void> trackSkillAddition(String userEmail, String skillName) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'skill_addition',
        'userEmail': userEmail,
        'skillName': skillName,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking skill addition: $e');
    }
  }

  // Track connection request
  Future<void> trackConnectionRequest(String fromEmail, String toEmail) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'connection_request',
        'fromEmail': fromEmail,
        'toEmail': toEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking connection request: $e');
    }
  }

  // Track premium feature access
  Future<void> trackPremiumFeatureAccess(String userEmail, String featureName) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'premium_feature_access',
        'userEmail': userEmail,
        'featureName': featureName,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking premium feature access: $e');
    }
  }

  // Track subscription attempt
  Future<void> trackSubscriptionAttempt(String userEmail, String planName) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'subscription_attempt',
        'userEmail': userEmail,
        'planName': planName,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking subscription attempt: $e');
    }
  }

  // Track chat message sent
  Future<void> trackChatMessage(String userEmail, String recipientEmail) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'chat_message_sent',
        'userEmail': userEmail,
        'recipientEmail': recipientEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking chat message: $e');
    }
  }

  // Track search query
  Future<void> trackSearchQuery(String userEmail, String query, String category) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'search_query',
        'userEmail': userEmail,
        'query': query,
        'category': category,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking search query: $e');
    }
  }

  // Track app session
  Future<void> trackAppSession(String userEmail, String userRole, int sessionDuration) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'app_session',
        'userEmail': userEmail,
        'userRole': userRole,
        'sessionDuration': sessionDuration, // in seconds
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking app session: $e');
    }
  }

  // Track feature usage
  Future<void> trackFeatureUsage(String userEmail, String featureName, String userRole) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'event': 'feature_usage',
        'userEmail': userEmail,
        'featureName': featureName,
        'userRole': userRole,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      print('Error tracking feature usage: $e');
    }
  }

  // Get analytics summary for dashboard
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      final lastMonth = now.subtract(const Duration(days: 30));

      // Get user registrations in last 7 days
      final registrationsQuery = await FirebaseFirestore.instance
          .collection('analytics')
          .where('event', isEqualTo: 'user_registration')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      // Get course completions in last 30 days
      final completionsQuery = await FirebaseFirestore.instance
          .collection('analytics')
          .where('event', isEqualTo: 'course_completion')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastMonth))
          .get();

      // Get connection requests in last 7 days
      final connectionsQuery = await FirebaseFirestore.instance
          .collection('analytics')
          .where('event', isEqualTo: 'connection_request')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      // Get premium feature access in last 30 days
      final premiumQuery = await FirebaseFirestore.instance
          .collection('analytics')
          .where('event', isEqualTo: 'premium_feature_access')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastMonth))
          .get();

      return {
        'newRegistrations': registrationsQuery.docs.length,
        'courseCompletions': completionsQuery.docs.length,
        'connectionRequests': connectionsQuery.docs.length,
        'premiumFeatureAccess': premiumQuery.docs.length,
        'lastUpdated': now.toIso8601String(),
      };
    } catch (e) {
      print('Error getting analytics summary: $e');
      return {
        'newRegistrations': 0,
        'courseCompletions': 0,
        'connectionRequests': 0,
        'premiumFeatureAccess': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get user engagement metrics
  Future<Map<String, dynamic>> getUserEngagementMetrics(String userEmail) async {
    try {
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));

      // Get user's course completions
      final completionsQuery = await FirebaseFirestore.instance
          .collection('analytics')
          .where('event', isEqualTo: 'course_completion')
          .where('userEmail', isEqualTo: userEmail)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastMonth))
          .get();

      // Get user's feature usage
      final featureQuery = await FirebaseFirestore.instance
          .collection('analytics')
          .where('event', isEqualTo: 'feature_usage')
          .where('userEmail', isEqualTo: userEmail)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastMonth))
          .get();

      // Get user's chat activity
      final chatQuery = await FirebaseFirestore.instance
          .collection('analytics')
          .where('event', isEqualTo: 'chat_message_sent')
          .where('userEmail', isEqualTo: userEmail)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastMonth))
          .get();

      return {
        'courseCompletions': completionsQuery.docs.length,
        'featureUsage': featureQuery.docs.length,
        'chatMessages': chatQuery.docs.length,
        'engagementScore': _calculateEngagementScore(
          completionsQuery.docs.length,
          featureQuery.docs.length,
          chatQuery.docs.length,
        ),
      };
    } catch (e) {
      print('Error getting user engagement metrics: $e');
      return {
        'courseCompletions': 0,
        'featureUsage': 0,
        'chatMessages': 0,
        'engagementScore': 0,
      };
    }
  }

  int _calculateEngagementScore(int completions, int features, int messages) {
    // Simple engagement score calculation
    return (completions * 10) + (features * 5) + (messages * 2);
  }
} 