import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../profile/profile_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.onAuthSuccess});

  final VoidCallback? onAuthSuccess;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  String? _success;
  String? _pendingVerificationEmail;
  final _referralController = TextEditingController();

  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
      _pendingVerificationEmail = null;
    });
    try {
      if (_isLogin) {
        final user = await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (user != null && !user.emailVerified) {
          setState(() {
            _error = 'Please verify your email before signing in.';
            _pendingVerificationEmail = user.email;
          });
          await user.sendEmailVerification();
        } else {
          setState(() {
            _success = 'Sign in successful!';
          });
          widget.onAuthSuccess?.call();
        }
      } else {
        final user = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (user != null) {
          await _profileService.createProfile(
            email: user.email ?? _emailController.text.trim(),
            referrer: _referralController.text.trim().isEmpty
                ? null
                : _referralController.text.trim(),
          );
          await user.sendEmailVerification();
          setState(() {
            _success =
                'Sign up successful! Please check your email to verify your account.';
            _pendingVerificationEmail = user.email;
          });
        }
      }
    } on Exception catch (e) {
      String message = e.toString();
      if (message.contains('email-already-in-use')) {
        message = 'This email is already in use.';
      } else if (message.contains('user-not-found')) {
        message = 'No user found for that email.';
      } else if (message.contains('wrong-password')) {
        message = 'Incorrect password.';
      } else if (message.contains('weak-password')) {
        message = 'Password is too weak.';
      } else if (message.contains('invalid-email')) {
        message = 'Invalid email address.';
      }
      setState(() {
        _error = message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openGmailOrBrowser() async {
    const gmailUrl = 'https://mail.google.com';
    if (await canLaunchUrl(Uri.parse(gmailUrl))) {
      await launchUrl(
        Uri.parse(gmailUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme.scaffoldWithBackground(
      context: context,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: AppTheme.createCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLogin ? 'Sign In' : 'Sign Up',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        hintText: 'Enter your email',
                        hintStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.black,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : 'Enter a valid email',
                      enabled: !_loading,
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _referralController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Referral Code (Optional)',
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          hintText: 'Enter referral code',
                          hintStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: const Icon(
                            Icons.card_giftcard,
                            color: Colors.black,
                          ),
                        ),
                        enabled: !_loading,
                      ),
                    ],
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.lock, color: Colors.black),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (v) => v != null && v.length >= 6
                          ? null
                          : 'Password must be at least 6 characters',
                      enabled: !_loading,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    if (_success != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _success!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                    if (_pendingVerificationEmail != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.orange[50],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'A verification email has been sent to $_pendingVerificationEmail. Please check your inbox and verify your email to continue.',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _openGmailOrBrowser,
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open Gmail'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _toggleMode,
                      child: Text(
                        _isLogin
                            ? "Don't have an account? Sign Up"
                            : 'Already have an account? Sign In',
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
