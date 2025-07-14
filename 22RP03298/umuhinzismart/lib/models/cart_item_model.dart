import 'product_model.dart';

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final String imageUrl;
  final String dealer;
  final int quantity;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.dealer,
    required this.quantity,
    required this.addedAt,
  });

  factory CartItem.fromMap(Map<String, dynamic> data, String documentId) {
    // Safe parsing functions
    double safeDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int safeInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 1;
      if (value is double) return value.toInt();
      return 1;
    }

    DateTime safeDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return CartItem(
      id: documentId,
      productId: data['productId']?.toString().trim() ?? '',
      productName: data['productName']?.toString().trim() ?? 'Unknown Product',
      price: safeDouble(data['price']),
      imageUrl: data['imageUrl']?.toString().trim() ?? '',
      dealer: data['dealer']?.toString().trim() ?? 'Unknown Dealer',
      quantity: safeInt(data['quantity']),
      addedAt: safeDateTime(data['addedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'imageUrl': imageUrl,
      'dealer': dealer,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Computed properties
  double get totalPrice => price * quantity;

  // Validation methods
  bool get isValid => 
    productId.isNotEmpty && 
    productName.isNotEmpty && 
    price > 0 && 
    quantity > 0;

  // Copy with methods for updates
  CartItem copyWith({
    String? productId,
    String? productName,
    double? price,
    String? imageUrl,
    String? dealer,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      dealer: dealer ?? this.dealer,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $id, productName: $productName, quantity: $quantity, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 