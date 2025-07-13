import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'register_screen.dart';
import 'role_selection_screen.dart';
import 'splash_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_service.dart';
import 'theme.dart';
import 'property_owner_main_screen.dart';
import 'login_screen.dart';
import 'renter_main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      // Sign in with FirebaseAuth
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userId = cred.user?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password.')),
        );
        return;
      }
      // Fetch user document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not found.')));
        return;
      }
      final user = userDoc.data()!;
      final role = user['role'] ?? 'renter/buyer';
      setState(() {
        _isLoading = false;
      });
      if (role == 'property_owner') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful!')));
        // Check wallet setup before navigating
        final hasWallet =
            user['walletProvider'] != null && user['walletNumber'] != null;
        if (!hasWallet) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              final _formKey = GlobalKey<FormState>();
              String provider = 'MTN';
              String walletNumber = '';
              bool isLoading = false;
              return Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Set Mobile Wallet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mobile Money Provider'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: provider,
                              items: const [
                                DropdownMenuItem(
                                  value: 'MTN',
                                  child: Text('MTN'),
                                ),
                                DropdownMenuItem(
                                  value: 'Airtel',
                                  child: Text('Airtel'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => provider = v ?? 'MTN'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Wallet Number'),
                            const SizedBox(height: 6),
                            TextFormField(
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: '07XXXXXXXX',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Enter wallet number'
                                  : null,
                              onChanged: (v) => walletNumber = v,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                label: isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save Wallet'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  minimumSize: const Size.fromHeight(44),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!.validate())
                                          return;
                                        setState(() => isLoading = true);
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .set({
                                              'walletProvider': provider,
                                              'walletNumber': walletNumber,
                                            }, SetOptions(merge: true));
                                        setState(() => isLoading = false);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Wallet saved!'),
                                          ),
                                        );
                                      },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blueGrey,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Used to receive payouts after bookings are confirmed.',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PropertyOwnerMainScreen()),
        );
      } else if (role == 'renter/buyer') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful!')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RenterMainScreen()),
        );
      } else if (role == 'admin') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful!')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role "$role" is not supported for this dashboard.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: \\${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                96,
              ), // leave space for button
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset('assets/images/logo.png', height: 80),
                      const SizedBox(height: 16),
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          color: Colors.red,
                          size: 22,
                        ),
                        label: const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          side: BorderSide(color: kPrimaryColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          minimumSize: const Size.fromHeight(44),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          final cred = await AuthService().signUpWithGoogle(
                            role: 'renter/buyer',
                          );
                          setState(() => _isLoading = false);
                          if (cred != null) {
                            // Fetch user role from Firestore
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(cred.user?.uid)
                                .get();
                            final role =
                                userDoc.data()?['role'] ?? 'renter/buyer';
                            if (role == 'property_owner') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Successfully signed in with Google!',
                                  ),
                                ),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PropertyOwnerMainScreen(),
                                ),
                              );
                            } else if (role == 'renter/buyer') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Successfully signed in with Google!',
                                  ),
                                ),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RenterMainScreen(),
                                ),
                              );
                            } else if (role == 'admin') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Successfully signed in with Google!',
                                  ),
                                ),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminDashboard(),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Role "$role" is not supported for this dashboard.',
                                  ),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Google sign-in failed or account not found.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Enter your email';
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                          if (!emailRegex.hasMatch(value))
                            return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                        ),
                        obscureText: true,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your password'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const Center(child: CustomLoadingIndicator())
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                minimumSize: const Size.fromHeight(44),
                              ),
                              child: const Text('Login'),
                            ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 12, // less padding at the bottom
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleSelectionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kPrimaryColor,
                  side: BorderSide(color: kPrimaryColor, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  minimumSize: const Size.fromHeight(40),
                ),
                child: const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder dashboards for role-based navigation
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(child: Text('Welcome, Admin!')),
    );
  }
}

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Dashboard')),
      body: const Center(child: Text('Welcome, Property Owner!')),
    );
  }
}

class RenterDashboard extends StatelessWidget {
  const RenterDashboard({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Renter Dashboard')),
      body: const Center(child: Text('Welcome, Renter!')),
    );
  }
}
