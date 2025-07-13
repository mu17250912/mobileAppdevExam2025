import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _showPassword = false;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    setState(() {
      _emailError = _passwordError = null;
    });
    bool valid = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    // Email validation
    if (email.isEmpty) {
      _emailError = 'Email is required';
      valid = false;
    } else if (!RegExp(r'^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}').hasMatch(email)) {
      _emailError = 'Please enter a valid email address';
      valid = false;
    }
    
    // Password validation
    if (password.isEmpty) {
      _passwordError = 'Password is required';
      valid = false;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      valid = false;
    }
    
    setState(() {});
    return valid;
  }

  // Real-time email validation
  void _validateEmail(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _emailError = 'Email is required';
      } else if (!RegExp(r'^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}').hasMatch(value.trim())) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }
    });
  }

  // Real-time password validation
  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Password is required';
      } else if (value.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }
    });
  }

  void _onLogin() async {
    if (!_validateFields()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Check if account is locked
      if (_authService.isAccountLocked(email)) {
        final lockoutTime = _authService.getLockoutTimeRemaining(email);
        if (lockoutTime != null) {
          final minutes = lockoutTime.inMinutes;
          final seconds = lockoutTime.inSeconds % 60;
          throw Exception('Account temporarily locked due to too many failed attempts. Please try again in ${minutes}m ${seconds}s.');
        }
      }

      // First validate credentials before attempting login
      final isValid = await _authService.validateUserCredentials(
        email: email,
        password: password,
      );

      if (!isValid) {
        final remainingAttempts = _authService.getRemainingLoginAttempts(email);
        if (remainingAttempts <= 0) {
          throw Exception('Too many failed login attempts. Please try again in 15 minutes.');
        } else {
          throw Exception('Invalid email or password. ${remainingAttempts} attempts remaining.');
        }
      }

      // Sign in user with Firestore
      await _authService.signInUser(
        email: email,
        password: password,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        // Remove the success message and redirect immediately
          context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // Provide more user-friendly error messages
        if (errorMessage.contains('No account found')) {
          errorMessage = 'No account found with that email address. Please check your email or create a new account.';
        } else if (errorMessage.contains('Incorrect password')) {
          errorMessage = 'Incorrect password. Please check your password and try again.';
        } else if (errorMessage.contains('Invalid email')) {
          errorMessage = 'Please enter a valid email address.';
        } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (errorMessage.contains('attempts remaining')) {
          errorMessage = errorMessage; // Keep the specific attempt count message
        } else if (errorMessage.contains('temporarily locked')) {
          errorMessage = errorMessage; // Keep the lockout message
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF145A32),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo.png',
                      height: 90,
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue ordering the freshest fish!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Email Field
                    TextField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Color(0xFF145A32)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        errorText: _emailError,
                      ),
                      onChanged: _validateEmail,
                    ),
                    const SizedBox(height: 18),
                    // Password Field
                    TextField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Password',
                        prefixIcon: Icon(Icons.lock, color: Color(0xFF145A32)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        errorText: _passwordError,
                      ),
                      onChanged: _validatePassword,
                    ),
                    const SizedBox(height: 10),
                    // Divider to separate form from button
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white24,
                            thickness: 1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Icon(Icons.login, color: Colors.white38, size: 28),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white24,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF145A32),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 6,
                          shadowColor: Colors.black26,
                        ),
                        onPressed: _isLoading ? null : _onLogin,
                        child: _isLoading
                            ? const SizedBox(
                                height: 28,
                                width: 28,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF145A32)),
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Don't have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : () => context.go('/signup'),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
} 