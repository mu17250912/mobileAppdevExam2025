import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<app_user.User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required app_user.UserType userType,
    String? university,
    String? studentId,
  }) async {
    try {
      final firebase_auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final userData = {
          'id': result.user!.uid,
      'email': email,
      'name': name,
      'phone': phone,
          'userType': userType.toString().split('.').last,
      'university': university,
      'studentId': studentId,
          'isVerified': false,
          'isPremium': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(result.user!.uid).set(userData);

        return app_user.User(
          id: result.user!.uid,
      email: email,
      name: name,
      phone: phone,
      userType: userType,
      university: university,
      studentId: studentId,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
      }
      throw Exception('Unknown registration error');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception('FirebaseAuthException [${e.code}]: ${e.message ?? 'Registration failed.'}');
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<app_user.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final firebase_auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Get user data from Firestore
        final userDoc = await _firestore.collection('users').doc(result.user!.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          return app_user.User(
            id: userData['id'],
            email: userData['email'],
            name: userData['name'],
            phone: userData['phone'],
            userType: userData['userType'] == 'landlord' ? app_user.UserType.landlord : app_user.UserType.student,
            university: userData['university'],
            studentId: userData['studentId'],
            isVerified: userData['isVerified'] ?? false,
            isPremium: userData['isPremium'] ?? false,
            createdAt: (userData['createdAt'] as Timestamp).toDate(),
            lastActive: (userData['lastActive'] as Timestamp).toDate(),
          );
        }
    }
    return null;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Get current user from Firestore
  Future<app_user.User?> getCurrentUser() async {
    try {
      final firebase_auth.User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          return app_user.User(
            id: userData['id'],
            email: userData['email'],
            name: userData['name'],
            phone: userData['phone'],
            userType: userData['userType'] == 'landlord' ? app_user.UserType.landlord : app_user.UserType.student,
            university: userData['university'],
            studentId: userData['studentId'],
            isVerified: userData['isVerified'] ?? false,
            isPremium: userData['isPremium'] ?? false,
            createdAt: (userData['createdAt'] as Timestamp).toDate(),
            lastActive: (userData['lastActive'] as Timestamp).toDate(),
          );
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? profileImage,
    String? university,
    String? studentId,
  }) async {
    try {
      final firebase_auth.User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        final updateData = <String, dynamic>{};
        
        if (name != null) updateData['name'] = name;
        if (phone != null) updateData['phone'] = phone;
        if (profileImage != null) updateData['profileImage'] = profileImage;
        if (university != null) updateData['university'] = university;
        if (studentId != null) updateData['studentId'] = studentId;
        
        updateData['lastActive'] = FieldValue.serverTimestamp();
        
        await _firestore.collection('users').doc(firebaseUser.uid).update(updateData);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Get user by ID
  Future<app_user.User?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return app_user.User(
          id: userData['id'],
          email: userData['email'],
          name: userData['name'],
          phone: userData['phone'],
          userType: userData['userType'] == 'landlord' ? app_user.UserType.landlord : app_user.UserType.student,
          university: userData['university'],
          studentId: userData['studentId'],
          isVerified: userData['isVerified'] ?? false,
          isPremium: userData['isPremium'] ?? false,
          createdAt: (userData['createdAt'] as Timestamp).toDate(),
          lastActive: (userData['lastActive'] as Timestamp).toDate(),
        );
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  // Save user session (not needed with Firebase Auth, but keeping for compatibility)
  Future<void> saveUserSession(String userId) async {
    // Firebase Auth handles session management automatically
  }

  // Load user session (not needed with Firebase Auth, but keeping for compatibility)
  Future<String?> loadUserSession() async {
    return _auth.currentUser?.uid;
  }

  // Clear user session (not needed with Firebase Auth, but keeping for compatibility)
  Future<void> clearUserSession() async {
    // Firebase Auth handles session management automatically
  }
} 