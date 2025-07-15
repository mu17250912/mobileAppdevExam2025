import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/task_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  AuthProvider() {
    _init();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  void _init() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithEmailAndPassword(email, password);
      _setLoading(false);
      return result != null;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> createUserWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.createUserWithEmailAndPassword(email, password);
      _setLoading(false);
      return result != null;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithGoogle();
      _setLoading(false);
      return result != null;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      // Clear task cache on logout
      TaskStorage.clearCache();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    _setLoading(true);
    try {
      await _authService.updateUserProfile(displayName: displayName, photoURL: photoURL);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 