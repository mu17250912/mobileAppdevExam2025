import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '603264273729-qhra1otrljgn8oofvqodees8d8f76ha7.apps.googleusercontent.com'
        : null,
  );
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _error;
  bool _emailVerificationSent = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final remember = prefs.getBool('remember') ?? false;
    if (remember && email != null) {
      _emailController.text = email;
      _rememberMe = true;
      setState(() {});
    }
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text.trim().toLowerCase());
      await prefs.setBool('remember', true);
    } else {
      await prefs.remove('email');
      await prefs.setBool('remember', false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  Future<void> _signInWithEmail() async {
    if (!_validateInputs()) return;
    await _saveRememberMe();

    setState(() {
      _isLoading = true;
      _error = null;
      _emailVerificationSent = false;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser!;
      await user.reload();

      if (!user.emailVerified) {
        setState(() {
          _error = 'Please verify your email before signing in.';
          _emailVerificationSent = true;
        });
      } else {
        _showSnack("Signed in successfully!");
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      _setErrorFromCode(e.code, e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendEmailVerification() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _showSnack('Verification email resent. Please check your inbox.');
      } else {
        setState(() {
          _error = 'No user signed in or email already verified.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to resend verification email.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerWithEmail() async {
    if (!_validateInputs()) return;
    await _saveRememberMe();

    setState(() {
      _isLoading = true;
      _error = null;
      _emailVerificationSent = false;
    });

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user!;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'uid': user.uid,
        'created_at': Timestamp.now(),
      });

      await user.sendEmailVerification();

      setState(() {
        _emailVerificationSent = true;
      });

      _showSnack("Verification email sent. Please check your inbox.");
    } on FirebaseAuthException catch (e) {
      _setErrorFromCode(e.code, e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!(kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      setState(() => _error = 'Google Sign-In is not supported.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _error = 'Google Sign-In was cancelled.';
          _isLoading = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user!;
      final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await doc.get();

      if (!snapshot.exists) {
        await doc.set({
          'email': user.email,
          'uid': user.uid,
          'name': user.displayName,
          'photo': user.photoURL,
          'created_at': Timestamp.now(),
        });
      }

      _showSnack("Signed in with Google!");
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setErrorFromCode(String code, String? message) {
    setState(() {
      switch (code) {
        case 'user-not-found':
          _error = 'No user found with this email.';
          break;
        case 'wrong-password':
          _error = 'Incorrect password.';
          break;
        case 'email-already-in-use':
          _error = 'Email already registered.';
          break;
        case 'invalid-email':
          _error = 'Invalid email format.';
          break;
        case 'weak-password':
          _error = 'Password too weak.';
          break;
        default:
          _error = message ?? 'Authentication error.';
      }
    });
  }

  bool _validateInputs() {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Email is required.');
      return false;
    }
    if (_passwordController.text.trim().length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return false;
    }
    return true;
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _error = 'Enter your email to reset password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim().toLowerCase());
      _showSnack('Password reset email sent. Check your inbox.');
    } on FirebaseAuthException catch (e) {
      _setErrorFromCode(e.code, e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In / Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/google_logo.svg',
                    height: 80,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                            ),
                            const Flexible(
                              child: Text('Remember me'),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _resetPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_emailVerificationSent)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          const Text(
                            'Verification email sent. Please verify your email.',
                            style: TextStyle(color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                          ElevatedButton(
                            onPressed: _resendEmailVerification,
                            child: const Text('Resend Verification Email'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            ElevatedButton(
                              onPressed: _signInWithEmail,
                              child: const Text('Sign In'),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _registerWithEmail,
                              child: const Text('Register'),
                            ),
                            const SizedBox(height: 20),
                            const Text('OR'),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _signInWithGoogle,
                              icon: SvgPicture.asset(
                                'assets/images/google_logo.svg',
                                height: 20,
                                width: 20,
                              ),
                              label: const Text('Sign In with Google'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                minimumSize: const Size(double.infinity, 48),
                                side: const BorderSide(color: Colors.grey),
                              ),
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
