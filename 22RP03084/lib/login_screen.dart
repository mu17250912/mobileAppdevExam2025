import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'swipe_screen.dart';
import 'employer_dashboard.dart';
import 'main.dart'; // for kGoldenBrown
import 'screens/admin_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onRegisterTap;
  const LoginScreen({super.key, required this.onRegisterTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;
  
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  Future<void> _loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('remember_me') ?? false;
    final rememberedUser = prefs.getString('remembered_user') ?? '';
    setState(() {
      _rememberMe = remembered;
      if (remembered) {
        _userController.text = rememberedUser;
      }
    });
  }

  Future<void> _saveRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('remembered_user', _userController.text.trim());
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('remembered_user');
    }
  }

  bool _isEmail(String input) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+ *');
    return emailRegex.hasMatch(input);
  }

  bool _isPhone(String input) {
    final phoneRegex = RegExp(r'^[0-9]{7,15} *');
    return phoneRegex.hasMatch(input);
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    final userInput = _userController.text.trim();
    final password = _passwordController.text.trim();
    if (userInput.isEmpty || password.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Both fields are required.';
      });
      return;
    }
    if (!_isEmail(userInput) && !_isPhone(userInput)) {
      setState(() {
        _loading = false;
        _error = 'Please enter a valid email address or phone number.';
      });
      return;
    }
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users')
        .where(_isEmail(userInput) ? 'email' : 'phone', isEqualTo: userInput)
        .where('password', isEqualTo: password)
        .get();
      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data() as Map<String, dynamic>?;
        final userType = userData != null ? userData['userType'] as String? : null;
        setState(() {
          _loading = false;
          _success = 'Login successful!';
        });
        await _saveRememberedUser();
        _userController.clear();
        _passwordController.clear();
        if (userType == 'job_seeker') {
          await FirebaseAnalytics.instance.logScreenView(screenName: 'SwipeScreen');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => SwipeScreen(userId: userInput)),
            );
          }
        } else if (userType == 'employer') {
          await FirebaseAnalytics.instance.logScreenView(screenName: 'EmployerDashboard');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => EmployerDashboard(userId: userInput)),
            );
          }
        } else if (userType == 'admin') {
          await FirebaseAnalytics.instance.logScreenView(screenName: 'AdminScreen');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => AdminScreen(userId: userInput)),
            );
          }
        } else {
          await FirebaseAnalytics.instance.logScreenView(screenName: 'HomeScreen');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      } else {
        setState(() {
          _loading = false;
          _error = 'Invalid email/phone or password.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Login failed. Please try again later.';
      });
    }
  }

  // Google Sign-In handler (copied from screens/login_screen.dart)
  void _handleGoogleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() { _loading = false; });
        return; // User cancelled
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        setState(() { _loading = false; _error = 'Google sign-in failed. No user.'; });
        return;
      }
      final email = user.email;
      final name = user.displayName ?? '';
      final photoUrl = user.photoURL;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(email).get();
      if (!userDoc.exists) {
        // Register new user
        await FirebaseFirestore.instance.collection('users').doc(email).set({
          'email': email,
          'name': name,
          'profileImageUrl': photoUrl,
          'userType': 'job_seeker', // Default, can be changed later
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthSwitcher()),
      );
    } catch (e, stack) {
      debugPrint('Google sign-in error: $e');
      debugPrint('Stack trace: $stack');
      setState(() {
        _error = 'Google sign-in failed. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: kGoldenBrown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userController,
              decoration: InputDecoration(
                labelText: 'Email or Phone Number',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.person, color: kGoldenBrown),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock, color: kGoldenBrown),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (val) {
                    setState(() {
                      _rememberMe = val ?? false;
                    });
                  },
                ),
                const Text('Remember me'),
                Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loading) CircularProgressIndicator(color: kGoldenBrown),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            if (_success != null) ...[
              Text(_success!, style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGoldenBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _loading ? null : _login,
                child: const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onRegisterTap,
              child: Text(
                "Don't have an account? Register",
                style: TextStyle(color: kGoldenBrown, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Google Sign-In Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Image.asset('assets/google_logo.png', height: 24),
                label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.black12),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _loading ? null : _handleGoogleSignIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: kGoldenBrown,
      ),
      body: const Center(
        child: Text('Welcome! (Placeholder for swipe interface)'),
      ),
    );
  }
} 

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _message;
  String? _error;

  Future<void> _sendResetEmail() async {
    setState(() {
      _loading = true;
      _message = null;
      _error = null;
    });
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please enter your email.';
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _loading = false;
        _message = 'Password reset email sent! Please check your inbox.';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to send reset email. Please check your email and try again.';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: kGoldenBrown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            if (_loading) const CircularProgressIndicator(),
            if (_message != null) ...[
              Text(_message!, style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 8),
            ],
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendResetEmail,
                style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
                child: const Text('Send Password Reset Email'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 