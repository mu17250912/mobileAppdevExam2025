import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create a new user in Firestore
  Future<void> createUser(UserProfile userProfile) async {
    try {
      await _usersCollection.doc(userProfile.uid).set(userProfile.toMap());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Get user by UID
  Future<UserProfile?> getUserById(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUser(UserProfile userProfile) async {
    try {
      await _usersCollection.doc(userProfile.uid).update(userProfile.toMap());
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Check if user exists by email
  Future<bool> userExistsByEmail(String email) async {
    try {
      final query = await _usersCollection.where('email', isEqualTo: email).get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Get user by email
  Future<UserProfile?> getUserByEmail(String email) async {
    try {
      final query = await _usersCollection.where('email', isEqualTo: email).get();
      if (query.docs.isNotEmpty) {
        return UserProfile.fromMap(query.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  // Update last login time
  Future<void> updateLastLogin(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  // Update email verification status
  Future<void> updateEmailVerification(String uid, bool isVerified) async {
    try {
      await _usersCollection.doc(uid).update({
        'isEmailVerified': isVerified,
      });
    } catch (e) {
      print('Error updating email verification: $e');
    }
  }

  // Update phone verification status
  Future<void> updatePhoneVerification(String uid, bool isVerified) async {
    try {
      await _usersCollection.doc(uid).update({
        'isPhoneVerified': isVerified,
      });
    } catch (e) {
      print('Error updating phone verification: $e');
    }
  }

  // Update subscription information
  Future<void> updateSubscription(String uid, String plan, DateTime expiry) async {
    try {
      await _usersCollection.doc(uid).update({
        'isPremium': true,
        'subscriptionPlan': plan,
        'subscriptionExpiry': expiry.toIso8601String(),
      });
    } catch (e) {
      print('Error updating subscription: $e');
    }
  }

  // Update user preferences
  Future<void> updatePreferences(String uid, Map<String, dynamic> preferences) async {
    try {
      await _usersCollection.doc(uid).update({
        'preferences': preferences,
      });
    } catch (e) {
      print('Error updating preferences: $e');
    }
  }

  // Get all users (admin function)
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final query = await _usersCollection.get();
      return query.docs.map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Search users by name
  Future<List<UserProfile>> searchUsersByName(String name) async {
    try {
      final query = await _usersCollection
          .where('displayName', isGreaterThanOrEqualTo: name)
          .where('displayName', isLessThan: name + '\uf8ff')
          .get();
      return query.docs.map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get users by subscription plan
  Future<List<UserProfile>> getUsersBySubscription(String plan) async {
    try {
      final query = await _usersCollection.where('subscriptionPlan', isEqualTo: plan).get();
      return query.docs.map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting users by subscription: $e');
      return [];
    }
  }

  // Get premium users
  Future<List<UserProfile>> getPremiumUsers() async {
    try {
      final query = await _usersCollection.where('isPremium', isEqualTo: true).get();
      return query.docs.map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting premium users: $e');
      return [];
    }
  }
} 