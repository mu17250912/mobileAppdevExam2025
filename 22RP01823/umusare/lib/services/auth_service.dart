import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import '../models/user.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Rate limiting for login attempts
  final Map<String, int> _loginAttempts = {};
  final Map<String, DateTime> _lastLoginAttempt = {};
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  // Simple password hashing (in production, use bcrypt or similar)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = base64.encode(bytes);
    return digest;
  }
  
  // Verify password hash
  bool _verifyPassword(String password, String hashedPassword) {
    final hashedInput = _hashPassword(password);
    return hashedInput == hashedPassword;
  }

  // Check rate limiting
  bool _isRateLimited(String email) {
    final now = DateTime.now();
    final lastAttempt = _lastLoginAttempt[email];
    
    if (lastAttempt != null) {
      final timeSinceLastAttempt = now.difference(lastAttempt);
      if (timeSinceLastAttempt > _lockoutDuration) {
        // Reset attempts after lockout period
        _loginAttempts[email] = 0;
      }
    }
    
    final attempts = _loginAttempts[email] ?? 0;
    return attempts >= _maxLoginAttempts;
  }

  // Record login attempt
  void _recordLoginAttempt(String email, bool success) {
    if (success) {
      // Reset attempts on successful login
      _loginAttempts[email] = 0;
      _lastLoginAttempt.remove(email);
    } else {
      // Increment failed attempts
      _loginAttempts[email] = (_loginAttempts[email] ?? 0) + 1;
      _lastLoginAttempt[email] = DateTime.now();
    }
  }

  // Register new user
  Future<User> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (name.trim().isEmpty) {
        throw Exception('Name is required.');
      }
      
      if (email.trim().isEmpty) {
        throw Exception('Email is required.');
      }
      
      if (!RegExp(r'^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}').hasMatch(email.trim())) {
        throw Exception('Please enter a valid email address.');
      }
      
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters long.');
      }

      // Check if user already exists with this email
      final QuerySnapshot existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('An account already exists for that email.');
      }

      // Hash the password before storing
      final hashedPassword = _hashPassword(password);

      // Create user document in Firestore
      final User user = User(
        id: '', // Will be set after document creation
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: hashedPassword,
        createdAt: DateTime.now(),
      );

      // Add user to Firestore and get the document ID
      final DocumentReference docRef = await _firestore
          .collection('users')
          .add(user.toMap());

      // Create the final user object with the document ID
      final User createdUser = User(
        id: docRef.id,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: hashedPassword,
        createdAt: DateTime.now(),
      );

      // Update the document with the correct ID
      await docRef.update({'id': docRef.id});

      // Set as current user
      UserService.setCurrentUser(createdUser);

      return createdUser;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An error occurred during registration: $e');
    }
  }

  // Sign in user with enhanced validation and rate limiting
  Future<User> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty) {
        throw Exception('Email is required.');
      }
      
      if (password.isEmpty) {
        throw Exception('Password is required.');
      }
      
      if (!RegExp(r'^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}').hasMatch(email.trim())) {
        throw Exception('Please enter a valid email address.');
      }

      // Check rate limiting
      if (_isRateLimited(email.trim().toLowerCase())) {
        throw Exception('Too many failed login attempts. Please try again in 15 minutes.');
      }

      // Find user by email (case-insensitive)
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      if (userQuery.docs.isEmpty) {
        _recordLoginAttempt(email.trim().toLowerCase(), false);
        throw Exception('No account found with that email address.');
      }

      final DocumentSnapshot userDoc = userQuery.docs.first;
      final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Verify password hash
      if (!_verifyPassword(password, userData['password'])) {
        _recordLoginAttempt(email.trim().toLowerCase(), false);
        throw Exception('Incorrect password. Please try again.');
      }

      // Update last login time
      await userDoc.reference.update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

      final User user = User.fromMap(userData, userDoc.id);
      
      // Record successful login
      _recordLoginAttempt(email.trim().toLowerCase(), true);
      
      // Set as current user
      UserService.setCurrentUser(user);

      return user;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An error occurred during sign in: $e');
    }
  }

  // Enhanced user validation with rate limiting
  Future<bool> validateUserCredentials({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty || password.isEmpty) {
        return false;
      }
      
      if (!RegExp(r'^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}').hasMatch(email.trim())) {
        return false;
      }

      // Check rate limiting
      if (_isRateLimited(email.trim().toLowerCase())) {
        return false;
      }

      // Check if user exists
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      if (userQuery.docs.isEmpty) {
        _recordLoginAttempt(email.trim().toLowerCase(), false);
        return false;
      }

      final DocumentSnapshot userDoc = userQuery.docs.first;
      final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Verify password
      final isValid = _verifyPassword(password, userData['password']);
      _recordLoginAttempt(email.trim().toLowerCase(), isValid);
      
      return isValid;
    } catch (e) {
      return false;
    }
  }

  // Get remaining login attempts
  int getRemainingLoginAttempts(String email) {
    final attempts = _loginAttempts[email.trim().toLowerCase()] ?? 0;
    return _maxLoginAttempts - attempts;
  }

  // Check if account is locked
  bool isAccountLocked(String email) {
    return _isRateLimited(email.trim().toLowerCase());
  }

  // Get lockout time remaining
  Duration? getLockoutTimeRemaining(String email) {
    final lastAttempt = _lastLoginAttempt[email.trim().toLowerCase()];
    if (lastAttempt != null) {
      final now = DateTime.now();
      final timeSinceLastAttempt = now.difference(lastAttempt);
      if (timeSinceLastAttempt < _lockoutDuration) {
        return _lockoutDuration - timeSinceLastAttempt;
      }
    }
    return null;
  }

  // Sign out user with session destruction
  Future<void> signOut() async {
    UserService.destroySession();
  }

  // Clear user session (for normal logout)
  Future<void> clearSession() async {
    UserService.clearCurrentUser();
  }

  // Get user data from Firestore
  Future<User?> getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return User.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      if (userQuery.docs.isNotEmpty) {
        final DocumentSnapshot userDoc = userQuery.docs.first;
        return User.fromMap(
          userDoc.data() as Map<String, dynamic>, 
          userDoc.id
        );
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user by email: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (name != null && name.trim().isNotEmpty) {
        updates['name'] = name.trim();
      }
      
      if (email != null && email.trim().isNotEmpty) {
        if (!RegExp(r'^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}').hasMatch(email.trim())) {
          throw Exception('Please enter a valid email address.');
        }
        
        // Check if email is already taken by another user
        final QuerySnapshot existingUser = await _firestore
            .collection('users')
            .where('email', isEqualTo: email.trim().toLowerCase())
            .get();

        if (existingUser.docs.isNotEmpty && 
            existingUser.docs.first.id != userId) {
          throw Exception('Email is already taken by another user.');
        }
        updates['email'] = email.trim().toLowerCase();
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update(updates);
      }
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  // Delete user account
  Future<void> deleteUserAccount(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting user account: $e');
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      return userQuery.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking email existence: $e');
    }
  }

  // Change password
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Get current user data
      final User? currentUser = await getUserData(userId);
      if (currentUser == null) {
        throw Exception('User not found.');
      }

      // Verify current password
      if (!_verifyPassword(currentPassword, currentUser.password)) {
        throw Exception('Current password is incorrect.');
      }

      // Validate new password
      if (newPassword.length < 6) {
        throw Exception('New password must be at least 6 characters long.');
      }

      // Hash new password
      final hashedNewPassword = _hashPassword(newPassword);

      // Update password in database
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'password': hashedNewPassword});
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }
} 