import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';

class RoleSelectionScreen extends StatelessWidget {
  final User user;
  const RoleSelectionScreen({super.key, required this.user});

  void _selectRole(BuildContext context, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'role': role,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
    }, SetOptions(merge: true));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Role')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _selectRole(context, 'user'),
              child: const Text('User'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _selectRole(context, 'organizer'),
              child: const Text('Event Organizer'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _selectRole(context, 'admin'),
              child: const Text('Admin'),
            ),
          ],
        ),
      ),
    );
  }
} 