import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import '../models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;
  String _selectedRole = 'user';
  final List<String> _roles = ['user', 'chef'];

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final role = _selectedRole;

    try {
      UserCredential userCredential;
      if (_isLogin) {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Save additional user info (like name and role) to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'name': name,
          'email': email,
          'role': role,
        });
      }

      // Fetch user role from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userRole = userData != null && userData['role'] != null ? userData['role'] as String : 'user';

      if (mounted) {
        setState(() => _isLoading = false);
        final appUser = AppUser.fromFirebaseUserAndData(userCredential.user!, userData);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(currentUser: appUser),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      setState(() {
        _isLoading = false;
        _error = 'Code: ${e.code}\nMessage: ${e.message ?? "No message"}';
      });
    } catch (e) {
      print('Unknown error: ${e.toString()}');
      setState(() {
        _isLoading = false;
        _error = 'Unknown error: ${e.toString()}';
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      GoogleSignIn googleSignIn;
      if (kIsWeb) {
        googleSignIn = GoogleSignIn(
          clientId: '752140122484-0pr5l63seelcllmhpn3cl41oisphtfcu.apps.googleusercontent.com', // <-- Replace with your actual Web client ID from Firebase Console
        );
      } else {
        googleSignIn = GoogleSignIn();
      }
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }
      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      // Check if user exists in Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        // New user, add to Firestore with default role 'user'
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'role': 'user',
        });
      }
      final userData = (await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get()).data();
      if (mounted) {
        setState(() => _isLoading = false);
        final appUser = AppUser.fromFirebaseUserAndData(userCredential.user!, userData);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(currentUser: appUser),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Google sign-in failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _isLogin;
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 100, height: 100),
              const SizedBox(height: 24),
              Text(
                isLogin ? 'Welcome Back' : 'Create Account',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              if (!isLogin) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter full name' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: _roles
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role[0].toUpperCase() + role.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value ?? 'user';
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter email' : null,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter password' : null,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _submit();
                          }
                        },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isLogin ? 'Login' : 'Register'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Image.asset('assets/images/google-icon.png', width: 24, height: 24),
                  label: Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _error = null;
                  });
                },
                child: Text(isLogin
                    ? "Don't have an account? Register"
                    : "Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 