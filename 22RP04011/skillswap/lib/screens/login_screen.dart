import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCredential.user;
      if (user == null) throw Exception('Login failed.');

      // Check subscription status
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // New user - redirect to subscription
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SubscriptionScreen(),
          ),
        );
        return;
      }

      final data = doc.data()!;
      final subscriptionStatus = data['subscriptionStatus'] as String?;
      final subscriptionExpiry = data['subscriptionExpiry'] as Timestamp?;

      // Check if user has active subscription
      bool hasActiveSubscription = false;

      if (subscriptionStatus == 'active' && subscriptionExpiry != null) {
        final expiryDate = subscriptionExpiry.toDate();
        final now = DateTime.now();
        hasActiveSubscription = expiryDate.isAfter(now);

        // If subscription has expired, update status
        if (!hasActiveSubscription) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'subscriptionStatus': 'expired',
          });
        }
      }

      if (hasActiveSubscription) {
        // User has active subscription - proceed to home
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // User needs to subscribe - show subscription screen
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SubscriptionScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login failed. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 48.0 : 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: isTablet ? 80 : 40),

                // App Logo
                Container(
                  width: isTablet ? 120 : 80,
                  height: isTablet ? 120 : 80,
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(Icons.swap_horiz,
                      size: isTablet ? 60 : 40, color: Colors.white),
                ),
                SizedBox(height: isTablet ? 32 : 16),

                // Welcome Text
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: isTablet ? 36 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: isTablet ? 16 : 8),
                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: isTablet ? 80 : 48),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    hintText: 'Enter your email address',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isTablet ? 24 : 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    hintText: 'Enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // Error Message
                if (_errorMessage != null) ...[
                  SizedBox(height: isTablet ? 24 : 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: isTablet ? 40 : 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: isTablet ? 56 : 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Login',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: isTablet ? 32 : 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/register'),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
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
