import 'package:flutter/material.dart';
import 'welcome_page.dart';
import 'student_home_page.dart';
import 'company_home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter email and password.';
      });
      return;
    }
    try {
      // 1. Sign in with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 2. Fetch user document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (userDoc.exists) {
        String role = userDoc['role'];
        if (role == 'student') {
          Navigator.pushNamedAndRemoveUntil(context, '/studentHome', (route) => false);
        } else if (role == 'company') {
          Navigator.pushNamedAndRemoveUntil(context, '/companyHome', (route) => false);
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unknown user role.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User data not found.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      String message;
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        message = 'Invalid email or password.';
      } else {
        message = e.message ?? 'Login failed. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } on FirebaseException catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Login failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0D3B24);
    const logoCircleColor = Color(0xFF2B3C70);
    const fieldColor = Color(0xFFE6E6E6);
    const buttonColor = Color(0xFF2B3C70);
    const homeIconColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Logo
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: logoCircleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.PNG',
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Internlink',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(1, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Email Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: fieldColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: fieldColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              // Login Button
              if (!_isLoading)
                SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't Have account?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _RegisterLink(),
                ],
              ),
              const SizedBox(height: 32),
              // Home Icon
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  },
                  child: Icon(
                    Icons.home_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterLink extends StatefulWidget {
  @override
  State<_RegisterLink> createState() => _RegisterLinkState();
}

class _RegisterLinkState extends State<_RegisterLink> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/register');
        },
        child: Text(
          'Register',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            fontSize: 15,
            shadows: _isHovering
                ? [
                    Shadow(
                      color: Colors.black.withOpacity(0.4),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }
} 