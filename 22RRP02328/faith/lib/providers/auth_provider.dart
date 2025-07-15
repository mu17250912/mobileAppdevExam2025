import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../providers/messaging_provider.dart'; // Added import for MessagingProvider
import '../utils/constants.dart';
import 'package:provider/provider.dart'; // Added import for Provider
import 'package:get/get.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  UserModel? _userData;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  UserModel? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _userData?.isAdmin ?? false;
  bool get isServiceProvider => _userData?.isServiceProvider ?? false;
  bool get isRegularUser => _userData?.isRegularUser ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    _setLoading(true);
    
    try {
      // Listen to auth state changes
      AuthService.authStateChanges.listen((User? user) async {
        _currentUser = user;
        
        if (user != null) {
          // Get user data from Firestore
          await _loadUserData(user.uid);
          await StorageService.saveUserId(user.uid);
        } else {
          _userData = null;
          await StorageService.clearUserData();
        }
        
        _setLoading(false);
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      _userData = await AuthService.getUserData(userId);
      if (_userData != null) {
        await StorageService.saveUserData(_userData!.toJson());
        await StorageService.saveUserType(_userData!.userType);
      }
    } catch (e) {
      _setError('Failed to load user data: $e');
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.signInWithEmailAndPassword(email, password);
      // Always reload user data after sign in
      if (result.user != null) {
        await _loadUserData(result.user!.uid);
      }
      NotificationService.showSuccessNotification(
        title: 'Welcome Back!',
        message: 'Successfully signed in to your account.',
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up with email and password
  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String userType,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await AuthService.createUserWithEmailAndPassword(
        email,
        password,
        name,
        phone,
        userType,
      );
      NotificationService.showSuccessNotification(
        title: 'Account Created!',
        message: 'Your account has been created successfully.',
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.signInWithGoogle();
      // Always reload user data after sign in
      if (result.user != null) {
        await _loadUserData(result.user!.uid);
      }
      NotificationService.showSuccessNotification(
        title: 'Welcome!',
        message: 'Successfully signed in with Google.',
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut(BuildContext context) async {
    _setLoading(true);
    try {
      await AuthService.signOut();
      await StorageService.clearAllData();
      // Reset messaging provider if available
      try {
        final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
        messagingProvider.reset();
      } catch (_) {}
      NotificationService.showInfoNotification(
        title: 'Signed Out',
        message: 'You have been successfully signed out.',
      );
      // Navigate to login
      if (!context.mounted) return;
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await AuthService.resetPassword(email);
      NotificationService.showSuccessNotification(
        title: 'Password Reset',
        message: 'Password reset email has been sent to your email address.',
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      await AuthService.updateUserData(_currentUser!.uid, data);
      
      // Reload user data
      await _loadUserData(_currentUser!.uid);
      
      NotificationService.showSuccessNotification(
        title: 'Profile Updated',
        message: 'Your profile has been updated successfully.',
      );
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_currentUser != null) {
      await _loadUserData(_currentUser!.uid);
      notifyListeners();
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
} 