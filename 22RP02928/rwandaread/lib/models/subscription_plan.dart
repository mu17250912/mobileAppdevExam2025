class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String billingPeriod; // monthly, yearly
  final List<String> features;
  final bool isPopular;
  final String? discountText;
  final double? originalPrice;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.billingPeriod,
    required this.features,
    this.isPopular = false,
    this.discountText,
    this.originalPrice,
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
      discountText: json['discountText'],
      originalPrice: json['originalPrice']?.toDouble(),
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
      'discountText': discountText,
      'originalPrice': originalPrice,
    };
  }

  double get savingsPercentage {
    if (originalPrice != null && originalPrice! > price) {
      return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
    }
    return 0.0;
  }
} 