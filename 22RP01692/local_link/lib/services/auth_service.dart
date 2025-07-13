import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'logger_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login with email and password
  Future<UserCredential?> login(String email, String password, String role) async {
    logger.info('Login attempt for email: $email with role: $role', 'AuthService');
    
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      logger.info('Firebase authentication successful for user: ${userCredential.user!.uid}', 'AuthService');
      
      // Verify role matches
      final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      final storedRole = doc.data()?['role'] as String?;
      
      logger.debug('Stored role: $storedRole, requested role: $role', 'AuthService');
      
      if (storedRole != role) {
        logger.warning('Role mismatch for user ${userCredential.user!.uid}. Expected: $role, Found: $storedRole', 'AuthService');
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'wrong-role',
          message: 'This account is registered as a $storedRole. Please select the correct role.',
        );
      }
      
      logger.info('Login successful for user: ${userCredential.user!.email} with role: $role', 'AuthService');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      logger.error('Firebase authentication error during login', 'AuthService', e);
      rethrow;
    } catch (e) {
      logger.error('Unexpected error during login', 'AuthService', e);
      rethrow;
    }
  }

  // Register new user
  Future<UserCredential?> register(String email, String password, String name, String role) async {
    logger.info('Registration attempt for email: $email with role: $role', 'AuthService');
    
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      logger.info('Firebase user created successfully: ${userCredential.user!.uid}', 'AuthService');
      
      // Create user document in Firestore
      final userData = {
        'name': name,
        'email': email,
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
        'phone': '',
        'address': '',
        'isVerified': false,
        'totalBookings': 0,
        'averageRating': 0.0,
        'favoriteProviders': [],
        'preferences': {
          'notifications': true,
          'emailUpdates': true,
          'preferredCategories': [],
        },
      };
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
      logger.info('User document created in Firestore for: ${userCredential.user!.uid}', 'AuthService');

      // Send notification to all providers about new user registration
      if (role == 'user') {
        logger.debug('Sending new user notification to providers', 'AuthService');
        await NotificationService.sendNewUserNotification(
          userId: userCredential.user!.uid,
          userName: name,
          email: email,
        );
      }
      
      logger.info('Registration completed successfully for: ${userCredential.user!.email}', 'AuthService');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      logger.error('Firebase authentication error during registration', 'AuthService', e);
      rethrow;
    } catch (e) {
      logger.error('Unexpected error during registration', 'AuthService', e);
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    final currentUser = _auth.currentUser;
    logger.info('Logout requested for user: ${currentUser?.email ?? 'unknown'}', 'AuthService');
    
    try {
      await _auth.signOut();
      logger.info('Logout successful', 'AuthService');
    } catch (e) {
      logger.error('Logout error', 'AuthService', e);
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    logger.debug('Fetching user data for UID: $uid', 'AuthService');
    
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        logger.debug('User data retrieved successfully for: $uid', 'AuthService');
        return doc.data();
      } else {
        logger.warning('User document not found for UID: $uid', 'AuthService');
        return null;
      }
    } catch (e) {
      logger.error('Get user data error for UID: $uid', 'AuthService', e);
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    logger.info('Updating profile for user: $uid', 'AuthService');
    logger.debug('Update data: $data', 'AuthService');
    
    try {
      await _firestore.collection('users').doc(uid).update(data);
      logger.info('Profile updated successfully for user: $uid', 'AuthService');
    } catch (e) {
      logger.error('Update profile error for user: $uid', 'AuthService', e);
      rethrow;
    }
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    logger.debug('Fetching user role for UID: $uid', 'AuthService');
    
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final role = doc.data()?['role'] as String?;
      logger.debug('User role retrieved: $role for UID: $uid', 'AuthService');
      return role;
    } catch (e) {
      logger.error('Get user role error for UID: $uid', 'AuthService', e);
      return null;
    }
  }
} 