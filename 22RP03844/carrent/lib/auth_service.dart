import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

// Conditional imports for mobile-only Google Sign In
import 'auth_service_mobile.dart' if (dart.library.html) 'auth_service_web.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      // Web implementation
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      return await _auth.signInWithPopup(provider);
    } else {
      // Mobile implementation
      return await signInWithGoogleMobile();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await signOutMobile();
    }
  }
} 