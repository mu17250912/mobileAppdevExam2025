import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  String? emailError;
  String? phoneError;
  String? passwordError;
  String? confirmPasswordError;
  String selectedRole = 'customer';

  @override
  void initState() {
    super.initState();
    emailController.addListener(() {
      setState(() {});
    });
    phoneController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Enter a valid email';
    return null;
  }
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    if (value.length < 10) return 'Enter a valid phone number';
    return null;
  }
  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
  String? _validateConfirmPassword(String? value) {
    if (value != passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { isLoading = true; });
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final newUserId = userCredential.user!.uid;
      final referralCode = referralCodeController.text.trim();
      String? referredBy;
      if (referralCode.isNotEmpty && referralCode != newUserId) {
        final referrerDoc = await FirebaseFirestore.instance.collection('users').doc(referralCode).get();
        if (referrerDoc.exists) {
          referredBy = referralCode;
          // Increment referralCount and reward referrer
          await FirebaseFirestore.instance.collection('users').doc(referralCode).update({
            'referralCount': FieldValue.increment(1),
            'loyaltyPoints': FieldValue.increment(10),
          });
        }
      }
      await FirebaseFirestore.instance.collection('users').doc(newUserId).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': selectedRole,
        if (referredBy != null) 'referredBy': referredBy,
        'referralCount': 0,
        'loyaltyPoints': referredBy != null ? 10 : 0,
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': null, // notify all admins
        'title': 'New User Registered',
        'message': 'A new user has registered: ${nameController.text.trim()} (${emailController.text.trim()})',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });
      setState(() { isLoading = false; });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Success'),
          content: Text('Registration successful!${referredBy != null ? '\nReferral reward applied.' : ''}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() { isLoading = false; });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(e.message ?? 'Registration failed'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: (ModalRoute.of(context)?.canPop ?? false)
          ? AppBar(
              leading: BackButton(),
              title: Text('Register', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
              backgroundColor: theme.colorScheme.primary,
              elevation: 0,
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.png', height: 64),
                      const SizedBox(height: 18),
                      Text('Create Account', style: theme.textTheme.displaySmall, textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      Text('Sign up to get started', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Your name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Your phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => showPassword = !showPassword),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !showConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                          ),
                        ),
                        validator: _validateConfirmPassword,
                      ),
                      const SizedBox(height: 18),
                      // Role Selector Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Register as',
                          prefixIcon: Icon(Icons.verified_user),
                        ),
                        items: [
                          DropdownMenuItem(value: 'customer', child: Text('Customer')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => selectedRole = val);
                        },
                      ),
                      const SizedBox(height: 18),
                      // Referral Code Field
                      TextFormField(
                        controller: referralCodeController,
                        decoration: InputDecoration(
                          labelText: 'Referral Code (optional)',
                          hintText: 'Enter referral code if you have one',
                          prefixIcon: Icon(Icons.card_giftcard),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Register'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 2,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        onPressed: isLoading ? null : _register,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account?', style: theme.textTheme.bodyMedium),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 