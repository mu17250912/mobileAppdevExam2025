import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;

import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../services/performance_service.dart';
import '../services/error_reporting_service.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'farmer';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _formController;
  late AnimationController _buttonController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _formAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _trackScreenView();
  }

  void _initializeAnimations() {
    // Background animation
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    );

    // Form animation
    _formController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _formAnimation = CurvedAnimation(
      parent: _formController,
      curve: Curves.elasticOut,
    );

    // Button animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _buttonAnimation = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    );

    // Start animations
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _buttonController.forward();
    });
  }

  Future<void> _trackScreenView() async {
    try {
      await AnalyticsService.trackScreenView('login_screen');
      await PerformanceService.trackScreenLoad('login_screen');
    } catch (e) {
      // Ignore tracking errors
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _backgroundController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _clearError() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.errorMessage != null) {
      authService.clearError();
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final role = _selectedRole;
    print('DEBUG: Attempting login with username="$username", password="$password", role="$role"');

    try {
      await PerformanceService.trackOperation(
        'login_attempt',
        () async {
          final authService = Provider.of<AuthService>(context, listen: false);
          final success = await authService.login(
            username,
            password,
            role,
          );

          if (success) {
            // Track successful login
            await AnalyticsService.trackLogin(
              username: username,
              role: role,
            );

            // Navigate to dashboard with animation
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const DashboardScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
                (route) => false,
              );
            }
          } else {
            // Track failed login
            await ErrorReportingService.reportAuthError(
              'login',
              authService.errorMessage ?? 'Unknown error',
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          authService.errorMessage ?? 'Login failed. Please try again.',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          }
        },
        thresholdMs: 5000,
      );
    } catch (e) {
      await ErrorReportingService.reportError(
        errorType: 'login_error',
        errorMessage: 'Failed to login user',
        error: e,
        additionalData: {
          'username': username,
          'role': role,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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

  void _goToRegister() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
          gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4CAF50),
                      Color.lerp(const Color(0xFF2E7D32), const Color(0xFF1B5E20), _backgroundAnimation.value)!,
                    ],
          ),
        ),
              );
            },
          ),
          // Animated floating background elements
          ...List.generate(12, (index) => _buildBackgroundElement(index)),
          // Main content
          SafeArea(
          child: Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glassmorphic card
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        minHeight: size.height * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        backgroundBlendMode: BlendMode.overlay,
                      ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          // Logo and title
                          ScaleTransition(
                            scale: _formAnimation,
                            child: FadeTransition(
                              opacity: _formAnimation,
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.10),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                          Icons.agriculture,
                                      size: 44,
                          color: Color(0xFF4CAF50),
                        ),
                                  ),
                                  const SizedBox(height: 18),
                        const Text(
                                    'Welcome Back',
                          style: TextStyle(
                                      fontSize: 30,
                            fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.1,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                                    'Sign in to your account',
                          style: TextStyle(
                            fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                          ),
                        ),
                        const SizedBox(height: 32),
                          // Login form
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(_formAnimation),
                            child: FadeTransition(
                              opacity: _formAnimation,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          autofocus: true,
                          onChanged: (_) => _clearError(),
                          decoration: const InputDecoration(
                            labelText: 'Username',
                                        prefixIcon: Icon(Icons.person_outline),
                                        hintText: 'Enter your username',
                          ),
                          validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                                    const SizedBox(height: 20),
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                                      obscureText: _obscurePassword,
                          onChanged: (_) => _clearError(),
                                      decoration: InputDecoration(
                            labelText: 'Password',
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                            HapticFeedback.lightImpact();
                                          },
                                        ),
                                        hintText: 'Enter your password',
                          ),
                          validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                                    const SizedBox(height: 20),
                        // Role Selection
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                                        labelText: 'I am a...',
                                        prefixIcon: Icon(Icons.work_outline),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'farmer',
                                          child: Row(
                                            children: [
                                              Icon(Icons.agriculture, size: 20),
                                              SizedBox(width: 8),
                                              Text('Farmer'),
                                            ],
                                          ),
                            ),
                            DropdownMenuItem(
                              value: 'dealer',
                                          child: Row(
                                            children: [
                                              Icon(Icons.store, size: 20),
                                              SizedBox(width: 8),
                                              Text('Dealer'),
                                            ],
                                          ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                            _clearError();
                                        HapticFeedback.lightImpact();
                          },
                                    ),
                                    const SizedBox(height: 20),
                                    // Remember me checkbox
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                            HapticFeedback.lightImpact();
                                          },
                                          activeColor: const Color(0xFF4CAF50),
                                        ),
                                        const Text(
                                          'Remember me',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                        ),
                        const SizedBox(height: 24),
                        // Login Button
                                    SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 1),
                                        end: Offset.zero,
                                      ).animate(_buttonAnimation),
                                      child: FadeTransition(
                                        opacity: _buttonAnimation,
                                        child: SizedBox(
                          width: double.infinity,
                                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                                              foregroundColor: Colors.white,
                                              elevation: 4,
                                              shadowColor: Colors.black.withOpacity(0.18),
                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                : const Text(
                                                    'Sign In',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Sign Up link
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(_buttonAnimation),
                            child: FadeTransition(
                              opacity: _buttonAnimation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                        TextButton(
                          onPressed: _goToRegister,
                          child: const Text(
                                      'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundElement(int index) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final random = math.Random(index);
        final x = random.nextDouble() * MediaQuery.of(context).size.width;
        final y = random.nextDouble() * MediaQuery.of(context).size.height;
        final size = random.nextDouble() * 4 + 2;
        final opacity = random.nextDouble() * 0.2 + 0.1;
        
        return Positioned(
          left: x,
          top: y,
          child: Transform.rotate(
            angle: _backgroundController.value * 2 * math.pi * (index % 2 == 0 ? 1 : -1),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
} 