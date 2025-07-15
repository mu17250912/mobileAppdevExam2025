import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;
  String? _username;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get username => _username;

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (_user != null) {
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        _username = doc.data()?['name'] ?? _user!.email;
      } else {
        _username = null;
      }
      notifyListeners();
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        _username = doc.data()?['name'] ?? _user!.email;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveConversion({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    required double convertedAmount,
    required double rate,
  }) async {
    if (_user == null) return;

    try {
      // Fetch username if not already loaded
      String? username = _username;
      if (username == null) {
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        username = doc.data()?['name'] ?? _user!.email;
        _username = username;
      }
      await _firestore.collection('conversions').add({
        'userId': _user!.uid,
        'username': username,
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'amount': amount,
        'convertedAmount': convertedAmount,
        'rate': rate,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving conversion: $e');
    }
  }

  Stream<QuerySnapshot> getConversionHistory() {
    if (_user == null) return Stream.empty();
    
    return _firestore
        .collection('conversions')
        .where('userId', isEqualTo: _user!.uid)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }
} 