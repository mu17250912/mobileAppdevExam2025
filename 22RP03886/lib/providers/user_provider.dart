import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  UserProfile? _userProfile;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  bool _isLoading = false;
  String? _error;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Check if user already exists
      final exists = await _userService.userExistsByEmail(email);
      if (exists) {
        throw Exception('User with this email already exists');
      }

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Create user profile
        final userProfile = UserProfile(
          uid: user.uid,
          email: email,
          displayName: '${firstName ?? ''} ${lastName ?? ''}'.trim(),
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          gender: gender,
          dateOfBirth: dateOfBirth,
          createdAt: DateTime.now(),
          isEmailVerified: user.emailVerified,
        );

        // Save to Firestore
        await _userService.createUser(userProfile);
        
        // Update display name in Firebase Auth
        if (userProfile.displayName != null && userProfile.displayName!.isNotEmpty) {
          await user.updateDisplayName(userProfile.displayName);
        }

        _userProfile = userProfile;
        notifyListeners();
        
        // Track user registration in analytics
        _trackUserRegistration();
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Get user profile from Firestore
        final userProfile = await _userService.getUserById(user.uid);
        if (userProfile != null) {
          // Update last login
          await _userService.updateLastLogin(user.uid);
          
          _userProfile = userProfile.copyWith(
            lastLoginAt: DateTime.now(),
            isEmailVerified: user.emailVerified,
          );
          notifyListeners();
          
          // Track user login in analytics
          _trackUserLogin();
        } else {
          // Create a basic profile if it doesn't exist (fallback for existing users)
          final basicProfile = UserProfile(
            uid: user.uid,
            email: user.email ?? email,
            displayName: user.displayName,
            createdAt: DateTime.now(),
            isEmailVerified: user.emailVerified,
          );
          
          try {
            await _userService.createUser(basicProfile);
            _userProfile = basicProfile.copyWith(lastLoginAt: DateTime.now());
            notifyListeners();
          } catch (createError) {
            print('Error creating fallback profile: $createError');
            // Still set the basic profile even if Firestore save fails
            _userProfile = basicProfile.copyWith(lastLoginAt: DateTime.now());
            notifyListeners();
          }
        }
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Google Sign-In (temporarily disabled)
  Future<void> signInWithGoogle() async {
    // Temporarily disabled due to package compatibility issues
    print('Google Sign-In temporarily disabled');
    // TODO: Re-enable when package compatibility is resolved
  }

  // Update user profile
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? country,
  }) async {
    if (_userProfile == null) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      final updatedProfile = _userProfile!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        gender: gender,
        dateOfBirth: dateOfBirth,
        address: address,
        city: city,
        country: country,
        displayName: '${firstName ?? _userProfile!.firstName ?? ''} ${lastName ?? _userProfile!.lastName ?? ''}'.trim(),
      );

      await _userService.updateUser(updatedProfile);
      _userProfile = updatedProfile;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update profile image
  Future<void> updateProfileImage(String imageUrl) async {
    if (_userProfile == null) return;
    
    try {
      final updatedProfile = _userProfile!.copyWith(profileImageUrl: imageUrl);
      await _userService.updateUser(updatedProfile);
      _userProfile = updatedProfile;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (_userProfile == null) return;
    
    try {
      // Delete from Firestore
      await _userService.deleteUser(_userProfile!.uid);
      
      // Delete from Firebase Auth
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
      
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Subscription management
  Future<void> setSubscription(String plan, DateTime expiry) async {
    if (_userProfile == null) return;
    
    try {
      await _userService.updateSubscription(_userProfile!.uid, plan, expiry);
      _userProfile = _userProfile!.copyWith(
        isPremium: true,
        subscriptionPlan: plan,
        subscriptionExpiry: expiry,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Update preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    if (_userProfile == null) return;
    
    try {
      await _userService.updatePreferences(_userProfile!.uid, preferences);
      _userProfile = _userProfile!.copyWith(preferences: preferences);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Getters
  bool get isSubscribed {
    if (_userProfile == null) return false;
    if (_userProfile!.subscriptionExpiry == null) return false;
    return _userProfile!.subscriptionExpiry!.isAfter(DateTime.now());
  }

  int? get remainingTrialDays {
    if (_userProfile == null) return null;
    if (_userProfile!.subscriptionPlan != 'trial') return null;
    if (_userProfile!.subscriptionExpiry == null) return null;
    final diff = _userProfile!.subscriptionExpiry!.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff + 1 : 0;
  }

  bool get isEmailVerified => _userProfile?.isEmailVerified ?? false;
  bool get isPhoneVerified => _userProfile?.isPhoneVerified ?? false;

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _onAuthStateChanged(User? user) async {
    if (user == null) {
      _userProfile = null;
    } else {
      // Get user profile from Firestore
      final userProfile = await _userService.getUserById(user.uid);
      if (userProfile != null) {
        _userProfile = userProfile.copyWith(
          isEmailVerified: user.emailVerified,
        );
      } else {
        // Create basic profile if not exists
        _userProfile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          createdAt: DateTime.now(),
          isEmailVerified: user.emailVerified,
        );
      }
    }
    notifyListeners();
  }

  // Analytics tracking methods
  void _trackUserRegistration() {
    try {
      if (_userProfile != null) {
        // Note: Analytics tracking will be handled by the UI layer
        // where we have access to BuildContext
        print('User registration tracked: ${_userProfile!.email}');
      }
    } catch (e) {
      print('Error tracking user registration: $e');
    }
  }

  void _trackUserLogin() {
    try {
      if (_userProfile != null) {
        // Note: Analytics tracking will be handled by the UI layer
        // where we have access to BuildContext
        print('User login tracked: ${_userProfile!.email}');
      }
    } catch (e) {
      print('Error tracking user login: $e');
    }
  }
} 