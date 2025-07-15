import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final double price;
  final int stockQuantity;
  final String category;
  final String? imageUrl;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stockQuantity,
    required this.category,
    this.imageUrl,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'],
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stockQuantity': stockQuantity,
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    int? stockQuantity,
    String? category,
    String? imageUrl,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isLowStock => stockQuantity <= 5;
} 