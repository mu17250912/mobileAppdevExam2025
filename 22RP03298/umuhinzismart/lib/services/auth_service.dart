import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _currentUser;
  String? _userRole;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get currentUser => _currentUser;
  String? get userRole => _userRole;
  String? get errorMessage => _errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    _checkAuthStatus();
  }

  /// Checks if user is already logged in (from local storage)
  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      final role = prefs.getString('user_role');

      if (username != null && role != null) {
        // Always validate credentials with Firestore
        final snap = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .where('role', isEqualTo: role)
            .get();
        if (snap.docs.isNotEmpty) {
          _currentUser = username;
          _userRole = role;
          _isAuthenticated = true;
        } else {
          // Clear invalid stored credentials
          await prefs.remove('username');
          await prefs.remove('user_role');
          _currentUser = null;
          _userRole = null;
          _isAuthenticated = false;
        }
      } else {
        _currentUser = null;
        _userRole = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      // On error, clear credentials and require login
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('user_role');
      _currentUser = null;
      _userRole = null;
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validates stored credentials against the server
  Future<bool> _validateStoredCredentials(String username, String role) async {
    try {
      print('🔍 Validating credentials for: $username ($role)');
      
      // Check if user exists in Firestore
      final snap = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: role)
          .get();

      print('📊 Firestore query result: ${snap.docs.length} documents found');

      if (snap.docs.isEmpty) {
        print('❌ User not found in database: $username ($role)');
        return false;
      }

      final userDoc = snap.docs.first;
      final storedRole = userDoc['role'];
      
      print('📋 User document found: ${userDoc.data()}');
      
      // Verify role matches
      if (storedRole != role) {
        print('❌ Role mismatch: stored=$role, server=$storedRole');
        return false;
      }

      print('✅ Credentials validated: $username ($role)');
      return true;
    } catch (e) {
      print('❌ Error validating credentials: $e');
      // For Windows testing, allow local validation if Firebase fails
      if (e.toString().contains('firebase') || e.toString().contains('network')) {
        print('⚠️ Firebase unavailable, using local validation for testing');
        return _validateCredentialsLocally(username, role);
      }
      return false;
    }
  }

  /// Fallback local validation for testing when Firebase is unavailable
  Future<bool> _validateCredentialsLocally(String username, String role) async {
    try {
      // For testing purposes, accept any non-empty username and valid role
      if (username.trim().isNotEmpty && 
          (role == 'farmer' || role == 'dealer')) {
        print('✅ Local validation passed: $username ($role)');
        return true;
      }
      print('❌ Local validation failed: $username ($role)');
      return false;
    } catch (e) {
      print('❌ Local validation error: $e');
      return false;
    }
  }

  /// Login with Firestore credentials
  Future<bool> login(String username, String password, String? role) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final usernameClean = username.trim().toLowerCase();
      final passwordClean = password.trim();
      final roleClean = role?.trim().toLowerCase();
      print('DEBUG: Login attempt username="$usernameClean", password="$passwordClean", role="$roleClean"');

      if (usernameClean.isEmpty || passwordClean.isEmpty) {
        _errorMessage = 'Username and password cannot be empty.';
        print(_errorMessage);
        _isAuthenticated = false;
        return false;
      }

      // Query all users with matching username (case-insensitive)
      final snap = await _firestore
          .collection('users')
          .where('username', isEqualTo: usernameClean)
          .get();
      print('DEBUG: Found ${snap.docs.length} user(s) with username="$usernameClean"');
      if (snap.docs.isEmpty) {
        _errorMessage = 'User does not exist.';
        print(_errorMessage);
        _isAuthenticated = false;
        return false;
      }
      // Check password and role
      QueryDocumentSnapshot<Map<String, dynamic>>? userDoc;
      try {
        userDoc = snap.docs.firstWhere(
          (doc) => (doc['password']?.toString().trim() ?? '') == passwordClean &&
                   (doc['role']?.toString().toLowerCase() ?? '') == (roleClean ?? ''),
        );
      } catch (e) {
        userDoc = null;
      }
      if (userDoc == null) {
        _errorMessage = 'Invalid username or password.';
        print(_errorMessage);
        _isAuthenticated = false;
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', usernameClean);
      await prefs.setString('user_role', roleClean ?? 'farmer');
      await prefs.setString('join_date', userDoc['join_date'] ?? DateTime.now().toIso8601String());
      _currentUser = usernameClean;
      _userRole = roleClean ?? 'farmer';
      _isAuthenticated = true;
      print('User logged in: $_currentUser ($_userRole)');
      return true;
    } catch (e) {
      print('Login error: $e');
      _errorMessage = 'Login failed. Please try again.';
      _isAuthenticated = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout and clear all user data
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('user_role');
      _currentUser = null;
      _userRole = null;
      _isAuthenticated = false;
      _errorMessage = null;
      print('User logged out');
    } catch (e) {
      print('Logout error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Register a new user in Firestore, then log them in
  Future<bool> register(String username, String password, String role, {String? email, String? phone}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final usernameClean = username.trim().toLowerCase();
      final passwordClean = password.trim();
      final roleClean = role.trim().toLowerCase();
      print('DEBUG: Registering username="$usernameClean", password="$passwordClean", role="$roleClean"');

      if (usernameClean.isEmpty || passwordClean.isEmpty) {
        _errorMessage = 'Username and password cannot be empty.';
        print('❌ Registration failed: $_errorMessage');
        return false;
      }
      if (passwordClean.length < 4) {
        _errorMessage = 'Password must be at least 4 characters long.';
        print('❌ Registration failed: $_errorMessage');
        return false;
      }

      // Check if username already exists (case-insensitive)
      final snap = await _firestore
          .collection('users')
          .where('username', isEqualTo: usernameClean)
          .get();
      if (snap.docs.isNotEmpty) {
        _errorMessage = 'Username already taken.';
        print('❌ Registration failed: $_errorMessage');
        return false;
      }
      print('✅ Username is available');

      final joinDate = DateTime.now().toIso8601String();
      try {
        final userData = {
          'username': usernameClean,
          'password': passwordClean, // Save password for login to work
          'role': roleClean,
          'join_date': joinDate,
          'created_at': FieldValue.serverTimestamp(),
        };
        if (email != null && email.trim().isNotEmpty) {
          userData['email'] = email.trim();
        }
        if (phone != null && phone.trim().isNotEmpty) {
          userData['phone'] = phone.trim();
        }
        print('🔵 Attempting to save user data to Firestore...');
        print('🔵 User data: $userData');
        final docRef = await _firestore.collection('users').add(userData);
        print('✅ User registered in Firestore with docId: ${docRef.id}');
        // Verify the data was actually saved
        final savedDoc = await docRef.get();
        if (savedDoc.exists) {
          print('✅ Data verification successful: ${savedDoc.data()}');
        } else {
          print('❌ Data verification failed: Document does not exist');
          throw Exception('Data was not saved to Firestore');
        }
      } catch (firestoreError) {
        print('❌ Firestore write error: $firestoreError');
        _errorMessage = 'Could not save user to Firestore: $firestoreError';
        return false;
      }
      // Immediately log in the user after registration
      print('🔵 Logging in user after successful registration...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', usernameClean);
      await prefs.setString('user_role', roleClean);
      await prefs.setString('join_date', joinDate);
      _currentUser = usernameClean;
      _userRole = roleClean;
      _isAuthenticated = true;
      print('✅ User registered and logged in: $_currentUser ($_userRole)');
      return true;
    } catch (e) {
      print('❌ Registration error: $e');
      _errorMessage = 'Registration failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Test Firestore connectivity and data storage
  Future<bool> testFirestoreConnection() async {
    try {
      print('🔵 Testing Firestore connection...');
      
      // Test write operation
      final testData = {
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Connection test',
      };
      
      final docRef = await _firestore.collection('test').add(testData);
      print('✅ Test write successful: ${docRef.id}');
      
      // Test read operation
      final doc = await docRef.get();
      if (doc.exists) {
        print('✅ Test read successful: ${doc.data()}');
        
        // Clean up test data
        await docRef.delete();
        print('✅ Test cleanup successful');
        
        return true;
      } else {
        print('❌ Test read failed: Document does not exist');
        return false;
      }
    } catch (e) {
      print('❌ Firestore test failed: $e');
      return false;
    }
  }

  /// Update user role
  Future<void> updateUserRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      _userRole = role;
      notifyListeners();
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  /// Force re-authentication by clearing stored credentials
  Future<void> forceReAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('user_role');
      _currentUser = null;
      _userRole = null;
      _isAuthenticated = false;
      _errorMessage = null;
      print('🔄 Forced re-authentication - cleared stored credentials');
    } catch (e) {
      print('Error during force re-authentication: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Check if user needs to re-authenticate
  Future<bool> needsReAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      final role = prefs.getString('user_role');
      
      if (username == null || role == null) {
        return true;
      }
      
      // Validate against server
      return !(await _validateStoredCredentials(username, role));
    } catch (e) {
      print('Error checking re-authentication need: $e');
      return true;
    }
  }

  /// Check if current session is valid
  Future<bool> isSessionValid() async {
    try {
      if (!_isAuthenticated || _currentUser == null || _userRole == null) {
        return false;
      }
      
      // Validate current session against server
      return await _validateStoredCredentials(_currentUser!, _userRole!);
    } catch (e) {
      print('Error checking session validity: $e');
      return false;
    }
  }

  /// Refresh authentication status
  Future<void> refreshAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _checkAuthStatus();
    } catch (e) {
      print('Error refreshing auth status: $e');
      // Clear invalid session
      await forceReAuthentication();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 