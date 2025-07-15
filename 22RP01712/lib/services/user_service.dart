import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';
import 'dart:convert';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  // Fetch current user's profile
  Future<AppUser?> getCurrentUserProfile() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data() as Map<String, dynamic>;
      return _createUserFromMap(data, currentUser.uid);
    } catch (e) {
      print('Error fetching current user profile: $e');
      return null;
    }
  }

  // Fetch all user profiles (for admin purposes)
  Future<List<AppUser>> getAllUserProfiles() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      final List<AppUser> users = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final user = _createUserFromMap(data, doc.id);
        if (user != null) {
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      print('Error fetching all user profiles: $e');
      return [];
    }
  }

  // Fetch user profile by ID
  Future<AppUser?> getUserProfileById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data() as Map<String, dynamic>;
      return _createUserFromMap(data, userId);
    } catch (e) {
      print('Error fetching user profile by ID: $e');
      return null;
    }
  }

  // Fetch user profiles with pagination
  Future<List<AppUser>> getUserProfilesWithPagination({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection('users').limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      final List<AppUser> users = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final user = _createUserFromMap(data, doc.id);
        if (user != null) {
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      print('Error fetching user profiles with pagination: $e');
      return [];
    }
  }

  // Search users by name or email
  Future<List<AppUser>> searchUsers(String searchTerm) async {
    try {
      // Search by full name (case-insensitive)
      final nameQuery = await _firestore
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: searchTerm)
          .where('fullName', isLessThan: searchTerm + '\uf8ff')
          .get();

      // Search by email (case-insensitive)
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: searchTerm)
          .where('email', isLessThan: searchTerm + '\uf8ff')
          .get();

      final Set<String> processedIds = <String>{};
      final List<AppUser> users = [];

      // Process name results
      for (var doc in nameQuery.docs) {
        if (!processedIds.contains(doc.id)) {
          processedIds.add(doc.id);
          final data = doc.data() as Map<String, dynamic>;
          final user = _createUserFromMap(data, doc.id);
          if (user != null) {
            users.add(user);
          }
        }
      }

      // Process email results
      for (var doc in emailQuery.docs) {
        if (!processedIds.contains(doc.id)) {
          processedIds.add(doc.id);
          final data = doc.data() as Map<String, dynamic>;
          final user = _createUserFromMap(data, doc.id);
          if (user != null) {
            users.add(user);
          }
        }
      }

      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      final totalUsers = querySnapshot.docs.length;
      
      int usersWithCV = 0;
      int usersWithExperience = 0;
      int usersWithDegrees = 0;
      int usersWithCertificates = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['cvUrl'] != null && data['cvUrl'].toString().isNotEmpty) {
          usersWithCV++;
        }
        
        if (data['experiences'] != null) {
          final experiences = data['experiences'] as List?;
          if (experiences != null && experiences.isNotEmpty) {
            usersWithExperience++;
          }
        }
        
        if (data['degrees'] != null) {
          final degrees = data['degrees'] as List?;
          if (degrees != null && degrees.isNotEmpty) {
            usersWithDegrees++;
          }
        }
        
        if (data['certificates'] != null) {
          final certificates = data['certificates'] as List?;
          if (certificates != null && certificates.isNotEmpty) {
            usersWithCertificates++;
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'usersWithCV': usersWithCV,
        'usersWithExperience': usersWithExperience,
        'usersWithDegrees': usersWithDegrees,
        'usersWithCertificates': usersWithCertificates,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {};
    }
  }

  // Helper method to create AppUser object from Firestore data
  AppUser? _createUserFromMap(Map<String, dynamic> data, String userId) {
    try {
      return AppUser(
        id: userId,
        idNumber: data['idNumber'] ?? '',
        fullName: data['fullName'] ?? '',
        telephone: data['telephone'] ?? '',
        email: data['email'] ?? '',
        password: '', // Don't include password for security
        cvUrl: data['cvUrl'],
        experiences: (data['experiences'] != null)
            ? (data['experiences'] as List)
                .map((e) => Experience.fromMap(Map<String, dynamic>.from(e)))
                .toList()
            : [],
        degrees: (data['degrees'] != null)
            ? List<String>.from(data['degrees'])
            : [],
        certificates: (data['certificates'] != null)
            ? List<String>.from(data['certificates'])
            : [],
        documents: (data['documents'] != null)
            ? (data['documents'] as List)
                .map((d) => UserDocument.fromMap(Map<String, dynamic>.from(d)))
                .toList()
            : [],
      );
    } catch (e) {
      print('Error creating user from map: $e');
      return null;
    }
  }

  // Add a document to user's documents list
  Future<bool> addUserDocument(String userId, UserDocument document) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      final data = userDoc.data() as Map<String, dynamic>;
      final List<dynamic> docs = (data['documents'] ?? []);
      docs.add(document.toMap());
      await _firestore.collection('users').doc(userId).update({'documents': docs});
      return true;
    } catch (e) {
      print('Error adding user document: $e');
      return false;
    }
  }

  // Remove a document from user's documents list by URL
  Future<bool> removeUserDocument(String userId, String documentUrl) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      final data = userDoc.data() as Map<String, dynamic>;
      final List<dynamic> docs = (data['documents'] ?? []);
      docs.removeWhere((d) => d['url'] == documentUrl);
      await _firestore.collection('users').doc(userId).update({'documents': docs});
      return true;
    } catch (e) {
      print('Error removing user document: $e');
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(userId).update(updates);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Delete user profile
  Future<bool> deleteUserProfile(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      print('Error deleting user profile: $e');
      return false;
    }
  }
} 