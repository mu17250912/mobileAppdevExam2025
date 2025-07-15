import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // Ensure user document exists in Firestore with correct role and info
  Future<void> ensureUserDocument(User user, {String? role}) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await doc.get();
    final data = snapshot.data();

    // Only set role if it's a new document or if the user is an admin
    Map<String, dynamic> updateData = {
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL ?? '',
    };
    if (!snapshot.exists && role != null) {
      updateData['role'] = role;
    }

    if (updateData.isNotEmpty) {
      await doc.set(updateData, SetOptions(merge: true));
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    UserCredential cred;
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      cred = await _auth.signInWithPopup(provider);
    } else {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      cred = await _auth.signInWithCredential(credential);
    }
    await ensureUserDocument(cred.user!, role: 'user');
    return cred;
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    // Only call ensureUserDocument if the document does not exist
    final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) {
      await ensureUserDocument(cred.user!, role: null); // Or pass the correct role if you know it
    }
    return cred;
  }

  Future<UserCredential?> registerWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await ensureUserDocument(cred.user!, role: 'user');
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
  }

  // Create an admin user with a specific email and password
  Future<void> createAdminUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Hash the password for storage (not recommended for production, but better than plain text)
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      // Store user in Firestore with role 'admin'
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'role': 'admin',
        'email': email,
        'displayName': displayName,
        'passwordHash': hashedPassword,
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
} 