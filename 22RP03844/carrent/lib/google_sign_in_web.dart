import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<UserCredential?> signInWithGoogle() async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GoogleAuthProvider googleProvider = GoogleAuthProvider();
  googleProvider.setCustomParameters({'login_hint': 'user@example.com'});
  final userCredential = await _auth.signInWithPopup(googleProvider);

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