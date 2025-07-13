import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;

  User? get user => _user;
  set user(User? value) {
    _user = value;
    notifyListeners();
  }

  AuthProvider() {
    _auth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        // Fetch user info from Firestore
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _user = User(
            id: firebaseUser.uid,
            name: data['name'] ?? firebaseUser.displayName ?? 'User',
            phone: data['phone'] ?? firebaseUser.phoneNumber ?? '',
            location: data['location'] ?? '',
            role: data['role'] == 'farmer' ? UserRole.farmer : UserRole.buyer,
            isPremium: data['isPremium'] ?? false, // <-- Add this
          );
        } else {
          // fallback if no Firestore doc
          _user = User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            phone: firebaseUser.phoneNumber ?? '',
            location: '',
            role: UserRole.buyer,
            isPremium: false, // <-- Default to false
          );
        }
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw e;
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name, UserRole role) async {
    try {
      firebase_auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.updateDisplayName(name);
      // Save user info to Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'phone': '',
        'location': '',
        'role': role == UserRole.farmer ? 'farmer' : 'buyer',
        'isPremium': false, // <-- Default to false
      });
      _user = User(
        id: result.user!.uid,
        name: name,
        phone: '',
        location: '',
        role: role,
        isPremium: false, // <-- Default to false
      );
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  /// Signs in the user using Google Sign-In
  /// 
  /// This method handles the complete Google Sign-In flow:
  /// 1. Opens Google Sign-In dialog
  /// 2. Authenticates with Firebase using Google credentials
  /// 3. Creates or updates user profile in Firestore
  /// 4. Sets the user role (buyer or farmer)
  /// 
  /// [role] - The user role to assign (buyer or farmer)
  /// 
  /// Throws exceptions for various error scenarios:
  /// - Network errors
  /// - Sign-in cancellation
  /// - Authentication failures
  Future<void> signInWithGoogle(UserRole role) async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase_auth.UserCredential result = await _auth.signInWithCredential(credential);
      
      // Check if user already exists in Firestore
      final doc = await _firestore.collection('users').doc(result.user!.uid).get();
      
      if (!doc.exists) {
        // New user - save to Firestore
        await _firestore.collection('users').doc(result.user!.uid).set({
          'name': result.user!.displayName ?? 'User',
          'phone': result.user!.phoneNumber ?? '',
          'location': '',
          'role': role == UserRole.farmer ? 'farmer' : 'buyer',
          'isPremium': false,
          'email': result.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // User will be set automatically by the authStateChanges listener
    } catch (e) {
      // Handle specific Google Sign-In errors
      if (e.toString().contains('network_error')) {
        throw Exception('Network error. Please check your internet connection.');
      } else if (e.toString().contains('sign_in_canceled')) {
        throw Exception('Sign in was cancelled.');
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception('Sign in failed. Please try again.');
      } else {
        throw Exception('Google sign in failed: ${e.toString()}');
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> updateProfile({String? name, String? phone, String? location}) async {
    if (_user == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (location != null) updates['location'] = location;
    await _firestore.collection('users').doc(_user!.id).update(updates);
    _user = User(
      id: _user!.id,
      name: name ?? _user!.name,
      phone: phone ?? _user!.phone,
      location: location ?? _user!.location,
      role: _user!.role,
      isPremium: _user!.isPremium,
    );
    notifyListeners();
  }
}
