import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;

import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../services/performance_service.dart';
import '../services/error_reporting_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String _selectedRole = 'farmer';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

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
      await AnalyticsService.trackScreenView('register_screen');
      await PerformanceService.trackScreenLoad('register_screen');
    } catch (e) {
      // Ignore tracking errors
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    
    try {
      await PerformanceService.trackOperation(
        'registration_attempt',
        () async {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.register(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );
      
      if (success) {
            // Track successful registration
            await AnalyticsService.trackRegistration(
              username: _usernameController.text.trim(),
              role: _selectedRole,
            );

            if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Account created successfully! Welcome ${_usernameController.text.trim()}!',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 3),
          ),
        );

              // Navigate to login screen with animation
        Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const LoginScreen(),
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
        });
            }
      } else {
            // Track failed registration
            await ErrorReportingService.reportAuthError(
              'registration',
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
                          authService.errorMessage ?? 'Registration failed. Please try again.',
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
        errorType: 'registration_error',
        errorMessage: 'Failed to register user',
        error: e,
        additionalData: {
          'username': _usernameController.text.trim(),
          'role': _selectedRole,
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
      setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
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
                        Icons.person_add,
                                      size: 44,
                                      color: Color(0xFF4CAF50),
                                    ),
                      ),
                                  const SizedBox(height: 18),
                      const Text(
                                    'Join UMUHINZI Smart',
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
                                    'Create your account today!',
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
                          // Registration form
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
                                        hintText: 'Choose a unique username',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          if (value.trim().length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                                          return 'Username can only contain letters, numbers, and underscores';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    // Email Field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      onChanged: (_) => _clearError(),
                                      decoration: const InputDecoration(
                                        labelText: 'Email (Optional)',
                                        prefixIcon: Icon(Icons.email_outlined),
                                        hintText: 'your.email@gmail.com',
                                      ),
                                      validator: (value) {
                                        if (value != null && value.isNotEmpty) {
                                          // Only allow emails ending with @gmail.com
                                          final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
                                          if (!gmailRegex.hasMatch(value.trim())) {
                                            return 'Please enter a valid Gmail address (must end with @gmail.com)';
                                          }
                                        }
                          return null;
                        },
                      ),
                                    const SizedBox(height: 20),
                                    // Phone Field
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      onChanged: (_) => _clearError(),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                                        // Add this formatter to automatically format the number
                                        TextInputFormatter.withFunction((oldValue, newValue) {
                                          final text = newValue.text;
                                          if (text.length > 3 && !text.contains('+250')) {
                                            // Auto-insert +250 if user starts with 7
                                            if (text.startsWith('7') && text.length <= 9) {
                                              return TextEditingValue(
                                                text: '+250$text',
                                                selection: TextSelection.collapsed(offset: '+250$text'.length),
                                              );
                                            }
                                            // Auto-insert + if user starts with 250
                                            if (text.startsWith('250') && text.length <= 12) {
                                              return TextEditingValue(
                                                text: '+$text',
                                                selection: TextSelection.collapsed(offset: '+$text'.length),
                                              );
                                            }
                                          }
                                          return newValue;
                                        }),
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Phone Number (Optional)',
                                        prefixIcon: Icon(Icons.phone_outlined),
                                        hintText: '+250 785 354 935',
                                      ),
                                      validator: (value) {
                                        if (value != null && value.isNotEmpty) {
                                          // Remove all whitespace for validation
                                          final cleanedValue = value.replaceAll(RegExp(r'\s+'), '');
                                          
                                          // Accept formats:
                                          // +2507XXXXXXXX
                                          // 2507XXXXXXXX
                                          // 07XXXXXXXX
                                          // 7XXXXXXXX
                                          final rwandaPhoneRegex = RegExp(r'^(\+?250|0)?7[2389]\d{7}$');
                                          
                                          if (!rwandaPhoneRegex.hasMatch(cleanedValue)) {
                                            return 'Please enter a valid Rwandan phone number\n(e.g. +250785354935, 250785354935, 0785354935, or 785354935)';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    // Role Selection
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedRole,
                                        dropdownColor: const Color(0xFF2E7D32),
                                        style: const TextStyle(color: Colors.white, fontSize: 16),
                                        decoration: const InputDecoration(
                                          labelText: 'Select Role',
                                          labelStyle: TextStyle(color: Colors.white70),
                                          prefixIcon: Icon(Icons.work_outline, color: Colors.white70),
                                          border: InputBorder.none,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'farmer',
                                            child: Row(
                                              children: [
                                                Icon(Icons.agriculture, color: Colors.white),
                                                SizedBox(width: 12),
                                                Text('Farmer'),
                                              ],
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'dealer',
                                            child: Row(
                                              children: [
                                                Icon(Icons.store, color: Colors.white),
                                                SizedBox(width: 12),
                                                Text('Dealer'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedRole = value!;
                                          });
                                        },
                                      ),
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
                                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                            color: Colors.white70,
                                          ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                                        hintText: 'Create a strong password',
                        ),
                        validator: (value) {
                                        if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                                    const SizedBox(height: 20),
                                    // Confirm Password Field
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      onChanged: (_) => _clearError(),
                                      decoration: InputDecoration(
                                        labelText: 'Confirm Password',
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                            color: Colors.white70,
                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword = !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                        hintText: 'Confirm your password',
                          ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                        },
                      ),
                      const SizedBox(height: 24),
                                    // Terms and Conditions
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _agreeToTerms,
                                          onChanged: (value) {
                                            setState(() {
                                              _agreeToTerms = value!;
                                            });
                                          },
                                          activeColor: const Color(0xFF4CAF50),
                                          checkColor: Colors.white,
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _agreeToTerms = !_agreeToTerms;
                                              });
                                            },
                                            child: const Text(
                                              'I agree to the Terms and Conditions',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                      // Register Button
                                    ScaleTransition(
                                      scale: _buttonAnimation,
                                      child: FadeTransition(
                                        opacity: _buttonAnimation,
                                        child: SizedBox(
                        width: double.infinity,
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(0xFF4CAF50),
                                              elevation: 8,
                                              shadowColor: Colors.black.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                  ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                                ),
                                                  )
                                                : const Text(
                                  'Create Account',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
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
                        ],
                      ),
                      ),
                    ],
                ),
              ),
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
        final size = MediaQuery.of(context).size;
        final random = math.Random(index);
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final scale = 0.5 + random.nextDouble() * 1.0;
        final opacity = 0.1 + random.nextDouble() * 0.2;
        
        return Positioned(
          left: x,
          top: y,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 