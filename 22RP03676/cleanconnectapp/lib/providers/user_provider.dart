import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  bool _isPremium = false;
  String? _userId;

  bool get isPremium => _isPremium;

  UserProvider() {
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      refreshUserData();
    }
  }

  Future<void> refreshUserData() async {
    if (_userId == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .get();
    _isPremium = userDoc.data()?['isPremium'] ?? false;
    notifyListeners();
  }
} 