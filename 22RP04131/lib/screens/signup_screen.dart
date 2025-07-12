import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/google_sign_in_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _loading = true;
        _error = null;
      });
      final appState = Provider.of<AppState>(context, listen: false);
      try {
        await appState.signup(_nameController.text.trim(), _emailController.text.trim(), null, _passwordController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful!')),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/onboarding');
            }
          },
        ),
        title: const Text('Sign Up', style: AppTypography.titleMedium),
      ),
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
                            child: const Icon(Icons.person_add, size: 32, color: Colors.white),
                          ),
                          const SizedBox(height: 18),
                          const Text('Create Account', style: AppTypography.headlineMedium, textAlign: TextAlign.center),
                          const Text('Sign up to get started', style: AppTypography.bodyLarge, textAlign: TextAlign.center),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Name is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
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
                          if (_error != null) ...[
                            Text(_error!, style: const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 8),
                          ],
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
                              onPressed: _loading ? null : _signup,
                              child: _loading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign Up'),
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
                        ],
                      ),
                    ),
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