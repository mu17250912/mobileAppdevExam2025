import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';

class AdminSetupService {
  static final AdminSetupService _instance = AdminSetupService._internal();
  factory AdminSetupService() => _instance;
  AdminSetupService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  /// Create admin user if it doesn't exist
  Future<bool> ensureAdminUserExists() async {
    try {
      _logger.i('Checking if admin user exists...');

      // Check if admin user already exists in Firestore
      try {
        final adminQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: 'admin@gmail.com')
            .where('userType', isEqualTo: 'admin')
            .get();

        if (adminQuery.docs.isNotEmpty) {
          _logger.i('Admin user already exists');
          return true;
        }
      } catch (e) {
        if (e.toString().contains('unavailable') ||
            e.toString().contains('offline') ||
            e.toString().contains('network')) {
          _logger.w('Firestore offline - skipping admin user check');
          return false;
        }
        _logger.e('Error checking admin user: $e');
        return false;
      }

      _logger.i('Admin user not found, creating...');

      // Create Firebase Auth user
      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: 'admin@gmail.com',
          password: '123456',
        );
      } catch (e) {
        if (e.toString().contains('already in use')) {
          // User exists in Auth but not in Firestore, try to sign in to get the user
          try {
            userCredential = await _auth.signInWithEmailAndPassword(
              email: 'admin@gmail.com',
              password: '123456',
            );
            // Sign out immediately to not change the current auth state
            await _auth.signOut();
          } catch (signInError) {
            _logger.e('Failed to sign in as admin: $signInError');
            return false;
          }
        } else {
          _logger.e('Failed to create admin user: $e');
          return false;
        }
      }

      final user = userCredential.user;
      if (user == null) {
        _logger.e('Failed to get admin user from credential');
        return false;
      }

      // Create admin user model
      final adminUser = UserModel(
        id: user.uid,
        name: 'System Administrator',
        email: 'admin@gmail.com',
        phone: '+250123456789',
        userType: UserType.admin,
        isVerified: true,
        rating: null,
        totalRides: 0,
        completedRides: 0,
        isPremium: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActive: DateTime.now(),
        preferences: const {},
      );

      // Save to Firestore
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(adminUser.toMap());
        _logger.i('Admin user created successfully');
        return true;
      } catch (e) {
        if (e.toString().contains('unavailable') ||
            e.toString().contains('offline') ||
            e.toString().contains('network')) {
          _logger
              .w('Firestore offline - admin user will be created when online');
          return false;
        }
        _logger.e('Error saving admin user to Firestore: $e');
        return false;
      }
    } catch (e) {
      _logger.e('Error ensuring admin user exists: $e');
      return false;
    }
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      return userData['userType'] == 'admin';
    } catch (e) {
      _logger.e('Error checking admin status: $e');
      return false;
    }
  }

  /// Get admin user model
  Future<UserModel?> getAdminUser() async {
    try {
      final adminQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'admin@gmail.com')
          .where('userType', isEqualTo: 'admin')
          .get();

      if (adminQuery.docs.isNotEmpty) {
        return UserModel.fromDoc(adminQuery.docs.first);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting admin user: $e');
      return null;
    }
  }

  /// Update admin user data
  Future<bool> updateAdminUser({
    String? name,
    String? phone,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final adminUser = await getAdminUser();
      if (adminUser == null) return false;

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (preferences != null) updates['preferences'] = preferences;

      await _firestore.collection('users').doc(adminUser.id).update(updates);
      return true;
    } catch (e) {
      _logger.e('Error updating admin user: $e');
      return false;
    }
  }

  /// Force create admin user (for manual setup)
  Future<bool> forceCreateAdminUser() async {
    try {
      _logger.i('Force creating admin user...');

      // First, try to create the Firebase Auth user
      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: 'admin@gmail.com',
          password: '123456',
        );
        _logger.i('Firebase Auth user created successfully');
      } catch (e) {
        if (e.toString().contains('already in use')) {
          _logger.i('Firebase Auth user already exists, signing in...');
          try {
            userCredential = await _auth.signInWithEmailAndPassword(
              email: 'admin@gmail.com',
              password: '123456',
            );
            await _auth.signOut(); // Sign out to not change current state
          } catch (signInError) {
            _logger.e('Failed to sign in as admin: $signInError');
            return false;
          }
        } else {
          _logger.e('Failed to create Firebase Auth user: $e');
          return false;
        }
      }

      final user = userCredential.user;
      if (user == null) {
        _logger.e('Failed to get user from credential');
        return false;
      }

      // Create admin user model
      final adminUser = UserModel(
        id: user.uid,
        name: 'System Administrator',
        email: 'admin@gmail.com',
        phone: '+250123456789',
        userType: UserType.admin,
        isVerified: true,
        rating: null,
        totalRides: 0,
        completedRides: 0,
        isPremium: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActive: DateTime.now(),
        preferences: const {},
      );

      // Save to Firestore
      await _firestore.collection('users').doc(user.uid).set(adminUser.toMap());
      _logger.i('Admin user force created successfully');
      return true;
    } catch (e) {
      _logger.e('Error force creating admin user: $e');
      return false;
    }
  }

  /// Create custom admin user with provided credentials
  Future<bool> createCustomAdminUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _logger.i('Creating custom admin user: $email');

      // Check if user already exists
      try {
        final existingQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (existingQuery.docs.isNotEmpty) {
          _logger.w('User with email $email already exists');
          return false;
        }
      } catch (e) {
        if (e.toString().contains('unavailable') ||
            e.toString().contains('offline') ||
            e.toString().contains('network')) {
          _logger.w('Firestore offline - cannot check existing user');
        } else {
          _logger.e('Error checking existing user: $e');
          return false;
        }
      }

      // Create Firebase Auth user
      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        _logger.i('Firebase Auth user created successfully');
      } catch (e) {
        if (e.toString().contains('already in use')) {
          _logger.w('Firebase Auth user already exists');
          return false;
        } else {
          _logger.e('Failed to create Firebase Auth user: $e');
          return false;
        }
      }

      final user = userCredential.user;
      if (user == null) {
        _logger.e('Failed to get user from credential');
        return false;
      }

      // Create admin user model
      final adminUser = UserModel(
        id: user.uid,
        name: name,
        email: email,
        phone: '+250123456789', // Default phone
        userType: UserType.admin,
        isVerified: true,
        rating: null,
        totalRides: 0,
        completedRides: 0,
        isPremium: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActive: DateTime.now(),
        preferences: const {},
      );

      // Save to Firestore
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(adminUser.toMap());
        _logger.i('Custom admin user created successfully');
        return true;
      } catch (e) {
        if (e.toString().contains('unavailable') ||
            e.toString().contains('offline') ||
            e.toString().contains('network')) {
          _logger
              .w('Firestore offline - admin user will be created when online');
          return false;
        }
        _logger.e('Error saving admin user to Firestore: $e');
        return false;
      }
    } catch (e) {
      _logger.e('Error creating custom admin user: $e');
      return false;
    }
  }
}
