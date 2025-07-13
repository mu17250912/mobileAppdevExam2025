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
    final isSmallScreen = AppTheme.isMobile(context);
    final screenSize = MediaQuery.of(context).size;

    return AppTheme.scaffoldWithBackground(
      context: context,
      body: SafeArea(
        child: AppTheme.createResponsiveCenteredContainer(
          context: context,
          child: AppTheme.createResponsiveCard(
            context: context,
            margin: EdgeInsets.zero,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Responsive title
                  Text(
                    _isLogin ? 'Sign In' : 'Sign Up',
                    style: AppTheme.responsiveTitleStyle(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppTheme.getResponsiveSpacing(context)),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    style: AppTheme.responsiveInputStyle(context),
                    decoration: AppTheme.responsiveInputDecoration(
                      context: context,
                      labelText: 'Email Address',
                      hintText: 'Enter your email',
                      prefixIcon: Icons.email,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v != null && v.contains('@')
                        ? null
                        : 'Enter a valid email',
                    enabled: !_loading,
                  ),

                  // Referral field (only for sign up)
                  if (!_isLogin) ...[
                    SizedBox(
                      height: AppTheme.getResponsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                    ),
                    TextFormField(
                      controller: _referralController,
                      style: AppTheme.responsiveInputStyle(context),
                      decoration: AppTheme.responsiveInputDecoration(
                        context: context,
                        labelText: 'Referral Code (Optional)',
                        hintText: 'Enter referral code',
                        prefixIcon: Icons.card_giftcard,
                      ),
                      enabled: !_loading,
                    ),
                  ],

                  SizedBox(
                    height: AppTheme.getResponsiveSpacing(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                  ),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    style: AppTheme.responsiveInputStyle(context),
                    decoration: AppTheme.responsiveInputDecoration(
                      context: context,
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black,
                          size: AppTheme.getResponsiveIconSize(context),
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

                  // Error message
                  if (_error != null) ...[
                    SizedBox(
                      height: AppTheme.getResponsiveSpacing(
                        context,
                        mobile: 12,
                        tablet: 16,
                        desktop: 20,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(
                        AppTheme.getResponsivePadding(
                          context,
                          mobile: 8,
                          tablet: 12,
                          desktop: 16,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  // Success message
                  if (_success != null) ...[
                    SizedBox(
                      height: AppTheme.getResponsiveSpacing(
                        context,
                        mobile: 12,
                        tablet: 16,
                        desktop: 20,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(
                        AppTheme.getResponsivePadding(
                          context,
                          mobile: 8,
                          tablet: 12,
                          desktop: 16,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        _success!,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  // Email verification card
                  if (_pendingVerificationEmail != null) ...[
                    SizedBox(
                      height: AppTheme.getResponsiveSpacing(
                        context,
                        mobile: 12,
                        tablet: 16,
                        desktop: 20,
                      ),
                    ),
                    Card(
                      color: Colors.orange[50],
                      margin: EdgeInsets.symmetric(
                        vertical: AppTheme.getResponsiveSpacing(
                          context,
                          mobile: 4,
                          tablet: 8,
                          desktop: 12,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                          AppTheme.getResponsivePadding(
                            context,
                            mobile: 12,
                            tablet: 16,
                            desktop: 20,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'A verification email has been sent to $_pendingVerificationEmail. Please check your inbox and verify your email to continue.',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                                fontSize: AppTheme.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: AppTheme.getResponsiveSpacing(
                                context,
                                mobile: 8,
                                tablet: 12,
                                desktop: 16,
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _openGmailOrBrowser,
                                icon: Icon(
                                  Icons.open_in_new,
                                  size: AppTheme.getResponsiveIconSize(
                                    context,
                                    mobile: 16,
                                    tablet: 20,
                                    desktop: 24,
                                  ),
                                ),
                                label: Text(
                                  'Open Gmail',
                                  style: TextStyle(
                                    fontSize: AppTheme.getResponsiveFontSize(
                                      context,
                                      mobile: 14,
                                      tablet: 16,
                                      desktop: 18,
                                    ),
                                  ),
                                ),
                                style: AppTheme.responsiveButtonStyle(
                                  context,
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: AppTheme.getResponsiveSpacing(context)),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: AppTheme.responsiveButtonStyle(context),
                      child: _loading
                          ? SizedBox(
                              height: AppTheme.getResponsiveIconSize(context),
                              width: AppTheme.getResponsiveIconSize(context),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Sign In' : 'Sign Up',
                              style: TextStyle(
                                fontSize: AppTheme.getResponsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(
                    height: AppTheme.getResponsiveSpacing(
                      context,
                      mobile: 16,
                      tablet: 20,
                      desktop: 24,
                    ),
                  ),

                  // Toggle mode button
                  TextButton(
                    onPressed: _loading ? null : _toggleMode,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.getResponsivePadding(
                          context,
                          mobile: 8,
                          tablet: 12,
                          desktop: 16,
                        ),
                      ),
                    ),
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Sign Up"
                          : 'Already have an account? Sign In',
                      style: TextStyle(
                        fontSize: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
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
