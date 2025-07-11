import 'fruit.dart';

class CartItem {
  final String id;
  final Fruit fruit;
  int quantity;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.fruit,
    this.quantity = 1,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  double get totalPrice {
    // Extract numeric value from price string (e.g., "500rwf" -> 500)
    final priceString = fruit.price.replaceAll(RegExp(r'[^0-9.]'), '');
    final price = double.tryParse(priceString) ?? 0.0;
    return price * quantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fruit': fruit.toJson(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      fruit: Fruit.fromJson(json['fruit']),
      quantity: json['quantity'],
      addedAt: DateTime.parse(json['addedAt']),
    );
  }

  CartItem copyWith({
    String? id,
    Fruit? fruit,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      fruit: fruit ?? this.fruit,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

