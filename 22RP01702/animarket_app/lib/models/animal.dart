import 'package:cloud_firestore/cloud_firestore.dart';

class Animal {
  final String id;
  final String userId;
  final String type;
  final String location;
  final String description;
  final double price;
  final String sellerName;
  final String sellerPhone;
  final DateTime createdAt;
  final int count; // <-- ADD THIS
  final bool isPremium; // <-- Add this

  Animal({
    required this.id,
    required this.userId,
    required this.type,
    required this.location,
    required this.description,
    required this.price,
    required this.sellerName,
    required this.sellerPhone,
    required this.createdAt,
    required this.count, // <-- ADD THIS
    required this.isPremium,
  });

  // If you have fromMap or similar, update it:
  factory Animal.fromMap(Map<String, dynamic> doc, String id) {
    return Animal(
      id: id,
      userId: doc['userId'],
      type: doc['type'],
      location: doc['location'],
      description: doc['description'],
      price: (doc['price'] as num).toDouble(),
      sellerName: doc['sellerName'],
      sellerPhone: doc['sellerPhone'],
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      count: doc['count'] ?? 1, // <-- default to 1 if missing
      isPremium: doc['isPremium'] ?? false,
    );
  }
}