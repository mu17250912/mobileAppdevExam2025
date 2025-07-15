import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart'; // Your custom user model
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  final void Function(User) onLogin;
  final VoidCallback onCreateAccount;

  const LoginScreen({
    Key? key,
    required this.onLogin,
    required this.onCreateAccount,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _errorMessage;

Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  _formKey.currentState!.save();
  setState(() {
    _loading = true;
    _errorMessage = null;
  });

  try {
    final credential = await fb_auth.FirebaseAuth.instance
        .signInWithEmailAndPassword(email: _email, password: _password);

      // Fetch user profile from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(_email).get();
      if (doc.exists) {
        final data = doc.data()!;
        final user = User(
          email: data['email'] ?? _email,
          householdSize: data['householdSize'] ?? 1,
          averageWaterBill: (data['averageWaterBill'] as num?)?.toDouble(),
          waterUsageGoalPercent: (data['waterUsageGoalPercent'] as num?)?.toDouble() ?? 20.0,
          usesSmartMeter: data['usesSmartMeter'] ?? false,
        );
        widget.onLogin(user);
      } else {
        // Fallback if no profile found
        final user = User(
          email: _email,
          householdSize: 1,
          averageWaterBill: null,
          waterUsageGoalPercent: 20.0,
          usesSmartMeter: false,
        );
        widget.onLogin(user);
      }
  } on fb_auth.FirebaseAuthException catch (e) {
    setState(() {
      switch (e.code) {
        case 'invalid-email':
          _errorMessage = 'The email address is badly formatted.';
          break;
        case 'user-not-found':
          _errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          _errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'user-disabled':
          _errorMessage = 'This user account has been disabled.';
          break;
        default:
          _errorMessage = 'Login failed: ${e.message}';
      }
    });
  } catch (e) {
    print('Login error: $e');
    setState(() {
      _errorMessage = 'An unexpected error occurred. Please try again later.';
    });
  } finally {
    setState(() {
      _loading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF64B5F6),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo and Name
                Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.water_drop, size: 40, color: Colors.blue.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AquaTrack',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Login Card
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email, color: Colors.blue.shade700),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value != null && value.contains('@') ? null : 'Enter a valid email',
                            onSaved: (value) => _email = value ?? '',
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            obscureText: true,
                            validator: (value) =>
                                value != null && value.length >= 6 ? null : 'Password too short',
                            onSaved: (value) => _password = value ?? '',
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                elevation: 6,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: widget.onCreateAccount,
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
