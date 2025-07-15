import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  final _users = FirebaseFirestore.instance.collection('users');

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.id, doc.data()!);
  }

  // Add more methods as needed
} 