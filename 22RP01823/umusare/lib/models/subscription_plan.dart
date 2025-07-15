class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String billingPeriod; // monthly, yearly
  final List<String> features;
  final bool isPopular;
  final String? productId; // For in-app purchase

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.billingPeriod,
    required this.features,
    this.isPopular = false,
    this.productId,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      billingPeriod: json['billingPeriod'] ?? 'monthly',
      features: List<String>.from(json['features'] ?? []),
      isPopular: json['isPopular'] ?? false,
      productId: json['productId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'billingPeriod': billingPeriod,
      'features': features,
      'isPopular': isPopular,
      'productId': productId,
    };
  }
}

class InAppProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String type; // consumable, non_consumable, subscription
  final String? imageUrl;

  const InAppProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.type,
    this.imageUrl,
  });

  factory InAppProduct.fromJson(Map<String, dynamic> json) {
    return InAppProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      type: json['type'] ?? 'consumable',
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'type': type,
      'imageUrl': imageUrl,
    };
  }
}

class UserSubscription {
  final String userId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String status; // active, cancelled, expired
  final String? transactionId;

  const UserSubscription({
    required this.userId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.status,
    this.transactionId,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      userId: json['userId'] ?? '',
      planId: json['planId'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'] ?? false,
      status: json['status'] ?? 'inactive',
      transactionId: json['transactionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'planId': planId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'status': status,
      'transactionId': transactionId,
    };
  }
} 