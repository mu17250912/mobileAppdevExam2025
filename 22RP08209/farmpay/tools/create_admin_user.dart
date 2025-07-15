import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  // Initialize Firebase for Dart console (no WidgetsFlutterBinding)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final email = '0788145026@farmpay.com';
  final password = 'admin123';
  final name = 'MANZI';
  try {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
      'name': name,
      'phone': '0788145026',
      'role': 'admin',
      'premium_status': 'approved',
      'created_at': DateTime.now().toIso8601String(),
    });
    print('Admin user created successfully!');
  } catch (e) {
    print('Error: ' + e.toString());
  }
} 