/// Professional Login Screen for SafeRide
///
/// This screen provides secure authentication with modern UI design,
/// proper validation, and support for various login methods.
library;

import 'package:flutter/material.dart';
import 'package:saferide/utils/app_config.dart';
import 'package:saferide/services/auth_service.dart';
import 'package:saferide/widgets/loading_overlay.dart';
import 'package:saferide/widgets/error_message.dart';
import 'package:saferide/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminCodeController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showAdminCodeInput = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (user != null) {
          // Navigate based on user type
          final userModel = await _authService.getCurrentUserModel();
          if (userModel?.userType == UserType.admin) {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          } else if (userModel?.userType == UserType.driver) {
            Navigator.pushReplacementNamed(context, '/driver-dashboard');
          } else {
            // Default to passenger dashboard
            Navigator.pushReplacementNamed(context, '/passenger-dashboard');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (mounted) {
        if (userCredential?.user != null) {
          // Navigate based on user type
          final userModel = await _authService.getCurrentUserModel();
          if (userModel?.userType == UserType.admin) {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          } else if (userModel?.userType == UserType.driver) {
            Navigator.pushReplacementNamed(context, '/driver-dashboard');
          } else {
            // Default to passenger dashboard
            Navigator.pushReplacementNamed(context, '/passenger-dashboard');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getGoogleSignInErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAdminLogin() async {
    if (_adminCodeController.text.trim() != AppConfig.adminCode) {
      setState(() {
        _errorMessage = 'Invalid admin code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create admin account if it doesn't exist
      final adminEmail = 'admin@saferide.com';
      final adminPassword = 'admin123456';

      await _authService.registerWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
        name: 'Admin User',
        phone: '250123456789',
        userType: UserType.admin,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email address';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address';
    } else if (error.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later';
    } else if (error.contains('network')) {
      return 'Network error. Please check your internet connection';
    } else {
      return 'Login failed. Please try again';
    }
  }

  String _getGoogleSignInErrorMessage(String error) {
    if (error.contains('popup_closed_by_user')) {
      return 'Sign-in was cancelled';
    } else if (error.contains('network')) {
      return 'Network error. Please check your internet connection';
    } else if (error.contains('account_exists_with_different_credential')) {
      return 'An account already exists with this email using a different sign-in method';
    } else if (error.contains('invalid_credential')) {
      return 'Invalid credentials. Please try again';
    } else if (error.contains('operation_not_allowed')) {
      return 'Google Sign-In is not enabled. Please contact support';
    } else {
      return 'Google Sign-In failed. Please try again';
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleAdminCodeInput() {
    setState(() {
      _showAdminCodeInput = !_showAdminCodeInput;
      if (!_showAdminCodeInput) {
        _adminCodeController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA), // Subtle light background
        body: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                margin:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo and App Name
                        _buildHeader(),
                        const SizedBox(height: 24),
                        // Welcome Text
                        _buildWelcomeText(),
                        const SizedBox(height: 24),
                        // Error Message
                        if (_errorMessage != null) ...[
                          ErrorMessage(error: _errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        // Login Form
                        _buildLoginForm(),
                        const SizedBox(height: 16),
                        // Login Button
                        _buildLoginButton(),
                        const SizedBox(height: 20),
                        // Divider for alternative sign-in
                        Row(
                          children: [
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('OR',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                            ),
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Google Sign-In Button
                        _buildGoogleSignInButton(),
                        const SizedBox(height: 16),
                        // Forgot Password
                        _buildForgotPassword(),
                        const SizedBox(height: 16),
                        // Register Link
                        _buildRegisterLink(),
                        const SizedBox(height: 8),
                        // Admin Access
                        _buildAdminAccess(),
                        if (_showAdminCodeInput) ...[
                          const SizedBox(height: 16),
                          _buildAdminCodeSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppConfig.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppConfig.primaryColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_taxi,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        // App Name
        Text(
          AppConfig.appName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF2D3142),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppConfig.appDescription,
          style: const TextStyle(
            color: Color(0xFF6C7A89),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Welcome Back!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConfig.spacingS),
        Text(
          'Sign in to continue your journey',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                .hasMatch(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),

        const SizedBox(height: AppConfig.spacingM),

        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: _togglePasswordVisibility,
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
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: AppConfig.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.cardRadius),
        ),
      ),
      child: Text(
        'Sign In',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      icon: Image.asset(
        'assets/images/google_logo.png',
        height: 24,
        width: 24,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.g_mobiledata, size: 24, color: Colors.red);
        },
      ),
      label: const Text(
        'Continue with Google',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildAdminCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Admin Access',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConfig.spacingM),
        TextFormField(
          controller: _adminCodeController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Admin Code',
            hintText: 'Enter admin code',
            prefixIcon: Icon(Icons.admin_panel_settings_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter admin code';
            }
            return null;
          },
        ),
        const SizedBox(height: AppConfig.spacingM),
        OutlinedButton(
          onPressed: _isLoading ? null : _handleAdminLogin,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppConfig.spacingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.cardRadius),
            ),
          ),
          child: Text(
            'Access Admin Panel',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: AppConfig.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConfig.spacingM),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/register'),
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: AppConfig.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminAccess() {
    return Column(
      children: [
        TextButton(
          onPressed: _toggleAdminCodeInput,
          child: Text(
            _showAdminCodeInput ? 'Hide Admin Access' : 'Admin Access',
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
        if (!_showAdminCodeInput) ...[
          const SizedBox(height: AppConfig.spacingS),
          Text(
            'Long press the logo for admin access',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.4),
                  fontSize: 10,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
