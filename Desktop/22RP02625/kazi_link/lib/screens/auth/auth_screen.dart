import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  final _signInKey = GlobalKey<FormState>();
  final _signUpKey = GlobalKey<FormState>();
  String _signInEmail = '', _signInPassword = '';
  String _signUpEmail = '', _signUpPassword = '', _signUpConfirm = '';
  String _signUpPasswordValue = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _togglePassword() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _toggleConfirm() {
    setState(() => _obscureConfirm = !_obscureConfirm);
  }

  void _signIn() async {
    if (_signInKey.currentState?.validate() ?? false) {
      _signInKey.currentState?.save();
      setState(() => _loading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _signInEmail,
          password: _signInPassword,
        );
        final String? providerRole = Provider.of<UserProvider>(context, listen: false).role;
        Navigator.of(context).pushReplacementNamed('/dashboard', arguments: providerRole);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.message ?? 'Sign in failed',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  void _signUp() async {
    if (_signUpKey.currentState?.validate() ?? false) {
      _signUpKey.currentState?.save();
      setState(() => _loading = true);
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _signUpEmail,
          password: _signUpPassword,
        );
        final String? providerRole = Provider.of<UserProvider>(context, listen: false).role;
        Navigator.of(context).pushReplacementNamed('/dashboard', arguments: providerRole);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.message ?? 'Sign up failed',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String? navRole = ModalRoute.of(context)?.settings.arguments as String?;
    final String? providerRole = Provider.of<UserProvider>(context).role;
    final String? role = navRole ?? providerRole;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Logo and branding section
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.1),
                            colorScheme.primary.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Icon(
                        Icons.handshake_rounded,
                        color: colorScheme.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to KaziLink',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (role != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.primaryContainer.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'Role: ${role[0].toUpperCase()}${role.substring(1)}',
                          style: GoogleFonts.poppins(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect Skills to Jobs',
                      style: GoogleFonts.poppins(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Auth container
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          // Tab bar
                          Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              labelColor: colorScheme.onPrimary,
                              unselectedLabelColor: colorScheme.onSurfaceVariant,
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: colorScheme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              tabs: [
                                Tab(
                                  child: Text(
                                    'Sign In',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Tab(
                                  child: Text(
                                    'Sign Up',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 480,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Sign In Tab
                                Form(
                                  key: _signInKey,
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        _buildTextField(
                                          label: 'Email',
                                          icon: Icons.email_rounded,
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                                          onSaved: (val) => _signInEmail = val ?? '',
                                        ),
                                        const SizedBox(height: 20),
                                        _buildPasswordField(
                                          label: 'Password',
                                          icon: Icons.lock_rounded,
                                          obscureText: _obscurePassword,
                                          onToggle: _togglePassword,
                                          validator: (val) => val == null || val.length < 6 ? 'Password too short' : null,
                                          onSaved: (val) => _signInPassword = val ?? '',
                                        ),
                                        const SizedBox(height: 16),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {},
                                            child: Text(
                                              'Forgot Password?',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        _buildPrimaryButton(
                                          onPressed: _loading ? null : _signIn,
                                          text: 'Sign In',
                                          loading: _loading,
                                        ),
                                        const SizedBox(height: 24),
                                        _buildDivider(),
                                        const SizedBox(height: 24),
                                        _buildGoogleButton('Sign in with Google'),
                                      ],
                                    ),
                                  ),
                                ),
                                // Sign Up Tab
                                Form(
                                  key: _signUpKey,
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        _buildTextField(
                                          label: 'Email',
                                          icon: Icons.email_rounded,
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                                          onSaved: (val) => _signUpEmail = val ?? '',
                                        ),
                                        const SizedBox(height: 20),
                                        _buildPasswordField(
                                          label: 'Password',
                                          icon: Icons.lock_rounded,
                                          obscureText: _obscurePassword,
                                          onToggle: _togglePassword,
                                          onChanged: (val) => setState(() => _signUpPasswordValue = val),
                                          validator: (val) => val == null || val.length < 6 ? 'Password too short' : null,
                                          onSaved: (val) => _signUpPassword = val ?? '',
                                        ),
                                        const SizedBox(height: 20),
                                        _buildPasswordField(
                                          label: 'Confirm Password',
                                          icon: Icons.lock_outline_rounded,
                                          obscureText: _obscureConfirm,
                                          onToggle: _toggleConfirm,
                                          validator: (val) => val != _signUpPasswordValue ? 'Passwords do not match' : null,
                                          onSaved: (val) => _signUpConfirm = val ?? '',
                                        ),
                                        const SizedBox(height: 24),
                                        _buildPrimaryButton(
                                          onPressed: _loading ? null : _signUp,
                                          text: 'Sign Up',
                                          loading: _loading,
                                        ),
                                        const SizedBox(height: 24),
                                        _buildDivider(),
                                        const SizedBox(height: 24),
                                        _buildGoogleButton('Sign up with Google'),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildPasswordField({
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: onToggle,
          tooltip: obscureText ? 'Show password' : 'Hide password',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      obscureText: obscureText,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required String text,
    required bool loading,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.outline.withOpacity(0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.poppins(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colorScheme.outline.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(
          Icons.g_mobiledata_rounded,
          color: Colors.red.shade600,
          size: 24,
        ),
        label: Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
} 