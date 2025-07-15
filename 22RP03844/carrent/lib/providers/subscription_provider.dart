import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../user_store.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.features,
  });
}

class Subscription {
  final String id;
  final String userId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      planId: map['planId'] ?? '',
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['endDate']?.toString() ?? '') ?? DateTime.now(),
      isActive: map['isActive'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null),
    );
  }

  // Create a copy with updated fields
  Subscription copyWith({
    String? id,
    String? userId,
    String? planId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SubscriptionProvider with ChangeNotifier {
  Subscription? _currentSubscription;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Available subscription plans
  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      id: 'basic',
      name: 'Basic Plan',
      description: 'Perfect for occasional rentals',
      price: 9.99,
      durationDays: 30,
      features: [
        'Unlimited bookings up to 2 days',
        'Standard customer support',
        'Basic rental history',
      ],
    ),
    SubscriptionPlan(
      id: 'premium',
      name: 'Premium Plan',
      description: 'Best value for frequent renters',
      price: 19.99,
      durationDays: 30,
      features: [
        'Unlimited bookings of any duration',
        'Priority customer support',
        'Detailed rental history',
        'Exclusive vehicle access',
        '10% discount on all rentals',
      ],
    ),
    SubscriptionPlan(
      id: 'pro',
      name: 'Pro Plan',
      description: 'For business and heavy users',
      price: 39.99,
      durationDays: 30,
      features: [
        'All Premium features',
        'Business account management',
        'Bulk booking discounts',
        'Dedicated support line',
        '20% discount on all rentals',
      ],
    ),
  ];

  // Getters
  Subscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  List<SubscriptionPlan> get plans => _plans;
  
  bool get isSubscribed => _currentSubscription != null && _currentSubscription!.isActive;
  
  double get discountPercentage {
    if (!isSubscribed) return 0.0;
    
    switch (_currentSubscription!.planId) {
      case 'premium':
        return 10.0;
      case 'pro':
        return 20.0;
      default:
        return 0.0;
    }
  }

  // Methods
  Future<void> subscribeToPlan(String planId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get current user
      final currentUser = UserStore.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Check if plan exists
      final plan = _plans.firstWhere((plan) => plan.id == planId);
      final now = DateTime.now();
      final endDate = now.add(Duration(days: plan.durationDays));
      
      // Create subscription object
      final subscription = Subscription(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.id,
        planId: planId,
        startDate: now,
        endDate: endDate,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      
      // Save to Firestore
      await _firestore
          .collection('subscriptions')
          .doc(subscription.id)
          .set(subscription.toMap());
      
      // Update local state
      _currentSubscription = subscription;
      
      debugPrint('Subscription created successfully: ${subscription.id}');
      
    } catch (e) {
      debugPrint('Error subscribing to plan: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelSubscription() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentSubscription != null) {
        // Update subscription in Firestore
        final updatedSubscription = _currentSubscription!.copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
        
        await _firestore
            .collection('subscriptions')
            .doc(_currentSubscription!.id)
            .update(updatedSubscription.toMap());
        
        // Update local state
        _currentSubscription = updatedSubscription;
        
        debugPrint('Subscription cancelled successfully: ${_currentSubscription!.id}');
      }
      
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSubscription() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get current user
      final currentUser = UserStore.currentUser;
      if (currentUser == null) {
        _currentSubscription = null;
        return;
      }

      // Load subscription from Firestore
      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: currentUser.id)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final subscription = Subscription.fromMap(doc.data());
        
        // Check if subscription is still valid
        if (DateTime.now().isAfter(subscription.endDate)) {
          // Subscription has expired, update it
          final expiredSubscription = subscription.copyWith(
            isActive: false,
            updatedAt: DateTime.now(),
          );
          
          await _firestore
              .collection('subscriptions')
              .doc(subscription.id)
              .update(expiredSubscription.toMap());
          
          _currentSubscription = null;
        } else {
          _currentSubscription = subscription;
        }
      } else {
        _currentSubscription = null;
      }
      
      debugPrint('Subscription loaded successfully');
      
    } catch (e) {
      debugPrint('Error loading subscription: $e');
      _currentSubscription = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get subscription history for current user
  Future<List<Subscription>> getSubscriptionHistory() async {
    try {
      final currentUser = UserStore.currentUser;
      if (currentUser == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: currentUser.id)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Subscription.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading subscription history: $e');
      return [];
    }
  }

  // Get subscription stream for real-time updates
  Stream<Subscription?> getSubscriptionStream() {
    final currentUser = UserStore.currentUser;
    if (currentUser == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: currentUser.id)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final subscription = Subscription.fromMap(doc.data());
        
        // Check if subscription is still valid
        if (DateTime.now().isAfter(subscription.endDate)) {
          return null; // Subscription expired
        }
        return subscription;
      }
      return null;
    });
  }

  // Helper method to get plan by ID
  SubscriptionPlan? getPlanById(String planId) {
    try {
      return _plans.firstWhere((plan) => plan.id == planId);
    } catch (e) {
      return null;
    }
  }

  // Helper method to check if user can book for specified duration
  bool canBookForDuration(int days) {
    if (!isSubscribed) {
      return days <= 2; // Non-subscribed users can only book up to 2 days
    }
    return true; // Subscribed users can book for any duration
  }
} 