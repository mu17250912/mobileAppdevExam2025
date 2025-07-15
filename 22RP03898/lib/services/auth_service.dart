/// Authentication Service for SafeRide
///
/// Handles user authentication, registration, and user profile management.
/// Supports multiple user types: passengers, drivers, and admins.
///
/// Features:
/// - Email/password authentication
/// - Google Sign-In (web and mobile)
/// - User registration with role selection
/// - User profile management
/// - Session management with caching
/// - Role-based access control
///
/// User Types:
/// - Passenger: Can book rides, view ride history
/// - Driver: Can post rides, manage bookings
/// - Admin: Can manage users, view analytics
///
/// TODO: Future Enhancements:
/// - Phone number authentication
/// - Social media login (Facebook)
/// - Two-factor authentication
/// - Password reset via SMS
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/user_model.dart';
import 'package:logger/logger.dart';
import 'error_service.dart';

final Logger _logger = Logger();
final ErrorService _errorService = ErrorService();

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for current user model
  UserModel? _cachedUserModel;
  String? _cachedUserId;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Get current user model with caching
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) {
      _clearCache();
      return null;
    }

    // Check if we have a valid cached version
    if (_cachedUserModel != null &&
        _cachedUserId == user.uid &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheValidDuration) {
      return _cachedUserModel;
    }

    // Check if we have expired cached data first (for offline scenarios)
    if (_cachedUserModel != null && _cachedUserId == user.uid) {
      _logger.i('Using cached user data (may be expired)');
      return _cachedUserModel;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        _logger
            .w('User document not found in Firestore, creating basic profile');
        // Create a basic user document for users who exist in Firebase Auth but not in Firestore
        final basicUserModel = _createBasicUserModel(user);
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(basicUserModel.toMap());
          _logger.i('Created basic user profile for: ${user.uid}');
        } catch (firestoreError) {
          _logger.e(
              'Failed to create user document in Firestore: $firestoreError');
          // Still return the basic model even if Firestore creation fails
        }
        _updateCache(basicUserModel, user.uid);
        return basicUserModel;
      }

      final userModel = UserModel.fromMap(doc.data()!, user.uid);
      _updateCache(userModel, user.uid);
      return userModel;
    } catch (e) {
      _errorService.logError('Error getting user model', e);
      _logger.e('Error getting user model: $e');

      // Return basic user model if Firestore is unavailable
      final basicUserModel = _createBasicUserModel(user);
      _updateCache(basicUserModel, user.uid);
      return basicUserModel;
    }
  }

  // Create basic user model from Firebase Auth data when Firestore is unavailable
  UserModel _createBasicUserModel(User user) {
    // Check if this is a Google user (has provider data)
    final isGoogleUser = user.providerData
        .any((provider) => provider.providerId == 'google.com');

    return UserModel(
      id: user.uid,
      name: user.displayName ?? (isGoogleUser ? 'Google User' : 'User'),
      email: user.email ?? '',
      phone: user.phoneNumber,
      userType: UserType.passenger, // Default to passenger
      isVerified: isGoogleUser, // Google users are verified
      rating: null,
      totalRides: 0,
      completedRides: 0,
      isPremium: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastActive: DateTime.now(),
      preferences: const {},
      profileImage: user.photoURL, // Include profile image for Google users
    );
  }

  // Email/Password Registration
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserType userType,
    String? vehicleType,
    String? vehicleNumber,
    String? licenseNumber,
  }) async {
    try {
      _logger
          .i('Starting registration for: $email with type: ${userType.name}');

      // Create Firebase user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }

      // Create user model
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email,
        phone: phone,
        userType: userType,
        isVerified: false,
        rating: null,
        totalRides: 0,
        completedRides: 0,
        isPremium: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActive: DateTime.now(),
        preferences: const {},
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        licenseNumber: licenseNumber,
      );

      // Save to Firestore
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      _updateCache(userModel, user.uid);
      _logger.i('User registered successfully: ${user.uid}');
      return userModel;
    } catch (e) {
      _errorService.logError('Registration failed', e);
      throw Exception('Registration failed: $e');
    }
  }

  // Email/Password Sign In
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      // Ensure Firebase is initialized
      if (!Firebase.apps.isNotEmpty) {
        throw Exception('Firebase is not initialized');
      }

      _logger.i('Signing in user: $email');

      // Trim and validate email format
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();

      if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }

      // Check if email format is valid
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedEmail)) {
        throw Exception('Please enter a valid email address');
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Sign in failed - no user returned');
      }

      _logger.i('Firebase Auth successful for user: ${user.uid}');

      final userModel = await getCurrentUserModel();
      if (userModel == null) {
        // User exists in Firebase Auth but not in Firestore
        // Create a basic user document
        _logger
            .w('User document not found in Firestore, creating basic profile');

        final basicUserModel = _createBasicUserModel(user);
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(basicUserModel.toMap());

        _logger.i('Created basic user profile for: ${user.uid}');
        return basicUserModel;
      }

      // Update last active
      await _firestore.collection('users').doc(user.uid).update({
        'lastActive': Timestamp.fromDate(DateTime.now()),
      });

      _logger.i(
          'User signed in successfully: ${user.uid} with type: ${userModel.userType}');
      return userModel;
    } catch (e) {
      _errorService.logError('Sign in failed', e);

      // Provide more specific error messages
      if (e.toString().contains('invalid-credential')) {
        throw Exception(
            'Invalid email or password. Please check your credentials and try again.');
      } else if (e.toString().contains('user-not-found')) {
        throw Exception(
            'No account found with this email address. Please register first.');
      } else if (e.toString().contains('wrong-password')) {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('Too many failed attempts. Please try again later.');
      } else if (e.toString().contains('network')) {
        throw Exception(
            'Network error. Please check your internet connection.');
      } else {
        throw Exception('Sign in failed: $e');
      }
    }
  }

  /// Professional Google Sign-In implementation
  /// Uses Firebase Auth for both web and mobile platforms
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _logger.i('Starting Google Sign-In process');

      // Create Google Auth Provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Add custom parameters for better UX
      googleProvider.setCustomParameters({
        'login_hint': 'user@example.com',
        'prompt': 'select_account',
      });

      // Use signInWithPopup for both web and mobile
      _logger.i('Using Google Sign-In with popup');
      final userCredential = await _auth.signInWithPopup(googleProvider);

      // After successful sign-in, sync with Firestore
      final user = userCredential.user;
      if (user == null) {
        _logger.e('Google Sign-In succeeded but no user returned');
        return null;
      }

      _logger.i('Google Sign-In successful for user: ${user.uid}');

      try {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          _logger.i('Creating new user document for Google user: ${user.uid}');

          // Create comprehensive user document
          final newUser = UserModel(
            id: user.uid,
            name: user.displayName ?? 'Google User',
            email: user.email ?? '',
            phone: user.phoneNumber ?? '',
            userType: UserType.passenger, // Default to passenger
            isVerified: true, // Google users are verified
            rating: null,
            totalRides: 0,
            completedRides: 0,
            isPremium: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            lastActive: DateTime.now(),
            preferences: const {},
            profileImage: user.photoURL,
          );

          await userDoc.set(newUser.toMap());
          _logger.i('User document created successfully for Google user');
        } else {
          _logger.i('Updating existing user document for: ${user.uid}');

          // Update profile information from Google
          await userDoc.update({
            'name': user.displayName ?? 'Google User',
            'email': user.email ?? '',
            'profileImage': user.photoURL,
            'isVerified': true, // Ensure Google users are verified
            'updatedAt': DateTime.now(),
            'lastActive': DateTime.now(),
          });
        }
      } catch (firestoreError) {
        _logger.e('Error syncing user with Firestore: $firestoreError');
        // Don't fail the sign-in if Firestore sync fails
        // The user can still use the app with basic functionality
      }

      _logger.i('Google Sign-In process completed successfully');
      return userCredential;
    } catch (e) {
      _logger.e('Google Sign-In failed: $e');
      _errorService.logError('Google Sign-In failed', e);

      // Provide user-friendly error messages
      if (e.toString().contains('network')) {
        throw Exception(
            'Network error. Please check your internet connection.');
      } else if (e.toString().contains('cancelled')) {
        throw Exception('Sign-in was cancelled.');
      } else if (e.toString().contains('popup_closed')) {
        throw Exception('Sign-in popup was closed. Please try again.');
      } else if (e.toString().contains('popup_blocked')) {
        throw Exception(
            'Sign-in popup was blocked. Please allow popups and try again.');
      } else {
        throw Exception('Google Sign-In failed. Please try again.');
      }
    }
  }

  /// Sign out from Firebase
  Future<void> signOut() async {
    try {
      _logger.i('Signing out user');

      // Sign out from Firebase
      await _auth.signOut();

      _clearCache();
      _logger.i('User signed out successfully');
    } catch (e) {
      _errorService.logError('Sign out failed', e);
      throw Exception('Sign out failed: $e');
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _logger.i('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent successfully');
    } catch (e) {
      _errorService.logError('Password reset failed', e);
      throw Exception('Password reset failed: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? bio,
    String? profileImage,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (bio != null) updates['bio'] = bio;
      if (profileImage != null) updates['profileImage'] = profileImage;
      if (preferences != null) updates['preferences'] = preferences;

      await _firestore.collection('users').doc(user.uid).update(updates);
      _clearCache(); // Clear cache to force refresh
      _logger.i('User profile updated successfully');
    } catch (e) {
      _errorService.logError('Profile update failed', e);
      throw Exception('Profile update failed: $e');
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'preferences': preferences,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _clearCache();
      _logger.i('User preferences updated successfully');
    } catch (e) {
      _errorService.logError('Preferences update failed', e);
      throw Exception('Preferences update failed: $e');
    }
  }

  // Check if user is premium
  Future<bool> isUserPremium() async {
    try {
      final userModel = await getCurrentUserModel();
      return userModel?.isPremium ?? false;
    } catch (e) {
      _logger.e('Error checking premium status: $e');
      return false;
    }
  }

  // Update premium status
  Future<void> updatePremiumStatus(bool isPremium) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'isPremium': isPremium,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _clearCache();
      _logger.i('Premium status updated: $isPremium');
    } catch (e) {
      _errorService.logError('Premium status update failed', e);
      throw Exception('Premium status update failed: $e');
    }
  }

  // Cache management
  void _updateCache(UserModel userModel, String userId) {
    _cachedUserModel = userModel;
    _cachedUserId = userId;
    _lastCacheTime = DateTime.now();
  }

  void _clearCache() {
    _cachedUserModel = null;
    _cachedUserId = null;
    _lastCacheTime = null;
  }

  // Get user by ID (for admin purposes)
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromMap(doc.data()!, userId);
    } catch (e) {
      _errorService.logError('Error getting user by ID', e);
      _logger.e('Error getting user by ID: $e');
      return null;
    }
  }

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase user
      await user.delete();

      _clearCache();
      _logger.i('User account deleted successfully');
    } catch (e) {
      _errorService.logError('Account deletion failed', e);
      throw Exception('Account deletion failed: $e');
    }
  }
}
