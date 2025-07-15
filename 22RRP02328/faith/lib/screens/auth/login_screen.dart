import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      final userType = authProvider.userData?.userType;
      if (userType == AppConstants.userTypeAdmin) {
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else if (userType == AppConstants.userTypeServiceProvider) {
        Get.offAllNamed('/provider-dashboard');
      } else if (userType == AppConstants.userTypeUser || userType == 'event_organizer') {
        Get.offAllNamed(AppRoutes.userDashboard);
      } else {
        // Unknown user type
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown account type. Please contact support.')),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      final userType = authProvider.userData?.userType;
      if (userType == AppConstants.userTypeAdmin) {
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else if (userType == AppConstants.userTypeServiceProvider) {
        Get.offAllNamed('/provider-dashboard');
      } else if (userType == AppConstants.userTypeUser || userType == 'event_organizer') {
        Get.offAllNamed(AppRoutes.userDashboard);
      } else {
        // Unknown user type
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown account type. Please contact support.')),
        );
      }
    }
  }

  void _navigateToRegister() {
    Get.toNamed(AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // App Logo and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(AppColors.primaryColor),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(AppColors.primaryColor).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppConstants.appName,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(AppColors.textColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.loginTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: AppStrings.emailHint,
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: AppStrings.passwordHint,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
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
                
                const SizedBox(height: 10),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final emailController = TextEditingController(text: _emailController.text);
                          return AlertDialog(
                            title: const Text('Reset Password'),
                            content: TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final email = emailController.text.trim();
                                  if (email.isEmpty) return;
                                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                  final success = await authProvider.resetPassword(email);
                                  Navigator.pop(context);
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password reset email sent!')),
                                    );
                                  }
                                },
                                child: const Text('Send'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text(
                      AppStrings.forgotPassword,
                      style: GoogleFonts.poppins(
                        color: const Color(AppColors.primaryColor),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Sign In Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _signInWithEmail,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Or Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Google Sign In Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return OutlinedButton.icon(
                      onPressed: authProvider.isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: Text(
                        'Continue with Google',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToRegister,
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.poppins(
                          color: const Color(AppColors.primaryColor),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Error Message
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.error != null) {
                      return Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(AppColors.errorColor).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(AppColors.errorColor).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          authProvider.error!,
                          style: GoogleFonts.poppins(
                            color: const Color(AppColors.errorColor),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 