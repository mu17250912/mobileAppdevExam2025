import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class HomeScreen extends StatelessWidget {
  final User? user;
  final Map<String, dynamic>? userData;
  const HomeScreen({super.key, this.user, this.userData});

  @override
  Widget build(BuildContext ctx) {
    final displayName = userData?['name'] ?? user?.displayName ?? 'User';
    final email = userData?['email'] ?? user?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user?.photoURL != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user!.photoURL!),
              ),
            const SizedBox(height: 16),
            Text('Hello, $displayName'),
            Text(email),
          ],
        ),
      ),
    );
  }
} 