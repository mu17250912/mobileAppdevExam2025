import 'package:flutter/material.dart';
import '../models/user.dart';
import '../styles/app_styles.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String? _error;
  bool _isLoading = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Admin login (hardcoded, case sensitive)
      if (_email == 'admin@admin.com' && _password == 'admin123') {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'isAdmin': true,
            'isLoggedIn': true,
            'userEmail': _email,
            'user': null,
          },
        );
        return;
      }
      try {
        fb_auth.UserCredential userCredential = await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        // Fetch user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        final userData = userDoc.data();
        final user = AppUser(
          id: userCredential.user!.uid,
          idNumber: userData?['idNumber'] ?? '',
          fullName: userData?['fullName'] ?? '',
          telephone: userData?['telephone'] ?? '',
          email: userData?['email'] ?? '',
          password: '',
          cvUrl: userData?['cvUrl'],
          experiences: [],
          degrees: [],
          certificates: [],
        );
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'isAdmin': false,
            'isLoggedIn': true,
            'userEmail': _email,
            'user': user,
          },
        );
      } on fb_auth.FirebaseAuthException catch (e) {
        setState(() {
          _error = e.message ?? 'Login failed.';
          _isLoading = false;
        });
        print("Login failed: ${e.message}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/me.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4), // semi-transparent overlay
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppStyles.primaryGradient,
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppStyles.spacingL),
                  child: AppStyles.primaryContainer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo/Header Section
                        Container(
                          padding: const EdgeInsets.all(AppStyles.spacingL),
                          decoration: BoxDecoration(
                            gradient: AppStyles.accentGradient,
                            borderRadius: BorderRadius.circular(AppStyles.radiusL),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 64,
                                color: Colors.white,
                              ),
                              AppStyles.verticalSpaceM,
                              Text(
                                'E-Recruitment',
                                style: AppStyles.heading2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AppStyles.verticalSpaceS,
                              Text(
                                'Find Your Dream Job',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        AppStyles.verticalSpaceXL,
                        
                        // Login Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome Back',
                                style: AppStyles.heading4,
                                textAlign: TextAlign.center,
                              ),
                              AppStyles.verticalSpaceS,
                              Text(
                                'Sign in to your account',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppStyles.textTertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              AppStyles.verticalSpaceL,
                              
                              // Error Message
                              if (_error != null)
                                Container(
                                  padding: const EdgeInsets.all(AppStyles.spacingM),
                                  decoration: BoxDecoration(
                                    color: AppStyles.errorColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppStyles.radiusM),
                                    border: Border.all(
                                      color: AppStyles.errorColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: AppStyles.errorColor,
                                        size: 20,
                                      ),
                                      AppStyles.horizontalSpaceS,
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: AppStyles.bodyMedium.copyWith(
                                            color: AppStyles.errorColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              if (_error != null) AppStyles.verticalSpaceM,
                              
                              // Email Field
                              TextFormField(
                                decoration: AppStyles.inputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Enter your email',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: AppStyles.textTertiary,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                                onChanged: (value) => _email = value,
                              ),
                              
                              AppStyles.verticalSpaceM,
                              
                              // Password Field
                              TextFormField(
                                decoration: AppStyles.inputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: AppStyles.textTertiary,
                                  ),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                onChanged: (value) => _password = value,
                              ),
                              
                              AppStyles.verticalSpaceL,
                              
                              // Login Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: AppStyles.primaryButton.copyWith(
                                  backgroundColor: MaterialStateProperty.all(AppStyles.primaryColor),
                                  foregroundColor: MaterialStateProperty.all(Colors.white),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text('Sign In'),
                              ),
                              
                              AppStyles.verticalSpaceL,
                              
                              // Register Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Don\'t have an account? ',
                                    style: AppStyles.bodyMedium,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/register');
                                    },
                                    child: Text(
                                      'Register',
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: AppStyles.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              AppStyles.verticalSpaceM,
                              
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 