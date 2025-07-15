import 'package:flutter/material.dart';

enum SubscriptionType {
  free,
  monthly,
  annual,
}

enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  pending,
  trial,
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final SubscriptionType type;
  final int durationInDays;
  final List<String> features;
  final bool isPopular;
  final double? originalPrice; // For discounted plans
  final String? discountText;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.durationInDays,
    required this.features,
    this.isPopular = false,
    this.originalPrice,
    this.discountText,
  });

  // Predefined subscription plans
  static const List<SubscriptionPlan> availablePlans = [
    SubscriptionPlan(
      id: 'free',
      name: 'Free',
      description: 'Basic features for everyone',
      price: 0.0,
      type: SubscriptionType.free,
      durationInDays: 0,
      features: [
        'Up to 10 tasks',
        'Basic notes',
        'Standard support',
      ],
    ),
    SubscriptionPlan(
      id: 'monthly',
      name: 'Monthly Pro',
      description: 'Unlimited features for productivity',
      price: 9.99,
      type: SubscriptionType.monthly,
      durationInDays: 30,
      features: [
        'Unlimited tasks',
        'Advanced notes',
        'Priority support',
        'Custom categories',
        'Data export',
        'Cloud sync',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      id: 'annual',
      name: 'Annual Pro',
      description: 'Best value for long-term users',
      price: 99.99,
      type: SubscriptionType.annual,
      durationInDays: 365,
      features: [
        'All Monthly features',
        'Early access to new features',
        'Premium themes',
        'Advanced analytics',
        'Team collaboration',
        'API access',
      ],
      originalPrice: 119.88, // 12 * 9.99
      discountText: 'Save 17%',
      isPopular: true,
    ),
  ];

  // Get plan by ID
  static SubscriptionPlan? getPlanById(String id) {
    try {
      return availablePlans.firstWhere((plan) => plan.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get monthly equivalent price for annual plan
  double get monthlyEquivalentPrice {
    if (type == SubscriptionType.annual) {
      return price / 12;
    }
    return price;
  }

  // Calculate savings percentage
  double? get savingsPercentage {
    if (originalPrice != null && originalPrice! > price) {
      return ((originalPrice! - price) / originalPrice!) * 100;
    }
    return null;
  }
}

class Subscription {
  final String? docId; // Firestore document ID
  final String userId;
  final String planId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? cancelledAt;
  final String? transactionId;
  final String? paymentMethod;
  final bool autoRenew;
  final DateTime? nextBillingDate;
  final double? amountPaid;
  final String? currency;
  final Map<String, dynamic>? metadata;

  const Subscription({
    this.docId,
    required this.userId,
    required this.planId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.cancelledAt,
    this.transactionId,
    this.paymentMethod,
    this.autoRenew = true,
    this.nextBillingDate,
    this.amountPaid,
    this.currency = 'USD',
    this.metadata,
  });

  // Check if subscription is active
  bool get isActive {
    return status == SubscriptionStatus.active && 
           DateTime.now().isBefore(endDate);
  }

  // Check if subscription is expired
  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  // Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  // Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = DateTime.now().difference(startDate).inDays;
    return (elapsedDays / totalDays).clamp(0.0, 1.0);
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planId': planId,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'autoRenew': autoRenew,
      'nextBillingDate': nextBillingDate?.toIso8601String(),
      'amountPaid': amountPaid,
      'currency': currency,
      'metadata': metadata,
    };
  }

  // Create from Map (from Firestore)
  factory Subscription.fromMap(Map<String, dynamic> map) {
    final planId = map['planId'] ?? '';
    final plan = SubscriptionPlan.getPlanById(planId) ?? 
                 SubscriptionPlan.availablePlans.first; // Default to free plan

    return Subscription(
      docId: map['docId'],
      userId: map['userId'] ?? '',
      planId: planId,
      plan: plan,
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SubscriptionStatus.pending,
      ),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      cancelledAt: map['cancelledAt'] != null ? DateTime.parse(map['cancelledAt']) : null,
      transactionId: map['transactionId'],
      paymentMethod: map['paymentMethod'],
      autoRenew: map['autoRenew'] ?? true,
      nextBillingDate: map['nextBillingDate'] != null ? DateTime.parse(map['nextBillingDate']) : null,
      amountPaid: map['amountPaid']?.toDouble(),
      currency: map['currency'] ?? 'USD',
      metadata: map['metadata'],
    );
  }

  // Create a copy with updated fields
  Subscription copyWith({
    String? docId,
    String? userId,
    String? planId,
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? cancelledAt,
    String? transactionId,
    String? paymentMethod,
    bool? autoRenew,
    DateTime? nextBillingDate,
    double? amountPaid,
    String? currency,
    Map<String, dynamic>? metadata,
  }) {
    return Subscription(
      docId: docId ?? this.docId,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      autoRenew: autoRenew ?? this.autoRenew,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      amountPaid: amountPaid ?? this.amountPaid,
      currency: currency ?? this.currency,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Subscription billing information
class BillingInfo {
  final String id;
  final String userId;
  final String subscriptionId;
  final double amount;
  final String currency;
  final DateTime billingDate;
  final String status; // 'paid', 'pending', 'failed'
  final String? transactionId;
  final String? invoiceUrl;
  final Map<String, dynamic>? metadata;

  const BillingInfo({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.amount,
    required this.currency,
    required this.billingDate,
    required this.status,
    this.transactionId,
    this.invoiceUrl,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'currency': currency,
      'billingDate': billingDate.toIso8601String(),
      'status': status,
      'transactionId': transactionId,
      'invoiceUrl': invoiceUrl,
      'metadata': metadata,
    };
  }

  factory BillingInfo.fromMap(Map<String, dynamic> map) {
    return BillingInfo(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      subscriptionId: map['subscriptionId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      billingDate: DateTime.parse(map['billingDate']),
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'],
      invoiceUrl: map['invoiceUrl'],
      metadata: map['metadata'],
    );
  }
} 