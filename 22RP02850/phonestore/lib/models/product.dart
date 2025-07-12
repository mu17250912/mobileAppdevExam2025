import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String sellerId;
  final bool inStock;
  final String description;
  final int? stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.sellerId,
    this.inStock = true,
    required this.description,
    this.stock,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'inStock': inStock,
      'description': description,
      'stock': stock ?? 0,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      sellerId: map['sellerId'] ?? '',
      inStock: map['inStock'] ?? true,
      description: map['description'] ?? '',
      stock: map['stock'],
    );
  }

  factory Product.fromDocument(DocumentSnapshot doc) {
    return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
