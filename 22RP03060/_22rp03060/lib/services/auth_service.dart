import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart' as app_models;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      print('Starting sign in for: $email');
      
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Sign in successful for user: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      print('Starting registration for: $email');
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Firebase Auth user created: ${result.user?.uid}');

      // Create user document in Firestore
      if (result.user != null) {
        await _createUserDocument(result.user!, name, email);
      }

      print('Registration completed successfully');
      return result;
    } catch (e) {
      print('Error registering: $e');
      if (e is FirebaseAuthException) {
        print('Error code: ${e.code}');
        print('Error message: ${e.message}');
      }
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String name, String email) async {
    try {
      print('Creating user document for: ${user.uid}');
      
      final userModel = app_models.UserModel(
        id: user.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());
      
      print('User document created successfully in Firestore');
    } catch (e) {
      print('Error creating user document in Firestore: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<app_models.UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return app_models.UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }


} 