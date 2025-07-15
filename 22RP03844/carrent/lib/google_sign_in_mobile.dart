import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<UserCredential?> signInWithGoogle() async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  if (googleUser == null) return null;
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    idToken: googleAuth.idToken,
    accessToken: googleAuth.accessToken,
  );
  final userCredential = await _auth.signInWithCredential(credential);

  if (userCredential.additionalUserInfo?.isNewUser ?? false) {
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'email': userCredential.user!.email,
      'displayName': userCredential.user!.displayName,
      'photoURL': userCredential.user!.photoURL,
      'createdAt': DateTime.now().toIso8601String(),
      'role': 'user',
    });
  }
  return userCredential;
} 