import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_screen.dart';
import 'role_selection_before_login.dart';
import 'role_selection_screen.dart';
import 'learner_dashboard.dart';
import 'trainer_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends StatefulWidget {
  final String userRole;
  final VoidCallback? onThemeToggle;
  final ThemeMode? themeMode;
  
  const LoginScreen({Key? key, required this.userRole, this.onThemeToggle, this.themeMode}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: _emailController.text.trim())
            .where('password', isEqualTo: _passwordController.text.trim())
            .get();
        
        if (query.docs.isNotEmpty) {
          final userData = query.docs.first.data();
          final userRole = userData['role'];
          
          // Check if user's role matches the selected role
          if (userRole != widget.userRole) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('This account is registered as a ${userRole == 'learner' ? 'Learner' : 'Trainer'}. Please select the correct role.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          
          if (mounted) {
            // Navigate to appropriate dashboard based on role
            if (widget.userRole == 'learner') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LearnerDashboard(userEmail: _emailController.text.trim(), onThemeToggle: widget.onThemeToggle, themeMode: widget.themeMode),
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => TrainerDashboard(userEmail: _emailController.text.trim(), onThemeToggle: widget.onThemeToggle, themeMode: widget.themeMode),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid email or password.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occurred. Please try again.')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; });
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // Web: use signInWithPopup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // Mobile: use GoogleSignIn and signInWithCredential
        final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          setState(() { _isLoading = false; });
          return;
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }
      final email = userCredential.user?.email;
      if (email == null) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in failed.')));
        return;
      }
      // Check if user exists in Firestore
      final userQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
      if (userQuery.docs.isEmpty) {
        // New user: prompt for role selection and create user doc
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RoleSelectionScreen(userEmail: email),
          ),
        );
      } else {
        final userData = userQuery.docs.first.data();
        final userRole = userData['role'];
        if (userRole == 'learner') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LearnerDashboard(userEmail: email, onThemeToggle: widget.onThemeToggle, themeMode: widget.themeMode),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TrainerDashboard(userEmail: email, onThemeToggle: widget.onThemeToggle, themeMode: widget.themeMode),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Login as ${widget.userRole == 'learner' ? 'Learner' : 'Trainer'}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RoleSelectionBeforeLogin()),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: isDark ? const Color(0xFF23272F) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icon.png',
                      height: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white : theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect. Learn. Grow.',
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white70 : Colors.blueGrey,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: _login,
                              child: Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(userRole: widget.userRole),
                          ),
                        );
                      },
                      child: Text(
                        "Don't have an account? Register",
                        style: GoogleFonts.poppins(
                          color: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Google Sign-In Button
                    _isLoading
                      ? const SizedBox.shrink()
                      : SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Image.asset('assets/google_logo.png', height: 24),
                            label: const Text('Sign in with Google'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _signInWithGoogle,
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