import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../services/notification_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionModel? _currentSubscription;
  List<SubscriptionModel> _subscriptionHistory = [];
  bool _isLoading = false;
  String? _error;
  bool _hasActiveSubscription = false;
  bool _hasPremiumFeatures = false;
  List<String> _userFeatures = [];

  // Getters
  SubscriptionModel? get currentSubscription => _currentSubscription;
  List<SubscriptionModel> get subscriptionHistory => _subscriptionHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSubscription => _hasActiveSubscription;
  bool get hasPremiumFeatures => _hasPremiumFeatures;
  List<String> get userFeatures => _userFeatures;

  // Initialize subscription
  void initialize() {
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSubscription();
      _loadSubscriptionHistory();
      _loadUserFeatures();
    });
  }

  // Load current subscription
  Future<void> _loadCurrentSubscription() async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentSubscription = await SubscriptionService.getUserSubscription();
      _hasActiveSubscription = _currentSubscription?.isActive ?? false;
      _hasPremiumFeatures = _currentSubscription?.isPremium ?? false;
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load subscription history
  Future<void> _loadSubscriptionHistory() async {
    try {
      SubscriptionService.getSubscriptionHistory().listen((history) {
        _subscriptionHistory = history;
        // Use addPostFrameCallback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      });
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Load user features
  Future<void> _loadUserFeatures() async {
    try {
      _userFeatures = await SubscriptionService.getUserFeatures();
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Create subscription
  Future<bool> createSubscription({
    required String planType,
    required String paymentMethod,
    bool autoRenew = false,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Process payment first
      final plan = SubscriptionService.getPlanDetails(planType);
      if (plan == null) throw 'Invalid plan type';

      final paymentSuccess = await SubscriptionService.processPayment(
        amount: plan['price'],
        currency: plan['currency'],
        paymentMethod: paymentMethod,
      );

      if (!paymentSuccess) throw 'Payment failed';

      // Create subscription
      _currentSubscription = await SubscriptionService.createSubscription(
        planType: planType,
        paymentMethod: paymentMethod,
        autoRenew: autoRenew,
      );

      // Update subscription status to active
      await SubscriptionService.updateSubscriptionStatus(
        _currentSubscription!.id,
        'active',
      );

      _hasActiveSubscription = true;
      _hasPremiumFeatures = _currentSubscription!.isPremium;
      await _loadUserFeatures();
              NotificationService.showSuccessNotification(
          title: 'Subscription Created',
          message: 'Your subscription has been created successfully!',
        );
        return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upgrade subscription
  Future<bool> upgradeSubscription({
    required String newPlanType,
    required String paymentMethod,
    bool autoRenew = false,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentSubscription = await SubscriptionService.upgradeSubscription(
        newPlanType: newPlanType,
        paymentMethod: paymentMethod,
        autoRenew: autoRenew,
      );

      _hasActiveSubscription = true;
      _hasPremiumFeatures = _currentSubscription!.isPremium;
      await _loadUserFeatures();
              NotificationService.showSuccessNotification(
          title: 'Subscription Upgraded',
          message: 'Your subscription has been upgraded successfully!',
        );
        return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    if (_currentSubscription == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      await SubscriptionService.cancelSubscription(_currentSubscription!.id);
      _hasActiveSubscription = false;
      _hasPremiumFeatures = false;
      await _loadUserFeatures();
              NotificationService.showSuccessNotification(
          title: 'Subscription Cancelled',
          message: 'Your subscription has been cancelled successfully!',
        );
        return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Renew subscription
  Future<bool> renewSubscription() async {
    if (_currentSubscription == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      await SubscriptionService.renewSubscription(_currentSubscription!.id);
      await _loadCurrentSubscription();
              NotificationService.showSuccessNotification(
          title: 'Subscription Renewed',
          message: 'Your subscription has been renewed successfully!',
        );
        return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get plan details
  Map<String, dynamic>? getPlanDetails(String planType) {
    return SubscriptionService.getPlanDetails(planType);
  }

  // Get all plans
  Map<String, Map<String, dynamic>> getAllPlans() {
    return SubscriptionService.getAllPlans();
  }

  // Check if user has specific feature
  bool hasFeature(String feature) {
    return _userFeatures.contains(feature);
  }

  // Get subscription analytics (for admin)
  Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    try {
      return await SubscriptionService.getSubscriptionAnalytics();
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }

  // Refresh subscription data
  Future<void> refreshSubscription() async {
    await _loadCurrentSubscription();
    await _loadUserFeatures();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Set error
  void _setError(String error) {
    _error = error;
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Clear error
  void _clearError() {
    _error = null;
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
} 