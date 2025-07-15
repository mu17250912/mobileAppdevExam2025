import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // Sign in with FirebaseAuth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Optionally fetch user data from Firestore if needed
      // final userDoc = await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(credential.user!.uid)
      //     .get();
      // You can use userDoc.data() if you need extra info
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed: ';
      if (e.code == 'user-not-found') {
        errorMessage += 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage += 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        errorMessage += 'Invalid email address';
      } else {
        errorMessage += e.message ?? e.code;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: \\${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.lock, size: 64, color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        Text('Welcome Back',
                          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
                        ),
                        const SizedBox(height: 4),
                        Text('Login to your account',
                          style: GoogleFonts.poppins(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      obscureText: !_showPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                final emailController = TextEditingController(text: _emailController.text);
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Forgot Password?'),
                                    content: TextFormField(
                                      controller: emailController,
                                      decoration: const InputDecoration(labelText: 'Enter your email'),
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          final email = emailController.text.trim();
                                          if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(email)) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Please enter a valid email.')),
                                            );
                                            return;
                                          }
                                          Navigator.of(ctx).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('If this email exists, you will receive password reset instructions.')),
                                          );
                                        },
                                        child: const Text('Send Reset Link'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                        child: Text('Forgot Password?', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?", style: GoogleFonts.poppins(fontSize: 15)),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                },
                          child: Text('Sign up', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        ),
                      ],
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