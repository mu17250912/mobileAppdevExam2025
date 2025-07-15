import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'commission_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'sign_in_screen.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _successMessage;

  Future<void> _registerOrganizer() async {
    setState(() {
      _loading = true;
      _successMessage = null;
    });
    try {
      final email = _emailController.text.trim();
      final displayName = _displayNameController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isEmpty || displayName.isEmpty || password.isEmpty) {
        throw Exception('All fields are required');
      }
      // Use a secondary Firebase app instance to avoid logging out the admin
      final FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
      final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      try {
        // Try to create organizer in Firebase Auth and get UID
        final cred = await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Use UID as document ID in Firestore
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'role': 'organizer',
          'email': email,
          'displayName': displayName,
        });
        setState(() {
          _successMessage = 'Organizer registered!\nEmail: $email\nPassword: $password';
          _emailController.clear();
          _displayNameController.clear();
          _passwordController.clear();
        });
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Find the existing user by email
          final userQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
          if (userQuery.docs.isNotEmpty) {
            final docId = userQuery.docs.first.id;
            await FirebaseFirestore.instance.collection('users').doc(docId).set({
              'role': 'organizer',
              'displayName': displayName,
            }, SetOptions(merge: true));
            setState(() {
              _successMessage = 'Existing user updated to organizer!';
              _emailController.clear();
              _displayNameController.clear();
              _passwordController.clear();
            });
          } else {
            // If user not found in Firestore, create a new Firestore user document
            // Find the Auth user UID by email
            final methods = await secondaryAuth.fetchSignInMethodsForEmail(email);
            // Try to get the UID from Auth (requires admin privileges in backend, but for now, create a Firestore doc with email as key)
            // In client-side, we don't have access to UID, so use email as doc ID (not ideal, but works for this case)
            await FirebaseFirestore.instance.collection('users').add({
              'role': 'organizer',
              'email': email,
              'displayName': displayName,
            });
            setState(() {
              _successMessage = 'Firestore user created and set as organizer!';
              _emailController.clear();
              _displayNameController.clear();
              _passwordController.clear();
            });
          }
        } else {
          throw e;
        }
      } finally {
        await secondaryAuth.signOut();
        await secondaryApp.delete();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home - Register Organizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await AuthService().signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Organizer Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Display Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _registerOrganizer,
                  child: _loading ? const CircularProgressIndicator() : const Text('Register Organizer'),
                ),
                if (_successMessage != null) ...[
                  const SizedBox(height: 24),
                  Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CommissionScreen()),
                    );
                  },
                  child: const Text('View Commission Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 