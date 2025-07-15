import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal.dart';

class AnimalProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Animal> _animals = [];

  List<Animal> get animals => _animals;

  Stream<List<Animal>> getAllAnimalsStream() {
    return _firestore.collection('animals').orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Animal(
        id: doc.id,
        userId: doc['userId'],
        type: doc['type'],
        location: doc['location'],
        description: doc['description'],
        price: (doc['price'] as num).toDouble(),
        sellerName: doc['sellerName'],
        sellerPhone: doc['sellerPhone'],
        createdAt: (doc['createdAt'] as Timestamp).toDate(),
        count: doc['count'] ?? 1,
        isPremium: doc['isPremium'] ?? false,
      )).toList(),
    );
  }

  Stream<List<Animal>> getSellerAnimalsStream(String userId) {
    return _firestore.collection('animals').where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Animal(
        id: doc.id,
        userId: doc['userId'],
        type: doc['type'],
        location: doc['location'],
        description: doc['description'],
        price: (doc['price'] as num).toDouble(),
        sellerName: doc['sellerName'],
        sellerPhone: doc['sellerPhone'],
        createdAt: (doc['createdAt'] as Timestamp).toDate(),
        count: doc['count'] ?? 1,
        isPremium: doc['isPremium'] ?? false,
      )).toList(),
    );
  }

  Future<String> addAnimal(Animal animal) async {
    final docRef = await _firestore.collection('animals').add({
      'userId': animal.userId,
      'type': animal.type,
      'location': animal.location,
      'description': animal.description,
      'price': animal.price,
      'sellerName': animal.sellerName,
      'sellerPhone': animal.sellerPhone,
      'createdAt': animal.createdAt,
      'count': animal.count,
      'isPremium': animal.isPremium,
    });
    notifyListeners();
    return docRef.id;
  }

  Future<void> removeAnimal(String id) async {
    await _firestore.collection('animals').doc(id).delete();
    notifyListeners();
  }

  Future<void> updateAnimalPrice(String id, double newPrice) async {
    await _firestore.collection('animals').doc(id).update({'price': newPrice});
    notifyListeners();
  }

  Future<Animal?> getAnimalById(String id) async {
    final doc = await _firestore.collection('animals').doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      return Animal(
        id: doc.id,
        userId: data['userId'],
        type: data['type'],
        location: data['location'],
        description: data['description'],
        price: (data['price'] as num).toDouble(),
        sellerName: data['sellerName'],
        sellerPhone: data['sellerPhone'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        count: data['count'] ?? 1,
        isPremium: data['isPremium'] ?? false,
      );
    }
    return null;
  }

  Future<int> getSellerAnimalsCount(String userId) async {
    final snapshot = await _firestore.collection('animals').where('userId', isEqualTo: userId).get();
    return snapshot.docs.length;
  }
}
