import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'buyer_dashboard.dart';
import 'registration_screen.dart';
import 'seller_dashboard.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // Uncomment if Google sign-in is implemented

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('LoginScreen initialized');
  }

  Future<void> _login() async {
    print('Login attempt started');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Email and password cannot be empty.';
          _isLoading = false;
        });
        return;
      }
      print('Attempting Firebase authentication...');
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Firebase auth successful, fetching user role...');
      // Fetch user role from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      final role = userDoc['role'];
      print('User role: $role');
      if (role == 'buyer') {
        print('Navigating to buyer dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BuyerDashboard()),
        );
      } else if (role == 'seller') {
        print('Navigating to seller dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SellerDashboard()),
        );
      } else {
        setState(() {
          _errorMessage = 'Unknown user role.';
        });
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase auth error: $e');
      setState(() {
        _errorMessage = e.message ?? 'Login failed.';
      });
    } catch (e) {
      print('General login error: $e');
      setState(() {
        _errorMessage = 'Login failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loginWithGoogle() async {
    // TODO: Implement Google sign-in logic
    setState(() {
      _errorMessage = 'Google sign-in not implemented.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo and App Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag, color: Colors.blue, size: 40),
                    const SizedBox(width: 8),
                    Text(
                      'BerwaStore',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Email Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                // Password Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                // OR Divider
                Row(
                  children: [
                    const Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('OR', style: TextStyle(color: Colors.grey[700])),
                    ),
                    const Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 16),
                // Google Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loginWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                // Create Account Link
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                    );
                  },
                  child: const Text(
                    'Create new account',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 