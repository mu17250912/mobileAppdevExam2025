import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Check if admin user exists before trying to create
  try {
    final existingUsers = await FirebaseAuth.instance.fetchSignInMethodsForEmail('herveishimwe740@gmail.com');
    if (existingUsers.isEmpty) {
      await AuthService().createAdminUser(
        email: 'herveishimwe740@gmail.com',
        password: 'Hervinho@123',
        displayName: 'Herve Ishimwe',
      );
      print('Admin user created.');
    } else {
      print('Admin user already exists.');
    }
  } catch (e) {
    print('Admin user creation error: ' + e.toString());
  }

  runApp(const MyApp());
}
