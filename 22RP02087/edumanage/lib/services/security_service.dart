import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SecurityService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Rate limiting
  static final Map<String, List<DateTime>> _requestHistory = {};
  static const int maxRequests = 100; // requests per hour
  static const Duration window = Duration(hours: 1);

  // Secure authentication with error handling
  static Future<UserCredential> signInWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      // Validate inputs
      final emailError = InputValidator.validateEmail(email);
      if (emailError != null) throw Exception(emailError);
      
      final passwordError = InputValidator.validatePassword(password);
      if (passwordError != null) throw Exception(passwordError);

      // Check rate limiting
      if (!_canMakeRequest(email)) {
        throw Exception('Too many login attempts. Please try again later.');
      }

      final result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  // Secure Google OAuth
  static Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');
      
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final result = await _auth.signInWithCredential(credential);
      
      return result;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Secure registration
  static Future<UserCredential> createUserWithEmailAndPassword(
    String email, 
    String password,
    String displayName,
  ) async {
    try {
      // Validate inputs
      final emailError = InputValidator.validateEmail(email);
      if (emailError != null) throw Exception(emailError);
      
      final passwordError = InputValidator.validatePassword(password);
      if (passwordError != null) throw Exception(passwordError);

      // Check rate limiting
      if (!_canMakeRequest(email)) {
        throw Exception('Too many registration attempts. Please try again later.');
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // Update user profile
      await result.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isPremium': false,
        'role': 'teacher',
      });

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  // Secure logout
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
    } catch (e) {
      rethrow;
    }
  }

  // Rate limiting check
  static bool _canMakeRequest(String identifier) {
    final now = DateTime.now();
    final userRequests = _requestHistory[identifier] ?? [];
    
    // Remove old requests outside the window
    userRequests.removeWhere((time) => now.difference(time) > window);
    
    if (userRequests.length >= maxRequests) {
      return false;
    }
    
    userRequests.add(now);
    _requestHistory[identifier] = userRequests;
    return true;
  }

  // Handle Firebase Auth exceptions
  static Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email address.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return Exception('An account with this email already exists.');
      case 'weak-password':
        return Exception('Password is too weak. Please choose a stronger password.');
      case 'invalid-email':
        return Exception('Invalid email address format.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please try again later.');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }

  // Check if user is authenticated
  static bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Check if user email is verified
  static bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      final emailError = InputValidator.validateEmail(email);
      if (emailError != null) throw Exception(emailError);

      await _auth.sendPasswordResetEmail(email: email);
      
    } catch (e) {
      rethrow;
    }
  }

  // Update password
  static Future<void> updatePassword(String newPassword) async {
    try {
      final passwordError = InputValidator.validatePassword(newPassword);
      if (passwordError != null) throw Exception(passwordError);

      await _auth.currentUser?.updatePassword(newPassword);
      
    } catch (e) {
      rethrow;
    }
  }

  // Delete user account
  static Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore first
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete user authentication
        await user.delete();
        
      }
    } catch (e) {
      rethrow;
    }
  }

  // Session management
  static Future<void> refreshUserSession() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      rethrow;
    }
  }

  // Check if user has required permissions
  static Future<bool> hasPermission(String permission) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      final role = userData?['role'] ?? 'user';

      // Define permission matrix
      final permissions = {
        'admin': ['read', 'write', 'delete', 'manage_users'],
        'teacher': ['read', 'write'],
        'student': ['read'],
      };

      return permissions[role]?.contains(permission) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Audit logging
  static Future<void> logSecurityEvent(String event, Map<String, dynamic>? details) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('security_audit').add({
        'userId': user?.uid,
        'userEmail': user?.email,
        'event': event,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'client_ip', // Would be implemented with actual IP detection
        'userAgent': 'client_user_agent', // Would be implemented with actual UA detection
      });

    } catch (e) {
      // Don't throw here to avoid breaking the main flow
      print('Failed to log security event: $e');
    }
  }
}

// Input validation class
class InputValidator {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    // Email regex validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    // Prevent SQL injection and XSS
    if (email.contains('<script>') || email.contains('javascript:')) {
      return 'Invalid email format';
    }
    
    return null;
  }
  
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for strong password requirements
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (!hasUppercase || !hasLowercase || !hasDigits || !hasSpecialCharacters) {
      return 'Password must contain uppercase, lowercase, digit, and special character';
    }
    
    return null;
  }
  
  static String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }
} 