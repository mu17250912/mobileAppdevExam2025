class SubscriptionModel {
  final String id;
  final String userId;
  final String planType; // basic, premium, business
  final String status; // active, expired, cancelled, pending
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String currency;
  final String paymentMethod;
  final bool autoRenew;
  final Map<String, dynamic> features;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planType,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.autoRenew = false,
    required this.features,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      planType: json['planType'] ?? 'basic',
      status: json['status'] ?? 'pending',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'RWF',
      paymentMethod: json['paymentMethod'] ?? '',
      autoRenew: json['autoRenew'] ?? false,
      features: json['features'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planType': planType,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'autoRenew': autoRenew,
      'features': features,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? planType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
    String? currency,
    String? paymentMethod,
    bool? autoRenew,
    Map<String, dynamic>? features,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planType: planType ?? this.planType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      autoRenew: autoRenew ?? this.autoRenew,
      features: features ?? this.features,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == 'active' && DateTime.now().isBefore(endDate);
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isBasic => planType == 'basic';
  bool get isPremium => planType == 'premium';
  bool get isBusiness => planType == 'business';
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
} 