import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isPremium => _userProfile?.isPremium ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    FirebaseService.authStateChanges.listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      // Only notify listeners if we're already initialized
      if (_isInitialized) {
        notifyListeners();
      } else {
        _isInitialized = true;
        // Delay the first notification to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      _isLoading = true;
      if (_isInitialized) {
        notifyListeners();
      }

      _userProfile = await FirebaseService.getUserProfile(uid);
      
      if (_userProfile != null) {
        await FirebaseService.setUserProperties(
          userId: uid,
          isPremium: _userProfile!.isPremium,
        );
      }
    } catch (e) {
      _error = 'Failed to load user profile: $e';
    } finally {
      _isLoading = false;
      if (_isInitialized) {
        notifyListeners();
      }
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseService.signUp(
        email: email,
        password: password,
        name: name,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseService.signIn(
        email: email,
        password: password,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseService.signOut();
      _currentUser = null;
      _userProfile = null;
    } catch (e) {
      _error = 'Failed to sign out: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> upgradeToPremium() async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseService.updateUserPremiumStatus(_currentUser!.uid, true);
      
      // Update local profile
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(isPremium: true);
      }

      return true;
    } catch (e) {
      _error = 'Failed to upgrade to premium: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 