import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    emailController.addListener(() {
      setState(() {
        _emailError = null;
      });
    });
    passwordController.addListener(() {
      setState(() {
        _passwordError = null;
      });
    });
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');
    if (!emailRegex.hasMatch(value)) return 'Invalid email address';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() { isLoading = true; });
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // Web: use signInWithPopup
        final googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // Mobile: use google_sign_in (not needed for web-only)
        // You can add mobile logic here if you want cross-platform
        throw UnimplementedError('Google Sign-In is only implemented for web in this build.');
      }
      // Check if user exists in Firestore, if not, create
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'role': 'customer',
        });
      }
      setState(() { isLoading = false; });
      // Navigate based on role
      final role = userDoc.data()?['role'] ?? 'customer';
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/available_cars_screen');
      }
    } catch (e) {
      setState(() { isLoading = false; });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Google sign-in failed. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: (ModalRoute.of(context)?.canPop ?? false)
          ? AppBar(
              leading: BackButton(),
              title: Text('Login', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
              backgroundColor: theme.colorScheme.primary,
              elevation: 0,
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png', height: 64),
                    const SizedBox(height: 18),
                    Text('Welcome Back!', style: theme.textTheme.displaySmall, textAlign: TextAlign.center),
                    const SizedBox(height: 18),
                    Text('Sign in to continue', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        errorText: _emailError,
                      ),
                      onChanged: (val) {
                        setState(() { _emailError = _validateEmail(val); });
                      },
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock_outline),
                        errorText: _passwordError,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() { _passwordError = _validatePassword(val); });
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) {
                            setState(() { _emailError = 'Enter your email to reset password.'; });
                            return;
                          }
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Password Reset'),
                                content: const Text('A password reset link has been sent to your email.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          } catch (e) {
                            setState(() { _emailError = 'Failed to send reset email.'; });
                          }
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.login),
                      label: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 2,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      onPressed: isLoading ? null : () async {
                        final email = emailController.text.trim();
                        final password = passwordController.text;
                        setState(() {
                          _emailError = _validateEmail(email);
                          _passwordError = _validatePassword(password);
                        });
                        if (_emailError != null || _passwordError != null) return;
                        setState(() { isLoading = true; });
                        try {
                          final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: email,
                            password: password,
                          );
                          // Fetch user role from Firestore
                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).get();
                          final role = userDoc.data()?['role'] ?? 'customer';
                          setState(() { isLoading = false; });
                          if (role == 'admin') {
                            Navigator.pushReplacementNamed(context, '/admin_dashboard');
                          } else {
                            Navigator.pushReplacementNamed(context, '/available_cars_screen');
                          }
                        } on FirebaseAuthException catch (e) {
                          setState(() { isLoading = false; });
                          String message = 'Login failed. Please check your credentials.';
                          if (e.code == 'user-not-found') {
                            message = 'No user found for that email.';
                          } else if (e.code == 'wrong-password') {
                            message = 'Wrong password provided.';
                          }
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Error'),
                              content: Text(message),
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
                    const SizedBox(height: 14),
                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Image.asset('assets/images/google_logo.png', height: 24), // Only the G logo
                        label: Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: isLoading ? null : _signInWithGoogle,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Don\'t have an account?', style: theme.textTheme.bodyMedium),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: const Text('Register'),
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