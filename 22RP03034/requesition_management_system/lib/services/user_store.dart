import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStore {
  static AppUser? _currentUser;

  static Future<AppUser?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    
    // Get current user from Firebase Auth
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _currentUser = AppUser.fromJson(userData);
          return _currentUser;
        }
      } catch (e) {
        debugPrint('Error fetching current user: $e');
      }
    }
    return null;
  }

  static Future<void> updateUser(AppUser user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.id).update(user.toJson());
    _currentUser = user;
  }

  static Future<void> registerUser(AppUser user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.id).set(user.toJson());
    _currentUser = user;
  }

  static Future<void> logout() async {
    _currentUser = null;
  }
} 