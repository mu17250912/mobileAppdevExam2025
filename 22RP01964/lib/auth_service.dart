import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn.instance;

  Future<UserCredential?> signUpWithGoogle({required String role}) async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        provider.setCustomParameters({'prompt': 'select_account'});
        final cred = await _auth.signInWithPopup(provider);
        await _createUserDocIfNeeded(cred.user, role: role);
        return cred;
      }
      // Always sign out first to force account picker
      await _google.signOut();
      final account = await _google.authenticate(scopeHint: ['email']);
      if (account == null) return null;
      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        // accessToken: auth.accessToken, // Not available in v7+, omit if not present
      );
      final cred = await _auth.signInWithCredential(credential);
      await _createUserDocIfNeeded(cred.user, role: role);
      return cred;
    } catch (e) {
      print('Google sign-up error: $e');
      rethrow;
    }
  }

  Future<void> _createUserDocIfNeeded(
    User? user, {
    required String role,
  }) async {
    if (user == null) return;
    try {
      final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await doc.get();
      if (!snapshot.exists) {
        await doc.set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          // Add more fields as needed (e.g., phone, etc.)
        });
        print('User document created successfully for UID: ${user.uid}');
      } else {
        print('User document already exists for UID: ${user.uid}');
      }
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) await _google.signOut();
  }
}
