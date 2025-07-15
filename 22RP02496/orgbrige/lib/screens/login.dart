import 'package:flutter/material.dart';
import 'register.dart';
import 'manager_dashboard.dart';
import 'employee_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final managerDoc = await FirebaseFirestore.instance.collection('managers').doc(credential.user!.uid).get();
      if (managerDoc.exists) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ManagerDashboard()),
          );
        }
      } else {
        final employeeDoc = await FirebaseFirestore.instance.collection('employees').doc(credential.user!.uid).get();
        if (employeeDoc.exists) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const EmployeeDashboard()),
            );
          }
        } else {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No account found for this user.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Login failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email is required';
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');
                        if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
                    ),
                    const SizedBox(height: 36),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: Colors.white,
                                elevation: 2,
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF764ba2)),
                              ),
                            ),
                          ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _goToRegister,
                      child: const Text(
                        'Don\'t have an account? Register',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 