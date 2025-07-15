import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _auth.currentUser != null;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, doc.id);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _loadUserData(userCredential.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  Future<bool> createUser(String email, String password, String name, String role) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.id).set(user.toMap());
        _currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Create user error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isCashier => _currentUser?.role == 'cashier';

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_currentUser == null) return false;

      // Update email in Firebase Auth if it changed
      if (email != _currentUser!.email) {
        await _auth.currentUser?.updateEmail(email);
      }

      // Update user data in Firestore
      final updatedUser = _currentUser!.copyWith(
        name: name,
        email: email,
        phone: phone,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(_currentUser!.id).update(updatedUser.toMap());
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_auth.currentUser == null) return false;

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: _auth.currentUser!.email!,
        password: currentPassword,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);

      // Change password
      await _auth.currentUser!.updatePassword(newPassword);
      return true;
    } catch (e) {
      print('Change password error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 