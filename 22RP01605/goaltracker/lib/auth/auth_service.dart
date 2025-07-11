import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges {
    // No platform block; allow on web and Windows
    return _auth.authStateChanges();
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    // No platform block; allow on web and Windows
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    // No platform block; allow on web and Windows
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() async {
    // No platform block; allow on web and Windows
    await _auth.signOut();
  }
}
