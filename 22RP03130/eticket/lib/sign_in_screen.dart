import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_home_screen.dart';
import 'user_home_screen.dart';
import 'organizer_home_screen.dart';
// import 'organizer_home_screen.dart'; // Uncomment if you have this screen

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  bool _loading = false;
  String? _error;

  // Email/password controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  void _showError(String? error) {
    setState(() => _error = error);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _handleUserPostLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    print('Current UID: [32m[1m[4m[7m[41m[42m[43m[44m[45m[46m[47m[100m[101m[102m[103m[104m[105m[106m[107m${user.uid}[0m');
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    print('User doc exists: ${doc.exists}');
    print('User doc data: ${doc.data()}');
    final role = doc.data()?['role'];
    print('Role: $role');
    if (doc.exists && role == 'user') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserHomeScreen()));
    } else {
      _showError('Account not yet activated.');
    }
  }

  Future<void> _handleOrganizerPostLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = doc.data()?['role'];
    if (doc.exists && role == 'organizer') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrganizerHomeScreen()));
    } else {
      _showError('Account not yet activated for organizer.');
    }
  }

  Future<void> _handleAdminPostLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = doc.data()?['role'];
    if (doc.exists && role == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
    } else {
      if (user.email == 'herveishimwe740@gmail.com') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
      } else {
        _showError('Account not yet activated for admin.');
      }
    }
  }

  Widget _buildUserTab() {
    return Column(
      children: [
        Text('Register with email:', style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 12),
        TextField(
          controller: _registerEmailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerPasswordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() { _loading = true; _error = null; });
                  try {
                    await _authService.registerWithEmail(
                      _registerEmailController.text.trim(),
                      _registerPasswordController.text.trim(),
                    );
                    // After registration, navigate to sign-in screen
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    );
                  } catch (e) {
                    _showError('Registration failed: $e');
                  } finally {
                    setState(() => _loading = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Register as User'),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        Text('Already have an account? Login:', style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        // Add Forgot Password button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              if (_emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter your email first.')),
                );
                return;
              }
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: _emailController.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password reset email sent!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ' + e.toString())),
                );
              }
            },
            child: Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() { _loading = true; _error = null; });
                  try {
                    await _authService.signInWithEmail(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );
                    await _handleUserPostLogin();
                  } catch (e) {
                    _showError('Login failed: $e');
                  } finally {
                    setState(() => _loading = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Login as User'),
        ),
      ],
    );
  }

  Widget _buildEmailLoginTab(String role) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() { _loading = true; _error = null; });
                  try {
                    await _authService.signInWithEmail(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );
                    if (role == 'Organizer') {
                      await _handleOrganizerPostLogin();
                    } else if (role == 'Admin') {
                      await _handleAdminPostLogin();
                    }
                  } catch (e) {
                    _showError('Sign in failed: $e');
                  } finally {
                    setState(() => _loading = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: Text('Login as $role'),
        ),
        const SizedBox(height: 12),
        if (role == 'Organizer')
          Text('Ask your admin for account access.', style: TextStyle(color: Colors.grey[700])),
        if (role == 'Admin')
          Text('Admin accounts are created manually.', style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.confirmation_num, size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text('Event organizer', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 24),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.deepPurple,
                  tabs: const [
                    Tab(text: 'User'),
                    Tab(text: 'Organizer'),
                    Tab(text: 'Admin'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 340,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(child: _buildUserTab()),
                      SingleChildScrollView(child: _buildEmailLoginTab('Organizer')),
                      SingleChildScrollView(child: _buildEmailLoginTab('Admin')),
                    ],
                  ),
                ),
                if (_loading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 