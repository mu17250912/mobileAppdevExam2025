import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  // Save or update user profile
  Future<void> setUserProfile(Map<String, dynamic> profileData) async {
    await _firestore.collection('users').doc(userId).set(profileData, SetOptions(merge: true));
  }

  // Get user profile
  Future<DocumentSnapshot> getUserProfile() async {
    return await _firestore.collection('users').doc(userId).get();
  }
} 