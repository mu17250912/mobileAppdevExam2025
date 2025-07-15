import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart'; // Added for BuildContext

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In process...');
      
      if (kIsWeb) {
        print('Using web Google Sign-In');
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        return await _auth.signInWithPopup(provider);
      }

      print('Using mobile Google Sign-In');
      final signIn = GoogleSignIn.instance;
      
      // Configure Google Sign-In for better compatibility
      print('Signing out from any existing sessions...');
      await signIn.signOut(); // Clear any existing sessions
      
      print('Starting Google Sign-In authentication...');
      final account = await signIn.authenticate();
      if (account == null) {
        print('Google Sign-In was cancelled or failed');
        return null;
      }

      print('Google Sign-In successful, getting ID token...');
      final idToken = await account.authentication;
      if (idToken.idToken == null) {
        print('Failed to get ID token from Google Sign-In');
        return null;
      }

      print('Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        idToken: idToken.idToken,
      );

      print('Signing in to Firebase with Google credential...');
      final userCredential = await _auth.signInWithCredential(credential);

      print('Firebase sign-in successful, storing user data...');
      // Store additional user data in Firestore
      if (userCredential.user != null) {
        await _storeUserData(userCredential.user!);
      }

      print('Google Sign-In process completed successfully');
      return userCredential;
    } catch (e) {
      print('Google Sign-In Error: $e');
      print('Error type: ${e.runtimeType}');
      // Try to sign out to clear any partial state
      try {
        await GoogleSignIn.instance.signOut();
        await _auth.signOut();
      } catch (signOutError) {
        print('Error during sign out: $signOutError');
      }
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _storeUserData(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      print('Email Sign-In Error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> registerWithEmail(String email, String password, String displayName, String userType) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName);
        
        // Store user data with user type
        await _storeUserData(userCredential.user!, userType: userType);
      }
      
      return userCredential;
    } catch (e) {
      print('Email Registration Error: $e');
      rethrow;
    }
  }

  Future<void> _storeUserData(User user, {String? userType}) async {
    try {
      // Check if user already exists
      final existingDoc = await _firestore.collection('users').doc(user.uid).get();
      
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
        'creationTime': user.metadata.creationTime?.toIso8601String(),
        'isEmailVerified': user.emailVerified,
        'providerData': user.providerData.map((provider) => {
          'providerId': provider.providerId,
          'uid': provider.uid,
          'displayName': provider.displayName,
          'email': provider.email,
          'photoURL': provider.photoURL,
        }).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Only set userType if it's provided (for new users) or if user doesn't exist
      if (userType != null || !existingDoc.exists) {
        userData['userType'] = userType ?? 'Farmer'; // Default to Farmer
        userData['subscriptionPlan'] = 'Basic'; // Default subscription
      }

      await _firestore.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));
    } catch (e) {
      print('Error storing user data: $e');
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      // Only sign out from Google if the user used Google sign-in
      final user = _auth.currentUser;
      if (user != null && user.providerData.any((p) => p.providerId == 'google.com')) {
        await GoogleSignIn.instance.signOut();
      }
      await Future.delayed(const Duration(milliseconds: 200));
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> getUserType(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['userType'] ?? 'Farmer';
      }
      return 'Farmer'; // Default
    } catch (e) {
      print('Error getting user type: $e');
      return 'Farmer'; // Default
    }
  }

  Future<void> updateUserType(String uid, String userType) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'userType': userType,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating user type: $e');
    }
  }
} 