import 'package:firebase_auth/firebase_auth.dart';

// Web stub functions - these will never be called on web
// as the main AuthService handles web implementation directly
Future<UserCredential?> signInWithGoogleMobile() async {
  throw UnsupportedError('Mobile Google sign-in not supported on web');
}

Future<void> signOutMobile() async {
  // No-op on web
} 