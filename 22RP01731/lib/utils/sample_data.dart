import 'package:cloud_firestore/cloud_firestore.dart';

class SampleData {
  static final List<Map<String, dynamic>> sampleProducts = [
    {
      'name': 'Fresh Tomatoes',
      'description': 'Organic red tomatoes, perfect for salads and cooking. Grown locally without pesticides.',
      'price': 2.99,
      'imageUrl': 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=400',
      'category': 'Vegetables',
      'unit': 'kg',
      'stockQuantity': 50,
      'isAvailable': true,
    },
    {
      'name': 'Organic Bananas',
      'description': 'Sweet and ripe organic bananas. Rich in potassium and perfect for smoothies.',
      'price': 1.99,
      'imageUrl': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400',
      'category': 'Fruits',
      'unit': 'bundle',
      'stockQuantity': 30,
      'isAvailable': true,
    },
    {
      'name': 'Fresh Milk',
      'description': 'Farm-fresh whole milk. Pasteurized and delivered daily.',
      'price': 3.49,
      'imageUrl': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400',
      'category': 'Dairy',
      'unit': 'liter',
      'stockQuantity': 25,
      'isAvailable': true,
    },
    {
      'name': 'Whole Grain Bread',
      'description': 'Freshly baked whole grain bread. No preservatives, made with natural ingredients.',
      'price': 2.49,
      'imageUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
      'category': 'Bakery',
      'unit': 'piece',
      'stockQuantity': 20,
      'isAvailable': true,
    },
    {
      'name': 'Free Range Eggs',
      'description': 'Farm fresh eggs from free-range chickens. Rich in protein and nutrients.',
      'price': 4.99,
      'imageUrl': 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400',
      'category': 'Dairy',
      'unit': 'dozen',
      'stockQuantity': 15,
      'isAvailable': true,
    },
    {
      'name': 'Organic Spinach',
      'description': 'Fresh organic spinach leaves. Perfect for salads and cooking.',
      'price': 3.99,
      'imageUrl': 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400',
      'category': 'Vegetables',
      'unit': 'bundle',
      'stockQuantity': 40,
      'isAvailable': true,
    },
    {
      'name': 'Apples (Red Delicious)',
      'description': 'Sweet and crisp red delicious apples. Perfect for snacking or baking.',
      'price': 2.49,
      'imageUrl': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400',
      'category': 'Fruits',
      'unit': 'kg',
      'stockQuantity': 35,
      'isAvailable': true,
    },
    {
      'name': 'Chicken Breast',
      'description': 'Fresh boneless chicken breast. Hormone-free and locally sourced.',
      'price': 8.99,
      'imageUrl': 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=400',
      'category': 'Meat',
      'unit': 'kg',
      'stockQuantity': 20,
      'isAvailable': true,
    },
    {
      'name': 'Brown Rice',
      'description': 'Organic brown rice. Rich in fiber and nutrients.',
      'price': 4.49,
      'imageUrl': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400',
      'category': 'Grains',
      'unit': 'kg',
      'stockQuantity': 30,
      'isAvailable': true,
    },
    {
      'name': 'Extra Virgin Olive Oil',
      'description': 'Premium extra virgin olive oil. Cold-pressed and imported from Italy.',
      'price': 12.99,
      'imageUrl': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400',
      'category': 'Pantry',
      'unit': 'bottle',
      'stockQuantity': 25,
      'isAvailable': true,
    },
  ];

  static Future<void> addSampleProducts() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final product in sampleProducts) {
        final docRef = FirebaseFirestore.instance.collection('products').doc();
        batch.set(docRef, {
          ...product,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      // Handle error silently
    }
  }
} 