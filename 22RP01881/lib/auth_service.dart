import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// import 'package:google_sign_in/google_sign_in.dart'
//     if (dart.library.html) 'src/google_sign_in_web_stub.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  // Only initialize GoogleSignIn on non-web platforms
  // final GoogleSignIn? _google = !kIsWeb ? GoogleSignIn() : null;

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final cred = await _auth.signInWithPopup(provider);
      await _createOrUpdateUserDoc(cred.user);
      return cred;
    }
    // For now, return null for mobile Google Sign In
    // TODO: Fix Google Sign In for mobile
    return null;
    // final account = await _google!.signIn();
    // if (account == null) return null;
    // final auth = await account.authentication;
    // final cred = GoogleAuthProvider.credential(
    //   idToken: auth.idToken,
    //   accessToken: auth.accessToken,
    // );
    // final userCred = await _auth.signInWithCredential(cred);
    // await _createOrUpdateUserDoc(userCred.user);
    // return userCred;
  }

  Future<void> _createOrUpdateUserDoc(User? user) async {
    if (user == null) return;
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await doc.set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastSignIn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // if (!kIsWeb) await _google?.signOut();
  }
} 