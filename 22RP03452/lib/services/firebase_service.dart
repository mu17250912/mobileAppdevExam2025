import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      UserModel userModel = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      return userCredential;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Add homework
  Future<void> addHomework({
    required String title,
    required String description,
    required String dueDate,
    required String subject,
    required String teacherId,
  }) async {
    try {
      await _firestore.collection('homework').add({
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'subject': subject,
        'teacherId': teacherId,
        'status': 'assigned',
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add homework: $e');
    }
  }

  // Get homework list
  Stream<QuerySnapshot> getHomeworkStream() {
    return _firestore
        .collection('homework')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add message
  Future<void> addMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    try {
      await _firestore.collection('messages').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  // Get messages between two users
  Stream<QuerySnapshot> getMessagesStream(String userId1, String userId2) {
    return _firestore
        .collection('messages')
        .where('senderId', whereIn: [userId1, userId2])
        .where('receiverId', whereIn: [userId1, userId2])
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Add attendance
  Future<void> addAttendance({
    required String teacherId,
    required String date,
    required List<Map<String, dynamic>> students,
  }) async {
    try {
      await _firestore.collection('attendance').add({
        'teacherId': teacherId,
        'date': date,
        'students': students,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add attendance: $e');
    }
  }

  // Get attendance for a specific date
  Future<QuerySnapshot> getAttendance(String teacherId, String date) async {
    try {
      return await _firestore
          .collection('attendance')
          .where('teacherId', isEqualTo: teacherId)
          .where('date', isEqualTo: date)
          .get();
    } catch (e) {
      throw Exception('Failed to get attendance: $e');
    }
  }
} 