import 'user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStore {
  static User? currentUser;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Initialize with default admin user
  static Future<void> initialize() async {
    try {
      // Always upsert the admin user (overwrite with correct credentials)
      final adminUser = User.admin(
        id: 'admin_001',
        name: 'Emmy Admin',
        email: 'emmy@gmail.com', // lowercase
        username: 'emmy_admin', // lowercase
        password: 'Emmy@#123',
        phone: '+1234567890',
      );
      await _firestore.collection('users').doc(adminUser.id).set(adminUser.toMap());
      
      // Add some sample users if they don't exist
      final sampleUsers = [
        {
          'id': 'user_001',
          'name': 'John Doe',
          'email': 'john@example.com',
          'username': 'johndoe',
          'password': 'password123',
          'phone': '+1987654321',
        },
        {
          'id': 'user_002',
          'name': 'Jane Smith',
          'email': 'jane@example.com',
          'username': 'janesmith',
          'password': 'password456',
          'phone': '+1122334455',
        },
      ];
      
      for (final userData in sampleUsers) {
        final userDoc = await _firestore.collection('users').doc(userData['id']).get();
        if (!userDoc.exists) {
          final user = User.standard(
            id: userData['id']!,
            name: userData['name']!,
            email: userData['email']!,
            username: userData['username']!,
            password: userData['password']!,
            phone: userData['phone']!,
          );
          await _firestore.collection('users').doc(user.id).set(user.toMap());
        }
      }
    } catch (e) {
      print('Error initializing users: $e');
    }
  }

  // Authentication methods
  static Future<bool> login(String email, String password) async {
    try {
      // Check Firestore for user
      QuerySnapshot querySnapshot;
      
      // First try by email
      querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // Try by username
        querySnapshot = await _firestore
            .collection('users')
            .where('username', isEqualTo: email.toLowerCase())
            .get();
      }
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Invalid credentials or user is inactive');
      }
      
      final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      final user = User.fromMap(userData);
      
      // Verify password and active status
      if (user.password != password || !user.isActive) {
        throw Exception('Invalid credentials or user is inactive');
      }
      
      // Update last login
      final updatedUser = user.copyWith(lastLogin: DateTime.now());
      await _firestore.collection('users').doc(user.id).update({
        'lastLogin': updatedUser.lastLogin?.toIso8601String(),
      });
      
      currentUser = updatedUser;
      return true;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  static void logout() {
    currentUser = null;
  }

  // User management methods
  static Stream<List<User>> getAllUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => User.fromMap(doc.data())).toList();
    });
  }

  static Stream<List<User>> getActiveUsersStream() {
    return _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => User.fromMap(doc.data())).toList();
    });
  }

  static Stream<List<User>> getUsersByRoleStream(UserRole role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role.toString())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => User.fromMap(doc.data())).toList();
    });
  }

  static Future<User?> getUserById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        return User.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  static Future<User?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return User.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  static Future<bool> createUser(User user) async {
    try {
      // Check if email or username already exists
      final existingEmail = await getUserByEmail(user.email);
      if (existingEmail != null) {
        throw Exception('Email already exists');
      }
      
      // Check username uniqueness
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: user.username.toLowerCase())
          .get();
      
      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Username already exists');
      }
      
      // Save to Firestore
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      return true;
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  static Future<bool> updateUser(User updatedUser) async {
    try {
      // Check if email is being changed and if it already exists
      final existingUser = await getUserByEmail(updatedUser.email);
      if (existingUser != null && existingUser.id != updatedUser.id) {
        throw Exception('Email already exists');
      }
      
      // Update in Firestore
      await _firestore.collection('users').doc(updatedUser.id).update(updatedUser.toMap());
      
      // Update current user if it's the same user
      if (currentUser?.id == updatedUser.id) {
        currentUser = updatedUser;
      }
      
      return true;
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  static Future<bool> deleteUser(String userId) async {
    try {
      // Prevent admin from deleting themselves
      if (currentUser?.id == userId && currentUser?.isAdmin == true) {
        throw Exception('Cannot delete your own admin account');
      }
      
      // Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  static Future<bool> deactivateUser(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }
      
      final updatedUser = user.copyWith(isActive: false);
      return await updateUser(updatedUser);
    } catch (e) {
      throw Exception('Failed to deactivate user: ${e.toString()}');
    }
  }

  static Future<bool> activateUser(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }
      
      final updatedUser = user.copyWith(isActive: true);
      return await updateUser(updatedUser);
    } catch (e) {
      throw Exception('Failed to activate user: ${e.toString()}');
    }
  }

  static Future<bool> changePassword(String userId, String newPassword) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }
      
      final updatedUser = user.copyWith(password: newPassword);
      return await updateUser(updatedUser);
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  // Statistics methods using streams
  static Stream<int> getTotalUsersCountStream() {
    return _firestore.collection('users').snapshots().map((snapshot) => snapshot.docs.length);
  }
  
  static Stream<int> getActiveUsersCountStream() {
    return _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  static Stream<int> getAdminCountStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.admin.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  static Stream<int> getStandardUsersCountStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.user.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  static Stream<List<User>> getRecentlyActiveUsersStream({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return _firestore
        .collection('users')
        .where('lastLogin', isGreaterThan: cutoffDate.toIso8601String())
        .orderBy('lastLogin', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => User.fromMap(doc.data()))
            .toList());
  }

  // Search users using Firestore
  static Stream<List<User>> searchUsersStream(String query) {
    if (query.isEmpty) {
      return getAllUsersStream();
    }
    
    final lowercaseQuery = query.toLowerCase();
    
    // Firestore doesn't support full-text search, so we'll filter client-side
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => User.fromMap(doc.data()))
          .where((user) =>
            user.name.toLowerCase().contains(lowercaseQuery) ||
            user.email.toLowerCase().contains(lowercaseQuery) ||
            user.username.toLowerCase().contains(lowercaseQuery) ||
            user.phone.contains(query)
          )
          .toList();
    });
  }

  // Validation methods
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(password);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }

  // Check if current user has admin privileges
  static bool get isCurrentUserAdmin => currentUser?.isAdmin ?? false;
  
  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;
}