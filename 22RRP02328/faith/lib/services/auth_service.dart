import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign up with email and password
  static Future<UserCredential> createUserWithEmailAndPassword(
    String email, 
    String password,
    String name,
    String phone,
    String userType,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _createUserDocument(result.user!, name, phone, userType);

      return result;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with Google
  static Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Web sign-in
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      return await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } else {
      // Mobile sign-in
      final GoogleSignIn _googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        // _googleSignIn.signOut(), // This line is removed as per the edit hint
      ]);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Create user document in Firestore
  static Future<void> _createUserDocument(
    User user,
    String name,
    String phone,
    String userType,
  ) async {
    final userModel = UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: name,
      phone: phone,
      userType: userType,
      profileImage: user.photoURL,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toJson());
  }

  // Get user data from Firestore
  static Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user data: $e';
    }
  }

  // Update user data
  static Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to update user data: $e';
    }
  }

  // Fetch all users from Firestore
  static Future<List<UserModel>> getAllUsers() async {
    final query = await _firestore.collection(AppConstants.usersCollection).get();
    return query.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  }

  // Handle authentication errors
  static String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    return error.toString();
  }
} 