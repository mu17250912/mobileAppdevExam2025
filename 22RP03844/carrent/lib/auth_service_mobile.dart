import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn();

Future<UserCredential?> signInWithGoogleMobile() async {
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  if (googleUser == null) return null;
  
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    idToken: googleAuth.idToken,
  );
  
  return await FirebaseAuth.instance.signInWithCredential(credential);
}

Future<void> signOutMobile() async {
  await _googleSignIn.signOut();
} 