class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final double quantity;
  final String unit;
  final String farmerId;
  final String farmerName;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.farmerId,
    required this.farmerName,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'farmerId': farmerId,
      'farmerName': farmerName,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
    );
  }
} 