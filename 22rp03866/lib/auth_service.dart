import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return await _auth.signInWithPopup(provider);
    }

    final googleUser = await _google.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);

    // Store extra info in Firestore if new user
    final user = userCredential.user;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userDoc.get();
      if (!doc.exists) {
        await userDoc.set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isAdmin': false,
        });
      } else {
        await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});
      }
    }
    return userCredential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) await _google.signOut();
  }
} 