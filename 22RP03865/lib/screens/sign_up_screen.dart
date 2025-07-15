import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/user_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String _confirmPassword = '';
  String? _errorMessage;
  bool _isLoading = false;

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signUp() async {
    setState(() {
      _errorMessage = null;
    });
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        await UserService.createUser(
          name: _name,
          email: _email,
          role: 'user', // Default role for manual sign-up
          phone: _phone,
          isGoogleSignIn: false,
          passwordHash: hashPassword(_password),
        );
        setState(() {
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/sign-in');
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (value) => _name = value,
                    validator: (value) => value != null && value.isNotEmpty ? null : 'Enter your name',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => _email = value,
                    validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) => _phone = value,
                    validator: (value) => value != null && value.length >= 8 ? null : 'Enter a valid phone',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onChanged: (value) => _password = value,
                    validator: (value) => value != null && value.length >= 6 ? null : 'Password too short',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                    onChanged: (value) => _confirmPassword = value,
                    validator: (value) => value == _password ? null : 'Passwords do not match',
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _signUp,
                          child: const Text('Sign Up'),
                        ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/sign-in');
                        },
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 