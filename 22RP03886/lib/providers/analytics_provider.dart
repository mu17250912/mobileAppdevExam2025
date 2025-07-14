import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../models/user_profile.dart';
import '../models/subscription.dart';

class AnalyticsProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isInitialized = false;
  String? _currentUserId;
  UserProfile? _currentUser;

  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUserId;
  UserProfile? get currentUser => _currentUser;

  // Initialize analytics
  Future<void> initialize() async {
    if (!_isInitialized) {
      await AnalyticsService.initialize();
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Set current user for analytics
  void setCurrentUser(UserProfile user) {
    _currentUser = user;
    _currentUserId = user.uid;
    _updateUserProperties();
  }

  // Update user properties in analytics
  Future<void> _updateUserProperties() async {
    if (_currentUser != null) {
      await _analyticsService.setUserProperties(
        userId: _currentUser!.uid,
        userEmail: _currentUser!.email,
        userType: _currentUser!.isPremium ? 'premium' : 'free',
        isPremium: _currentUser!.isPremium,
        subscriptionPlan: _currentUser!.subscriptionPlan,
      );
    }
  }

  // Track user registration
  Future<void> trackRegistration({
    required String method,
    String? userEmail,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackUserRegistration(
        method: method,
        userId: _currentUserId!,
        userEmail: userEmail,
      );
    }
  }

  // Track user login
  Future<void> trackLogin({required String method}) async {
    if (_currentUserId != null) {
      await _analyticsService.trackUserLogin(
        method: method,
        userId: _currentUserId!,
      );
    }
  }

  // Track subscription events
  Future<void> trackSubscriptionStarted({
    required String planId,
    required double amount,
    required String currency,
    String? paymentMethod,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackSubscriptionStarted(
        userId: _currentUserId!,
        planId: planId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
      );

      // Track revenue
      await _analyticsService.trackRevenue(
        userId: _currentUserId!,
        amount: amount,
        currency: currency,
        source: 'subscription',
        planId: planId,
      );

      // Track conversion
      await _analyticsService.trackConversion(
        userId: _currentUserId!,
        conversionType: 'subscription_started',
        source: 'app',
        value: amount,
        currency: currency,
      );
    }
  }

  Future<void> trackSubscriptionRenewed({
    required String planId,
    required double amount,
    required String currency,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackSubscriptionRenewed(
        userId: _currentUserId!,
        planId: planId,
        amount: amount,
        currency: currency,
      );

      // Track revenue
      await _analyticsService.trackRevenue(
        userId: _currentUserId!,
        amount: amount,
        currency: currency,
        source: 'subscription_renewal',
        planId: planId,
      );
    }
  }

  Future<void> trackSubscriptionCancelled({
    required String planId,
    String? reason,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackSubscriptionCancelled(
        userId: _currentUserId!,
        planId: planId,
        reason: reason,
      );
    }
  }

  Future<void> trackSubscriptionExpired({
    required String planId,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackSubscriptionExpired(
        userId: _currentUserId!,
        planId: planId,
      );
    }
  }

  // Track feature usage
  Future<void> trackFeatureUsage({
    required String featureName,
    String? additionalData,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackFeatureUsage(
        userId: _currentUserId!,
        featureName: featureName,
        additionalData: additionalData,
      );
    }
  }

  // Track task events
  Future<void> trackTaskCreated({
    required String taskCategory,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackTaskCreated(
        userId: _currentUserId!,
        taskCategory: taskCategory,
        isPremium: _currentUser?.isPremium ?? false,
      );
    }
  }

  Future<void> trackTaskCompleted({
    required String taskCategory,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackTaskCompleted(
        userId: _currentUserId!,
        taskCategory: taskCategory,
        isPremium: _currentUser?.isPremium ?? false,
      );
    }
  }

  // Track note events
  Future<void> trackNoteCreated() async {
    if (_currentUserId != null) {
      await _analyticsService.trackNoteCreated(
        userId: _currentUserId!,
        isPremium: _currentUser?.isPremium ?? false,
      );
    }
  }

  // Track screen views
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analyticsService.trackScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // Track user engagement
  Future<void> trackUserEngagement({
    required String action,
    String? screenName,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackUserEngagement(
        userId: _currentUserId!,
        action: action,
        screenName: screenName,
        additionalData: additionalData,
      );
    }
  }

  // Track conversion events
  Future<void> trackConversion({
    required String conversionType,
    String? source,
    double? value,
    String? currency,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackConversion(
        userId: _currentUserId!,
        conversionType: conversionType,
        source: source,
        value: value,
        currency: currency,
      );
    }
  }

  // Track error events
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackError(
        userId: _currentUserId!,
        errorType: errorType,
        errorMessage: errorMessage,
        screenName: screenName,
      );
    }
  }

  // Track app performance
  Future<void> trackPerformance({
    required String metricName,
    required double value,
    String? unit,
  }) async {
    if (_currentUserId != null) {
      await _analyticsService.trackPerformance(
        userId: _currentUserId!,
        metricName: metricName,
        value: value,
        unit: unit,
      );
    }
  }

  // Track custom events
  Future<void> trackCustomEvent({
    required String eventName,
    required Map<String, Object> parameters,
  }) async {
    await _analyticsService.trackCustomEvent(
      eventName: eventName,
      parameters: parameters,
    );
  }

  // Clear user data (for logout)
  void clearUserData() {
    _currentUser = null;
    _currentUserId = null;
    notifyListeners();
  }

  // Get analytics service instance
  AnalyticsService get analyticsService => _analyticsService;
} 