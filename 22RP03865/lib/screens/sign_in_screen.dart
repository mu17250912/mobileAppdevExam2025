import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/user_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String? _errorMessage;
  bool _isLoading = false;

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }



  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
    });
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: _email)
            .limit(1)
            .get();
        if (query.docs.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No user found with this email.';
          });
          return;
        }
        final userData = query.docs.first.data();
        final storedHash = userData['passwordHash'] as String?;
        if (storedHash == null || storedHash != hashPassword(_password)) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Incorrect password.';
          });
          return;
        }
        
        // Check user role and route accordingly
        final userRole = userData['role'] as String? ?? 'user';
        setState(() {
          _isLoading = false;
        });
        
        final route = UserService.getRouteForRole(userRole);
        final welcomeMessage = UserService.getWelcomeMessage(userRole);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign In Successful'),
            content: Text(welcomeMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, route);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign in failed: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => _email = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onChanged: (value) => _password = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Sign In'),
                      ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.account_circle, color: Colors.redAccent),
                  label: Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: Size(double.infinity, 48),
                    side: BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: () async {
                    try {
                      // Use Firebase Auth's Google sign-in for both web and mobile
                      // This approach works consistently across platforms
                      final provider = GoogleAuthProvider();
                      
                      UserCredential? userCredential;
                      if (kIsWeb) {
                        // Web: use signInWithPopup
                        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
                      } else {
                        // Mobile: try popup first, fallback to redirect
                        try {
                          userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
                        } catch (popupError) {
                          // If popup fails, try redirect
                          await FirebaseAuth.instance.signInWithRedirect(provider);
                          // Note: With redirect, we need to handle the result differently
                          // For now, we'll assume success and check auth state
                          userCredential = null;
                        }
                      }
                      
                      if (userCredential != null) {
                        // Handle Google sign-in user creation/checking
                        await UserService.handleGoogleSignIn(userCredential.user!);
                        
                        // Route to user home (Google users are always "user" role)
                        Navigator.pushReplacementNamed(context, '/home');
                      } else {
                        // Handle redirect case - check current auth state
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          // Handle Google sign-in user creation/checking
                          await UserService.handleGoogleSignIn(currentUser);
                          
                          // Route to user home (Google users are always "user" role)
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      }
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Google Sign-In Failed'),
                          content: Text('Error: ${e.toString()}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/sign-up');
                      },
                      child: const Text('Sign Up'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/password-reset');
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 