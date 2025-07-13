class UserSubscription {
  final String userId;
  final String planId;
  final String planName;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String status; // active, expired, cancelled, pending
  final String? transactionId;
  final double amount;
  final String currency;
  final String billingPeriod;

  const UserSubscription({
    required this.userId,
    required this.planId,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.status,
    this.transactionId,
    required this.amount,
    required this.currency,
    required this.billingPeriod,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      userId: json['userId'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? false,
      status: json['status'] ?? 'inactive',
      transactionId: json['transactionId'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      billingPeriod: json['billingPeriod'] ?? 'monthly',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'planId': planId,
      'planName': planName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'status': status,
      'transactionId': transactionId,
      'amount': amount,
      'currency': currency,
      'billingPeriod': billingPeriod,
    };
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isExpiringSoon {
    final daysUntilExpiry = endDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }

  int get daysRemaining {
    final difference = endDate.difference(DateTime.now());
    return difference.isNegative ? 0 : difference.inDays;
  }
} 