import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'lib/models/task.dart';

// Simple test script to verify Firebase integration
// Run this with: dart test_firebase_integration.dart

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Firebase initialized successfully');

  // Test Firebase connectivity
  await testFirebaseConnectivity();
  
  // Test task operations
  await testTaskOperations();
}

Future<void> testFirebaseConnectivity() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    print('Testing Firebase connectivity...');
    
    // Test if we can connect to Firestore
    await firestore.collection('test').doc('connection_test').get();
    print('✓ Firestore connection successful');
    
    // Test authentication state
    final user = auth.currentUser;
    if (user != null) {
      print('✓ User is authenticated: ${user.email}');
    } else {
      print('⚠ No user is currently authenticated');
    }
    
  } catch (e) {
    print('✗ Firebase connectivity test failed: $e');
  }
}

Future<void> testTaskOperations() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    final user = auth.currentUser;
    if (user == null) {
      print('⚠ Skipping task operations test - no authenticated user');
      return;
    }
    
    print('Testing task operations...');
    
    // Create a test task
    final testTask = Task(
      subject: 'Test Task',
      notes: 'This is a test task for Firebase integration',
      dateTime: DateTime.now().add(Duration(hours: 1)),
      duration: 30,
      isCompleted: false,
    );
    
    // Add task to Firebase
    final taskData = testTask.toMap();
    final docRef = await firestore
        .collection('tasks')
        .doc(user.uid)
        .collection('userTasks')
        .add(taskData);
    
    print('✓ Task added to Firebase with ID: ${docRef.id}');
    
    // Read task from Firebase
    final doc = await firestore
        .collection('tasks')
        .doc(user.uid)
        .collection('userTasks')
        .doc(docRef.id)
        .get();
    
    if (doc.exists) {
      final retrievedTask = Task.fromMap(doc.data()!, doc.id);
      print('✓ Task retrieved from Firebase: ${retrievedTask.subject}');
    } else {
      print('✗ Task not found in Firebase');
    }
    
    // Update task
    await firestore
        .collection('tasks')
        .doc(user.uid)
        .collection('userTasks')
        .doc(docRef.id)
        .update({'isCompleted': true});
    
    print('✓ Task updated in Firebase');
    
    // Delete test task
    await firestore
        .collection('tasks')
        .doc(user.uid)
        .collection('userTasks')
        .doc(docRef.id)
        .delete();
    
    print('✓ Task deleted from Firebase');
    print('✓ All task operations completed successfully');
    
  } catch (e) {
    print('✗ Task operations test failed: $e');
  }
} 