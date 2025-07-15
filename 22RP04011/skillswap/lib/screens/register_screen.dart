import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _skillsOfferedController =
      TextEditingController();
  final TextEditingController _skillsToLearnController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _availability = 'Available';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) throw Exception("Registration failed.");

      final now = DateTime.now();
      final userDetails = UserDetails(
        uid: user.uid,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        skillsOffered: _skillsOfferedController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        skillsToLearn: _skillsToLearnController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        phone: _phoneController.text.trim(),
        availability: _availability,
        location: _locationController.text.trim(),
        isOnline: true,
        photoUrl: null,
        createdAt: now,
        updatedAt: now,
        fcmToken: null,
        lastTokenUpdate: null,
        lastTabIndex: 0,
        subscriptionStatus: null,
        subscriptionType: null,
        subscriptionExpiry: null,
      );
      try {
        await _firestore.collection('users').doc(user.uid).set(
              userDetails.toFirestore(),
              SetOptions(merge: true),
            );
        await UserDetails.ensureUserSubcollections(user.uid);
      } catch (e) {
        // Firestore write failed after Auth succeeded
        await _auth.signOut();
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Registration partially succeeded. Please try logging in, or contact support if you cannot access your account.';
        });
        return;
      }

      // Sign out the user after registration
      await _auth.signOut();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Registration successful! Please login with your credentials.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Registration failed. Please try again.';
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _skillsOfferedController.dispose();
    _skillsToLearnController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 32.0 : 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: isTablet ? 100 : 80,
                        height: isTablet ? 100 : 80,
                        decoration: BoxDecoration(
                          color: Colors.blue[800],
                          borderRadius:
                              BorderRadius.circular(isTablet ? 20 : 16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_add,
                          size: isTablet ? 50 : 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isTablet ? 24 : 16),
                      Text(
                        'Join SkillSwap',
                        style: TextStyle(
                          fontSize: isTablet ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: isTablet ? 8 : 4),
                      Text(
                        'Start your learning journey today',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTablet ? 40 : 24),

                // Personal Information Section
                _buildSectionTitle('Personal Information', isTablet),
                SizedBox(height: isTablet ? 16 : 12),

                _buildTextField(
                    _fullNameController, 'Full Name', Icons.person, isTablet),
                SizedBox(height: isTablet ? 16 : 12),

                _buildTextField(
                    _emailController, 'Email', Icons.email, isTablet,
                    keyboardType: TextInputType.emailAddress),
                SizedBox(height: isTablet ? 16 : 12),

                _buildTextField(
                    _passwordController, 'Password', Icons.lock, isTablet,
                    keyboardType: TextInputType.text,
                    obscureText: _obscurePassword, onSuffixPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                }),
                SizedBox(height: isTablet ? 16 : 12),

                _buildTextField(_confirmPasswordController, 'Confirm Password',
                    Icons.lock, isTablet,
                    keyboardType: TextInputType.text,
                    obscureText: _obscureConfirmPassword, onSuffixPressed: () {
                  setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword);
                }),
                SizedBox(height: isTablet ? 16 : 12),

                _buildTextField(
                    _phoneController, 'Phone', Icons.phone, isTablet,
                    keyboardType: TextInputType.phone),
                SizedBox(height: isTablet ? 16 : 12),

                _buildTextField(_locationController, 'Location',
                    Icons.location_on, isTablet),
                SizedBox(height: isTablet ? 24 : 16),

                // Skills Section
                _buildSectionTitle('Skills & Interests', isTablet),
                SizedBox(height: isTablet ? 16 : 12),

                _buildTextField(
                    _skillsOfferedController,
                    'Skills You Can Teach (comma separated)',
                    Icons.settings,
                    isTablet),
                SizedBox(height: isTablet ? 16 : 12),

                _buildTextField(
                    _skillsToLearnController,
                    'Skills You Want to Learn (comma separated)',
                    Icons.school,
                    isTablet),
                SizedBox(height: isTablet ? 16 : 12),

                // Availability Dropdown
                DropdownButtonFormField<String>(
                  value: _availability,
                  items: ['Available', 'Busy', 'Offline'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Availability',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 16 : 12),
                  ),
                  onChanged: (newValue) {
                    setState(() {
                      _availability = newValue!;
                    });
                  },
                ),
                SizedBox(height: isTablet ? 24 : 16),

                // Error message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) SizedBox(height: isTablet ? 24 : 16),

                // Register button
                SizedBox(
                  width: double.infinity,
                  height: isTablet ? 56 : 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: isTablet ? 32 : 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 32 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isTablet) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isTablet ? 20 : 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isTablet, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    VoidCallback? onSuffixPressed,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: 'Enter $label',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16, vertical: isTablet ? 16 : 12),
        suffixIcon: onSuffixPressed != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: onSuffixPressed,
              )
            : null,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }

        // Email validation
        if (label == 'Email') {
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
        }

        // Password validation
        if (label == 'Password') {
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
        }

        // Confirm password validation
        if (label == 'Confirm Password') {
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
        }

        return null;
      },
    );
  }
}
