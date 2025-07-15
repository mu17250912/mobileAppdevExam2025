import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product(
        id: map['productId'] ?? '',
        name: map['name'] ?? '',
        price: (map['price'] ?? 0.0).toDouble(),
        description: map['description'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        category: map['category'] ?? '',
        unit: map['unit'] ?? '',
        stockQuantity: (map['stockQuantity'] ?? 0.0).toDouble(),
        isAvailable: true,
      ),
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'name': product.name,
      'price': product.price,
      'description': product.description,
      'imageUrl': product.imageUrl,
      'category': product.category,
      'unit': product.unit,
      'stockQuantity': product.stockQuantity,
      'quantity': quantity,
    };
  }
} 