// analytics_stub.dart
// This file demonstrates where you would integrate Firebase Analytics or another analytics tool.

class AnalyticsStub {
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    // In a real app, you would call FirebaseAnalytics.instance.logEvent(...)
    print('Analytics event: ' + eventName + (parameters != null ? ' | params: $parameters' : ''));
  }
}

// Example usage:
// AnalyticsStub.logEvent('course_started', parameters: {'courseId': 'abc123'}); 