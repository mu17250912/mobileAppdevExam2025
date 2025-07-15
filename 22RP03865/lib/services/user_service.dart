import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static const String _usersCollection = 'users';
  
  /// Get user data from Firestore by email
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection(_usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }
  
  /// Create a new user in Firestore
  static Future<void> createUser({
    required String name,
    required String email,
    required String role,
    String? phone,
    bool isGoogleSignIn = false,
    String? passwordHash,
  }) async {
    try {
      final userData = {
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'googleSignIn': isGoogleSignIn,
      };
      
      // Add password hash only for manual sign-ups
      if (passwordHash != null) {
        userData['passwordHash'] = passwordHash;
      }
      
      await FirebaseFirestore.instance.collection(_usersCollection).add(userData);
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }
  
  /// Check if user exists and get their role
  static Future<String?> getUserRole(String email) async {
    try {
      final userData = await getUserByEmail(email);
      return userData?['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
  
  /// Handle Google Sign-In user creation/checking
  static Future<void> handleGoogleSignIn(User user) async {
    try {
      // Check if user already exists
      final existingUser = await getUserByEmail(user.email!);
      
      if (existingUser == null) {
        // Create new user with "user" role
        await createUser(
          name: user.displayName ?? 'Google User',
          email: user.email!,
          role: 'user', // Google users always get "user" role
          phone: user.phoneNumber,
          isGoogleSignIn: true,
        );
      }
    } catch (e) {
      print('Error handling Google sign-in: $e');
      rethrow;
    }
  }
  
  /// Get the appropriate route based on user role
  static String getRouteForRole(String? role) {
    switch (role) {
      case 'admin':
        return '/admin-dashboard';
      case 'user':
      default:
        return '/home';
    }
  }
  
  /// Get welcome message based on user role
  static String getWelcomeMessage(String? role) {
    switch (role) {
      case 'admin':
        return 'Welcome Admin!';
      case 'user':
      default:
        return 'Welcome User!';
    }
  }
} 