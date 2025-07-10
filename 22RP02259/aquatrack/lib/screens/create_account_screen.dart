import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class CreateAccountScreen extends StatefulWidget {
  final VoidCallback onAccountCreated;
  final VoidCallback onBackToLogin;

  const CreateAccountScreen({
    Key? key,
    required this.onAccountCreated,
    required this.onBackToLogin,
  }) : super(key: key);

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _loading = false;
  String? _errorMessage;

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    if (_password != _confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await fb_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: _email, password: _password);

      // You can store _name to Firestore here later if needed

      widget.onAccountCreated();
    } on fb_auth.FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
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
                // Logo + App name
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
                      'AquTrack',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form card
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
                            decoration: _inputDecoration('Name', Icons.person),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Enter your name' : null,
                            onSaved: (value) => _name = value ?? '',
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: _inputDecoration('Email', Icons.email),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => (value == null || !value.contains('@'))
                                ? 'Enter a valid email'
                                : null,
                            onSaved: (value) => _email = value ?? '',
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: _inputDecoration('Password', Icons.lock),
                            obscureText: true,
                            validator: (value) => (value == null || value.length < 6)
                                ? 'Password must be at least 6 characters'
                                : null,
                            onSaved: (value) => _password = value ?? '',
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: _inputDecoration('Confirm Password', Icons.lock_outline),
                            obscureText: true,
                            validator: (value) => (value == null || value.length < 6)
                                ? 'Confirm your password'
                                : null,
                            onSaved: (value) => _confirmPassword = value ?? '',
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
                              onPressed: _loading ? null : _createAccount,
                              child: _loading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: widget.onBackToLogin,
                            child: Text(
                              'Back to Login',
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      filled: true,
      fillColor: Colors.blue.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
