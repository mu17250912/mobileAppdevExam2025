import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';

class SubscriptionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Subscription? _currentSubscription;
  List<SubscriptionPlan> _availablePlans = SubscriptionPlan.availablePlans;
  List<BillingInfo> _billingHistory = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Subscription? get currentSubscription => _currentSubscription;
  List<SubscriptionPlan> get availablePlans => _availablePlans;
  List<BillingInfo> get billingHistory => _billingHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSubscription => _currentSubscription?.isActive ?? false;
  bool get isPremium => hasActiveSubscription;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load user's subscription
  Future<void> loadUserSubscription(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final doc = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: SubscriptionStatus.active.name)
          .orderBy('endDate', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        final data = doc.docs.first.data();
        data['docId'] = doc.docs.first.id;
        _currentSubscription = Subscription.fromMap(data);
      } else {
        _currentSubscription = null;
      }

      // Load billing history
      await _loadBillingHistory(userId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load subscription: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load billing history
  Future<void> _loadBillingHistory(String userId) async {
    try {
      final docs = await _firestore
          .collection('billing')
          .where('userId', isEqualTo: userId)
          .orderBy('billingDate', descending: true)
          .limit(20)
          .get();

      _billingHistory = docs.docs.map((doc) {
        final data = doc.data();
        return BillingInfo.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error loading billing history: $e');
      _billingHistory = [];
    }
  }

  // Create new subscription
  Future<void> createSubscription({
    required String userId,
    required String planId,
    String? transactionId,
    String? paymentMethod,
    double? amountPaid,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final plan = SubscriptionPlan.getPlanById(planId);
      if (plan == null) {
        throw Exception('Invalid plan ID');
      }

      final now = DateTime.now();
      final endDate = plan.type == SubscriptionType.free 
          ? now 
          : now.add(Duration(days: plan.durationInDays));

      final subscription = Subscription(
        userId: userId,
        planId: planId,
        plan: plan,
        status: SubscriptionStatus.active,
        startDate: now,
        endDate: endDate,
        transactionId: transactionId,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        autoRenew: plan.type != SubscriptionType.free,
        nextBillingDate: plan.type != SubscriptionType.free ? endDate : null,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('subscriptions')
          .add(subscription.toMap());

      _currentSubscription = subscription.copyWith(docId: docRef.id);
      
      // Update user profile
      await _updateUserSubscriptionStatus(userId, planId, endDate);

      // Track subscription analytics
      _trackSubscriptionStarted(planId, amountPaid ?? 0.0, 'USD', paymentMethod);

      notifyListeners();
    } catch (e) {
      _setError('Failed to create subscription: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription(String userId) async {
    if (_currentSubscription == null) return;

    _setLoading(true);
    _clearError();

    try {
      final updatedSubscription = _currentSubscription!.copyWith(
        status: SubscriptionStatus.cancelled,
        cancelledAt: DateTime.now(),
        autoRenew: false,
      );

      await _firestore
          .collection('subscriptions')
          .doc(_currentSubscription!.docId)
          .update(updatedSubscription.toMap());

      _currentSubscription = updatedSubscription;
      
      // Update user profile
      await _updateUserSubscriptionStatus(userId, 'free', DateTime.now());

      // Track subscription cancellation analytics
      _trackSubscriptionCancelled(_currentSubscription!.planId, 'user_requested');

      notifyListeners();
    } catch (e) {
      _setError('Failed to cancel subscription: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Renew subscription
  Future<void> renewSubscription({
    required String userId,
    String? transactionId,
    String? paymentMethod,
    double? amountPaid,
  }) async {
    if (_currentSubscription == null) return;

    _setLoading(true);
    _clearError();

    try {
      final plan = _currentSubscription!.plan;
      final now = DateTime.now();
      final newEndDate = now.add(Duration(days: plan.durationInDays));

      final updatedSubscription = _currentSubscription!.copyWith(
        status: SubscriptionStatus.active,
        startDate: now,
        endDate: newEndDate,
        cancelledAt: null,
        transactionId: transactionId,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        autoRenew: true,
        nextBillingDate: newEndDate,
      );

      await _firestore
          .collection('subscriptions')
          .doc(_currentSubscription!.docId)
          .update(updatedSubscription.toMap());

      _currentSubscription = updatedSubscription;
      
      // Update user profile
      await _updateUserSubscriptionStatus(userId, plan.id, newEndDate);

      // Track subscription renewal analytics
      _trackSubscriptionRenewed(plan.id, amountPaid ?? 0.0, 'USD');

      notifyListeners();
    } catch (e) {
      _setError('Failed to renew subscription: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile subscription status
  Future<void> _updateUserSubscriptionStatus(
    String userId, 
    String planId, 
    DateTime? expiryDate
  ) async {
    try {
      final plan = SubscriptionPlan.getPlanById(planId);
      final isPremium = plan?.type != SubscriptionType.free;

      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'isPremium': isPremium,
        'subscriptionPlan': planId,
        'subscriptionExpiry': expiryDate?.toIso8601String(),
      });
    } catch (e) {
      print('Error updating user subscription status: $e');
    }
  }

  // Add billing record
  Future<void> addBillingRecord(BillingInfo billingInfo) async {
    try {
      await _firestore
          .collection('billing')
          .add(billingInfo.toMap());

      _billingHistory.insert(0, billingInfo);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add billing record: ${e.toString()}');
    }
  }

  // Check if user can access premium features
  bool canAccessPremiumFeature() {
    return hasActiveSubscription;
  }

  // Get subscription status text
  String getSubscriptionStatusText() {
    if (_currentSubscription == null) {
      return 'No active subscription';
    }

    if (_currentSubscription!.isExpired) {
      return 'Subscription expired';
    }

    if (_currentSubscription!.status == SubscriptionStatus.cancelled) {
      return 'Subscription cancelled';
    }

    final daysRemaining = _currentSubscription!.daysRemaining;
    if (daysRemaining <= 0) {
      return 'Subscription expired';
    } else if (daysRemaining <= 7) {
      return 'Expires in $daysRemaining days';
    } else {
      return 'Active - ${daysRemaining} days remaining';
    }
  }

  // Get subscription progress (0.0 to 1.0)
  double getSubscriptionProgress() {
    return _currentSubscription?.progressPercentage ?? 0.0;
  }

  // Check if subscription is expiring soon (within 7 days)
  bool get isExpiringSoon {
    if (_currentSubscription == null) return false;
    return _currentSubscription!.daysRemaining <= 7 && _currentSubscription!.daysRemaining > 0;
  }

  // Get recommended plan based on usage
  SubscriptionPlan getRecommendedPlan() {
    // Simple logic - can be enhanced based on actual usage data
    return SubscriptionPlan.availablePlans.firstWhere(
      (plan) => plan.id == 'monthly',
      orElse: () => SubscriptionPlan.availablePlans.first,
    );
  }

  // Clear subscription data (for logout)
  void clearSubscriptionData() {
    _currentSubscription = null;
    _billingHistory = [];
    _error = null;
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Analytics tracking methods
  void _trackSubscriptionStarted(String planId, double amount, String currency, String? paymentMethod) {
    try {
      // Note: Analytics tracking will be handled by the UI layer
      // where we have access to BuildContext
      print('Subscription started tracked: $planId, $amount $currency');
    } catch (e) {
      print('Error tracking subscription started: $e');
    }
  }

  void _trackSubscriptionRenewed(String planId, double amount, String currency) {
    try {
      // Note: Analytics tracking will be handled by the UI layer
      // where we have access to BuildContext
      print('Subscription renewed tracked: $planId, $amount $currency');
    } catch (e) {
      print('Error tracking subscription renewed: $e');
    }
  }

  void _trackSubscriptionCancelled(String planId, String? reason) {
    try {
      // Note: Analytics tracking will be handled by the UI layer
      // where we have access to BuildContext
      print('Subscription cancelled tracked: $planId, reason: $reason');
    } catch (e) {
      print('Error tracking subscription cancelled: $e');
    }
  }
} 