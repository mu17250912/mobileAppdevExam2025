import 'package:flutter/material.dart';

class Fruit {
  final String id;
  final String name;
  final String price;
  final String seller;
  final String description;
  final String imagePath; // New field for image path
  final IconData icon;
  final Color color;
  final String category;
  final bool isAvailable;
  final double rating;

  Fruit({
    required this.id,
    required this.name,
    required this.price,
    required this.seller,
    required this.description,
    required this.imagePath, // Required for image path
    this.icon = Icons.circle, // Default icon
    required this.color,
    this.category = 'Fresh Fruits',
    this.isAvailable = true,
    this.rating = 4.5,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'seller': seller,
      'description': description,
      'category': category,
      'isAvailable': isAvailable,
      'rating': rating,
    };
  }

  factory Fruit.fromJson(Map<String, dynamic> json) {
    return Fruit(
      id: json["id"],
      name: json["name"],
      price: json["price"],
      seller: json["seller"],
      description: json["description"],
      imagePath: json["imagePath"], // Add imagePath here
      icon: Icons.circle, // Default icon
      color: Colors.green, // Default color
      category: json["category"] ?? "Fresh Fruits",
      isAvailable: json["isAvailable"] ?? true,
      rating: json["rating"]?.toDouble() ?? 4.5,
    );
  }
}

