import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Registers a new user with email and password, then stores their role.
  Future<(UserCredential?, String?)> registerWithEmail(
    String email,
    String password,
    String role,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': email,
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });

      return (userCredential, null);
    } on FirebaseAuthException catch (e) {
      return (null, e.message);
    } catch (e) {
      return (null, 'Something went wrong: $e');
    }
  }

  /// Logs in a user with email and password.
  Future<(UserCredential?, String?)> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return (userCredential, null);
    } on FirebaseAuthException catch (e) {
      return (null, e.message);
    } catch (e) {
      return (null, 'Something went wrong: $e');
    }
  }

  /// Signs in a user using Google Sign-In
  Future<(UserCredential?, String?)> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return (null, "Google sign-in cancelled");

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Check if user record exists in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        // Add default 'buyer' role for new Google users
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'email': userCredential.user!.email,
              'role': 'buyer',
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      return (userCredential, null);
    } catch (e) {
      return (null, 'Google Sign-In error: $e');
    }
  }

  /// Retrieves the user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) return null;

      return doc.data()?['role'] as String?;
    } catch (e) {
      return null;
    }
  }
}
