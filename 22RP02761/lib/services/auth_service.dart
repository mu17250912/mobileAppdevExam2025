import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user exists in Firestore database
  Future<bool> isUserRegistered(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user registration: $e');
      return false;
    }
  }

  // Validate login credentials
  Future<Map<String, dynamic>?> validateLogin(String email, String password) async {
    try {
      // First check if user exists in Firestore
      final isRegistered = await isUserRegistered(email);
      if (!isRegistered) {
        return null; // User not registered
      }

      // Try to sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Get user profile from Firestore
        final userProfile = await getUserProfile(userCredential.user!.uid);
        return userProfile;
      }
      return null;
    } catch (e) {
      print('Login validation error: $e');
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // User cancelled sign-in

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  // Validate Google sign-in user
  Future<Map<String, dynamic>?> validateGoogleSignIn() async {
    try {
      final user = await signInWithGoogle();
      if (user != null) {
        // Check if user exists in Firestore
        final isRegistered = await isUserRegistered(user.email ?? '');
        if (isRegistered) {
          return await getUserProfile(user.uid);
        } else {
          // User not registered, sign them out
          await signOut();
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Google sign-in validation error: $e');
      return null;
    }
  }

  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'role': role,
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return user;
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> createUserProfile(String uid, String email, String role) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'role': role,
      'firstName': '',
      'lastName': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      // Ignore if not signed in with Google
    }
  }

  Future<bool> isPremium(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null && data.containsKey('premium')) {
      return data['premium'] == true;
    }
    return false;
  }

  Future<void> setPremium(String uid, bool value) async {
    await _firestore.collection('users').doc(uid).update({'premium': value});
  }
}
