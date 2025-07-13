import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create an admin user (call this once to set up your admin account)
  static Future<void> createAdminUser({
    required String email,
    required String password,
    required String fullName,
    String phone = '',
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Failed to create user');

      // Create admin user document in Firestore
      final adminUser = UserModel(
        id: user.uid,
        fullName: fullName,
        email: email,
        userType: 'commissioner',
        role: 'admin',
        phone: phone,
        favorites: [],
        savedSearches: [],
        preferences: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: true,
        isActive: true,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(adminUser.toFirestore());

      print('Admin user created successfully!');
      print('Email: $email');
      print('Password: $password');
      print('Role: admin');
    } catch (e) {
      print('Error creating admin user: $e');
      rethrow;
    }
  }

  // Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return false;

    final userData = doc.data() as Map<String, dynamic>;
    return userData['role'] == 'admin' || userData['userType'] == 'commissioner';
  }

  // Get admin users list
  static Stream<QuerySnapshot> getAdminUsers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .snapshots();
  }

  // Promote a user to admin
  static Future<void> promoteToAdmin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'role': 'admin',
      'userType': 'commissioner',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Demote an admin to regular user
  static Future<void> demoteFromAdmin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'role': 'user',
      'userType': 'buyer',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
} 