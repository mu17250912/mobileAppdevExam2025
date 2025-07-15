import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class TestUserCreator {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a test user with both Firebase Auth and Firestore document
  static Future<void> createTestUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserType userType,
    String? vehicleType,
    String? vehicleNumber,
    String? licenseNumber,
  }) async {
    try {
      // Check if user already exists in Firebase Auth
      try {
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        await _auth.signOut();
        print('User already exists in Firebase Auth: $email');
      } catch (e) {
        // User doesn't exist, create new one
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('Created Firebase Auth user: ${userCredential.user?.uid}');
      }

      // Check if user document exists in Firestore
      final user = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final docRef = _firestore.collection('users').doc(user.user!.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        print('User document already exists in Firestore: ${user.user!.uid}');
        await _auth.signOut();
        return;
      }

      // Create user model
      final userModel = UserModel(
        id: user.user!.uid,
        name: name,
        email: email,
        phone: phone,
        userType: userType,
        isVerified: false,
        rating: null,
        totalRides: 0,
        completedRides: 0,
        isPremium: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActive: DateTime.now(),
        preferences: const {},
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        licenseNumber: licenseNumber,
      );

      // Save to Firestore
      await docRef.set(userModel.toMap());
      print('Created Firestore document for user: ${user.user!.uid}');

      await _auth.signOut();
      print('Test user created successfully: $email');
    } catch (e) {
      print('Error creating test user: $e');
      rethrow;
    }
  }

  /// Create all test users
  static Future<void> createAllTestUsers() async {
    try {
      // Create admin user
      await createTestUser(
        email: 'admin@gmail.com',
        password: 'admin123',
        name: 'Admin User',
        phone: '+1234567890',
        userType: UserType.admin,
      );

      // Create passenger user
      await createTestUser(
        email: 'passenger@gmail.com',
        password: 'passenger123',
        name: 'John Passenger',
        phone: '+1234567891',
        userType: UserType.passenger,
      );

      // Create driver user
      await createTestUser(
        email: 'driver@gmail.com',
        password: 'driver123',
        name: 'Jane Driver',
        phone: '+1234567892',
        userType: UserType.driver,
        vehicleType: 'Sedan',
        vehicleNumber: 'ABC123',
        licenseNumber: 'DL123456',
      );

      print('All test users created successfully!');
    } catch (e) {
      print('Error creating test users: $e');
    }
  }
}
