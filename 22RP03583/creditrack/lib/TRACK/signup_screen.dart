import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() { _isLoading = true; });
    
    // Validate inputs
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty || _usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      setState(() { _isLoading = false; });
      return;
    }
    
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 6 characters')),
      );
      setState(() { _isLoading = false; });
      return;
    }
    
    try {
      print('Attempting to create user with email: ${_emailController.text.trim()}');
      
      // Check if Firebase Auth is available
      if (FirebaseAuth.instance == null) {
        throw Exception('Firebase Auth is not initialized');
      }
      
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Set displayName to username
      await userCredential.user?.updateDisplayName(_usernameController.text.trim());

      print('User created successfully: ${userCredential.user?.uid}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully! Please sign in.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear the form
      _emailController.clear();
      _passwordController.clear();
      _usernameController.clear();
      
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Sign up error: $e');
      
      String errorMessage = 'Sign up failed';
      
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered. Please sign in instead.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak. Please choose a stronger password.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('configuration')) {
        errorMessage = 'Firebase configuration error. Please contact support.';
      } else {
        errorMessage = 'Sign up failed: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7B8AFF),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Text('CT', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                SizedBox(height: 16),
                Text('CreditTrack', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Create your account', style: TextStyle(fontSize: 14, color: Colors.white)),
                SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Username',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Email Address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF7B8AFF),
                    minimumSize: Size(double.infinity, 48),
                  ),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Sign up'),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    "Already have an account? Sign in",
                    style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 