import 'package:flutter/material.dart';
import '../models/fruit.dart';

class FruitService {
  static final FruitService _instance = FruitService._internal();
  factory FruitService() => _instance;
  FruitService._internal();

  final List<Fruit> _fruits = [
    Fruit(
      id: '1',
      name: 'Fresh apples',
      price: '500rwf',
      seller: 'karibu fruits farm',
      description: 'Sweet and fresh apples that will get you healthy. Rich in vitamins and perfect for daily consumption.',
      imagePath: 'assets/images/apple.jpeg',
      color: Colors.red,
      category: 'Fresh Fruits',
      rating: 4.8,
    ),
    Fruit(
      id: '2',
      name: 'Oranges',
      price: '300rwf',
      seller: 'karibu fruits farm',
      description: 'Juicy and vitamin C rich oranges. Perfect for fresh juice or eating directly.',
      imagePath: 'assets/images/orange.jpg',
      color: Colors.orange,
      category: 'Citrus',
      rating: 4.6,
    ),
    Fruit(
      id: '3',
      name: 'Bananas',
      price: '200rwf',
      seller: 'karibu fruits farm',
      description: 'Energy-rich bananas perfect for breakfast or post-workout snacks.',
      imagePath: 'assets/images/banana.jpg',
      color: Colors.yellow,
      category: 'Tropical',
      rating: 4.7,
    ),
    Fruit(
      id: '4',
      name: 'Strawberries',
      price: '800rwf',
      seller: 'karibu fruits farm',
      description: 'Sweet and delicious strawberries. Perfect for desserts and smoothies.',
      imagePath: 'assets/images/strawberry.jpg',
      color: Colors.red.shade300,
      category: 'Berries',
      rating: 4.9,
    ),
    Fruit(
      id: '5',
      name: 'Mangoes',
      price: '600rwf',
      seller: 'karibu fruits farm',
      description: 'Tropical mangoes with sweet and juicy flesh. Rich in vitamins A and C.',
      imagePath: 'assets/images/mango.jpeg',
      color: Colors.orange.shade600,
      category: 'Tropical',
      rating: 4.8,
    ),
    Fruit(
      id: '6',
      name: 'Pineapples',
      price: '1000rwf',
      seller: 'karibu fruits farm',
      description: 'Fresh pineapples with tropical sweetness. Great for digestion and immunity.',
      imagePath: 'assets/images/pineapple.jpeg',
      color: Colors.yellow.shade700,
      category: 'Tropical',
      rating: 4.5,
    ),
  ];

  List<Fruit> get allFruits => List.unmodifiable(_fruits);

  List<Fruit> searchFruits(String query) {
    if (query.isEmpty) return allFruits;
    
    return _fruits.where((fruit) {
      return fruit.name.toLowerCase().contains(query.toLowerCase()) ||
             fruit.category.toLowerCase().contains(query.toLowerCase()) ||
             fruit.seller.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<Fruit> getFruitsByCategory(String category) {
    return _fruits.where((fruit) => fruit.category == category).toList();
  }

  Fruit? getFruitById(String id) {
    try {
      return _fruits.firstWhere((fruit) => fruit.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> get categories {
    return _fruits.map((fruit) => fruit.category).toSet().toList();
  }

  List<Fruit> getRecommendedFruits({int limit = 4}) {
    final sorted = List<Fruit>.from(_fruits);
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(limit).toList();
  }
}

