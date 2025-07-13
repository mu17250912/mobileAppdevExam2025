import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool isLogin = true;
  String email = '';
  String password = '';
  String name = '';
  String error = '';
  bool loading = false;
  bool _obscurePassword = true;
  String selectedRole = 'user';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!mounted) return;
    setState(() { loading = true; error = ''; });
    try {
      if (isLogin) {
        await _authService.login(email, password, selectedRole);
      } else {
        await _authService.register(email, password, name, selectedRole);
        if (mounted) {
          setState(() {
            isLogin = true;
            error = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Registration successful! Please log in.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
      setState(() { error = e.message ?? 'Authentication error'; });
      }
    } finally {
      if (mounted) {
      setState(() { loading = false; });
      }
    }
  }

  void _toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
      error = '';
      _formKey.currentState?.reset();
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
        child: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo and Title Section
                    _buildHeader(),
                    const SizedBox(height: 40),
                    
                    // Auth Form Card
                    _buildAuthForm(),
                    const SizedBox(height: 24),
                    
                    // Footer
                    _buildFooter(),
                  ],
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
        // App Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.link_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        
        // Title
        Text(
          'Local Link',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          isLogin ? 'Welcome back to your account' : 'Create your account',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
                ),
              ],
            ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role Selector
            _buildRoleSelector(),
            const SizedBox(height: 24),
            
            // Form Fields
            if (!isLogin) ...[
              _buildNameField(),
              const SizedBox(height: 20),
            ],
            _buildEmailField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 24),
            
            // Error Message
            if (error.isNotEmpty) _buildErrorWidget(),
            
            const SizedBox(height: 24),
            
            // Submit Button
            _buildSubmitButton(),
            const SizedBox(height: 24),
            
            // Toggle Auth Mode
            _buildToggleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
        Text(
          'I am a',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              items: [
                DropdownMenuItem(
                  value: 'user',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      const Text('User', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'provider',
                  child: Row(
                    children: [
                      Icon(Icons.business, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      const Text('Service Provider', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedRole = val);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
          'Full Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
                        TextFormField(
          key: const ValueKey('name'),
                          decoration: InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          onChanged: (val) => name = val,
          validator: (val) => !isLogin && (val == null || val.isEmpty) 
              ? 'Please enter your name' 
              : null,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
                      TextFormField(
          key: const ValueKey('email'),
                        decoration: InputDecoration(
            hintText: 'Enter your email address',
            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (val) => email = val,
          validator: (val) => val == null || !val.contains('@') 
              ? 'Please enter a valid email address' 
              : null,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
                      TextFormField(
          key: const ValueKey('password'),
                        decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          obscureText: _obscurePassword,
                        onChanged: (val) => password = val,
          validator: (val) => val == null || val.length < 6 
              ? 'Password must be at least 6 characters' 
              : null,
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
                            width: double.infinity,
      height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: const Color(0xFF667EEA).withOpacity(0.3),
        ),
        onPressed: loading ? null : () {
                                if (_formKey.currentState!.validate()) {
                                  _submit();
                                }
                              },
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                isLogin ? 'Sign In' : 'Create Account',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Center(
      child: TextButton(
        onPressed: _toggleAuthMode,
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            children: [
              TextSpan(
                text: isLogin 
                    ? "Don't have an account? " 
                    : 'Already have an account? ',
              ),
              TextSpan(
                text: isLogin ? 'Sign Up' : 'Sign In',
                style: const TextStyle(
                  color: Color(0xFF667EEA),
                  fontWeight: FontWeight.w600,
                  ),
                ),
              ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'By continuing, you agree to our',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              ' and ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 