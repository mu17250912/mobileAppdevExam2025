import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _loading = true;
        _error = null;
      });
      final appState = Provider.of<AppState>(context, listen: false);
      try {
        await appState.login(_emailController.text.trim(), _passwordController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
        context.go('/dashboard');
      } catch (e) {
        setState(() {
          // Show only the real Firebase error message if possible
          final msg = e.toString();
          final match = RegExp(r'\] (.*)').firstMatch(msg);
          _error = match != null ? match.group(1) : msg;
        });
      } finally {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.signInWithGoogle();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In successful!')),
      );
      context.go('/dashboard');
    } catch (e) {
      setState(() {
        final msg = e.toString();
        final match = RegExp(r'\] (.*)').firstMatch(msg);
        _error = match != null ? match.group(1) : msg;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.lock, size: 32, color: Colors.white),
                          ),
                          const SizedBox(height: 18),
                          const Text('Welcome Back', style: AppTypography.headlineMedium, textAlign: TextAlign.center),
                          const Text('Sign in to your account', style: AppTypography.bodyLarge, textAlign: TextAlign.center),
                          const SizedBox(height: 28),
                          if (_error != null) ...[
                            Text(_error!, style: const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 8),
                          ],
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Email is required';
                              if (!value.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Password is required';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                textStyle: AppTypography.labelLarge,
                                elevation: 4,
                              ),
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Login'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Divider with "or" text
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('or', style: AppTypography.bodyMedium?.copyWith(color: Colors.grey[600])),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Google Sign-In Button
                          GoogleSignInButton(
                            onPressed: _signInWithGoogle,
                            loading: _loading,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              // TODO: Navigate to forgot password
                            },
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: AppTypography.bodyMedium),
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: AppTypography.bodyMedium, ),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: AppTypography.bodyMedium),
                        child: const Text('Sign up'),
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