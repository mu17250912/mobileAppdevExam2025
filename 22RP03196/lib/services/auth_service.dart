import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create user object from Firebase User
  AppUser? _userFromFirebase(User? user, Map<String, dynamic>? data) {
    if (user == null) return null;
    return AppUser.fromMap(data ?? {}, user.uid);
  }

  // Auth change user stream
  Stream<AppUser?> get user {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _db.collection('users').doc(user.uid).get();
      return _userFromFirebase(user, doc.data());
    });
  }

  // Sign in with email & password
  Future<AppUser?> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final doc = await _db.collection('users').doc(result.user!.uid).get();
    return _userFromFirebase(result.user, doc.data());
  }

  // Register with email & password
  Future<AppUser?> registerWithEmail(String email, String password, {String? name, String role = 'user'}) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = AppUser(uid: result.user!.uid, email: email, name: name, role: role);
    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  // Google sign-in (web and mobile)
  Future<AppUser?> signInWithGoogle() async {
    UserCredential result;
    if (kIsWeb) {
      // Web: Use signInWithPopup
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      result = await _auth.signInWithPopup(googleProvider);
    } else {
      // Mobile: Use google_sign_in
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      result = await _auth.signInWithCredential(credential);
    }
    final doc = await _db.collection('users').doc(result.user!.uid).get();
    if (!doc.exists) {
      final user = AppUser(uid: result.user!.uid, email: result.user!.email ?? '', name: result.user!.displayName, role: 'user');
      await _db.collection('users').doc(user.uid).set(user.toMap());
      return user;
    }
    return _userFromFirebase(result.user, doc.data());
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    // if (!kIsWeb) {
    //   final GoogleSignIn googleSignIn = GoogleSignIn();
    //   await googleSignIn.signOut();
    // }
  }

  // Get current user role
  Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['role'];
  }

  Future<void> upgradeToPremium() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();
    if (doc.exists) {
      await userRef.update({'isPremium': true});
    } else {
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'isPremium': true,
      });
    }
  }
} 