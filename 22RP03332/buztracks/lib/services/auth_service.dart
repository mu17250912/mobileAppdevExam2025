import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Register user with email and password
  Future<UserCredential?> registerUser(String email, String password, String username) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'isPremium': false,
        'language': 'en', // default language
        'isNewUser': true, // mark as new user for welcome notification
      });

      return userCredential;
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // Login user with email and password
  Future<UserCredential?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print('Error logging in user: $e');
      rethrow;
    }
  }

  // Logout user
  Future<void> logoutUser() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error logging out user: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user premium status
  Future<void> updatePremiumStatus(String uid, bool isPremium) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isPremium': isPremium,
        'premiumUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating premium status: $e');
      rethrow;
    }
  }

  // Update user language preference
  Future<void> updateLanguage(String uid, String language) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'language': language,
      });
    } catch (e) {
      print('Error updating language: $e');
      rethrow;
    }
  }

  // Update any user field
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        field: value,
      });
    } catch (e) {
      print('Error updating user field: $e');
      rethrow;
    }
  }

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
} 