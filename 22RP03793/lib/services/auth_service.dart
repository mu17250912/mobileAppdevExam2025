import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign up user with email & password and save role
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String role,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email.trim(),
          'role': role,
          'fullName': fullName.trim(),
          'phoneNumber': phoneNumber.trim(),
          'profilePictureUrl': '',
          'shippingAddress': '',
          'savedAddresses': <String>[],
          'createdAt': Timestamp.now(),
        });
        return null; // success
      } else {
        return "User is null after registration.";
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Unknown error: $e";
    }
  }

  /// Sign in with email & password
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Unknown error: $e";
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user's role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc['role'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;
}
