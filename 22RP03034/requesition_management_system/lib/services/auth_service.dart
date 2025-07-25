// 🔄 FILE 1: auth_service.dart (Firebase Auth + Firestore logic)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    String? postName,
    String? phone,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userData = {
        'id': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'role': role,
        'postName': postName,
        'profileImagePath': null,
        'registrationDate': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

      return userCredential;
    } catch (e) {
      debugPrint('❌ Registration failed: ${e.toString()}');
      rethrow;
    }
  }

  // Sign in
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        return AppUser(
          id: uid,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'],
          password: '',
          role: data['role'] ?? '',
          postName: data['postName'],
          profileImagePath: data['profileImagePath'],
          registrationDate: (data['registrationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ Sign in failed: ${e.toString()}');
      return null;
    }
  }

  Future<void> signOut() async => await _auth.signOut();
}

