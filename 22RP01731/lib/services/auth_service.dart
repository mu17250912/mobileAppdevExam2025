import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Stream the current user's Firestore profile document in real time
  Stream<DocumentSnapshot<Map<String, dynamic>>>? get currentUserProfileStream {
    final user = _auth.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }

  // Admin email addresses
  static const List<String> _adminEmails = [
    'admin@groceryapp.com',
    'admin@test.com',
  ];

  bool get isAdmin {
    final user = _auth.currentUser;
    return user != null && _adminEmails.contains(user.email);
  }

  Future<void> signUpWithEmail(String email, String password, {required String firstName, required String lastName}) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
    
    // Create user profile in Firestore
    if (_auth.currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'isAdmin': _adminEmails.contains(email),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    
    // Update user profile in Firestore if it doesn't exist
    if (_auth.currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .set({
          'email': email,
          'isAdmin': _adminEmails.contains(email),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  /// Update the user's delivery info in Firestore
  Future<void> updateUserDeliveryInfo({
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'address': address,
    }, SetOptions(merge: true));
    notifyListeners();
  }

  /// Add a product to user's favorites
  Future<void> addFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(productId)
        .set({'addedAt': FieldValue.serverTimestamp()});
    notifyListeners();
  }

  /// Remove a product from user's favorites
  Future<void> removeFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(productId)
        .delete();
    notifyListeners();
  }

  /// Check if a product is in user's favorites
  Stream<bool> isFavorite(String productId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(productId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Stream all favorite product IDs for the user
  Stream<List<String>> get favoriteProductIds {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // TODO: Add phone authentication methods
} 