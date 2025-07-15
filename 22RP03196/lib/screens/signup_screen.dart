import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:async';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} *');
    return emailRegex.hasMatch(email);
  }

  String _friendlyFirebaseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('invalid-email')) return 'The email address is badly formatted.';
    if (msg.contains('email-already-in-use')) return 'This email is already in use.';
    if (msg.contains('weak-password')) return 'The password is too weak.';
    return 'Sign up failed. Please check your details.';
  }

  Future<void> _signup() async {
    setState(() { _loading = true; _error = null; });
    String email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() {
        _error = 'Please enter a valid email address.';
        _loading = false;
      });
      return;
    }
    final start = DateTime.now();
    try {
      await AuthService().registerWithEmail(
        email,
        _passwordController.text,
        name: _nameController.text,
      );
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final minDuration = 3000;
      if (elapsed < minDuration) {
        await Future.delayed(Duration(milliseconds: minDuration - elapsed));
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = _friendlyFirebaseError(e); });
      }
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, color: Colors.white, size: 70),
              SizedBox(height: 18),
              Text('FITINITY', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 2)),
              SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                ),
              ),
              SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                ),
              ),
              SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                ),
              ),
              SizedBox(height: 18),
              if (_error != null) Text(_error!, style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF22A6F2),
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: TextStyle(fontSize: 18),
                  elevation: 2,
                ),
                child: _loading ? CircularProgressIndicator() : Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 18),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: Text('Already have an account? Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 