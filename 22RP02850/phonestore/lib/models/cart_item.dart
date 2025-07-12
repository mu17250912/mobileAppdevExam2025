class CartItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final String sellerId;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.sellerId,
    required this.addedAt,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'sellerId': sellerId,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromMap(String id, Map<String, dynamic> map) {
    return CartItem(
      id: id,
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 1,
      sellerId: map['sellerId'] ?? '',
      addedAt: map['addedAt'] != null 
          ? DateTime.parse(map['addedAt']) 
          : DateTime.now(),
    );
  }

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
    String? sellerId,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      sellerId: sellerId ?? this.sellerId,
      addedAt: addedAt ?? this.addedAt,
    );
  }
} 