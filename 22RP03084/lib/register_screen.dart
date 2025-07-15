import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart'; // for kGoldenBrown
import '../swipe_screen.dart';
import '../employer_dashboard.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: kGoldenBrown,
      ),
      body: const Center(
        child: Text('Welcome! (Placeholder for swipe interface)'),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final VoidCallback onLoginTap;
  const RegisterScreen({super.key, required this.onLoginTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;
  String? _userType; // 'job_seeker' or 'employer'

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty || _userType == null) {
      setState(() {
        _loading = false;
        _error = 'All fields are required, including user type.';
      });
      return;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+ *');
    final phoneRegex = RegExp(r'^[0-9]{7,15} *');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _loading = false;
        _error = 'Please enter a valid email address.';
      });
      return;
    }
    if (!phoneRegex.hasMatch(phone)) {
      setState(() {
        _loading = false;
        _error = 'Please enter a valid phone number.';
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _loading = false;
        _error = 'Password must be at least 6 characters long.';
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _loading = false;
        _error = 'Passwords do not match.';
      });
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').add({
        'name': name,
        'email': email,
        'phone': phone,
        'userType': _userType,
        'password': password, // In production, never store plain passwords!
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _loading = false;
        _success = 'Registration successful!';
      });
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Registration failed. Please try again later.';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: kGoldenBrown,
      ),
      body: Center(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: kGoldenBrown),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email, color: kGoldenBrown),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone, color: kGoldenBrown),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock, color: kGoldenBrown),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline, color: kGoldenBrown),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Job Seeker'),
                    value: 'job_seeker',
                    groupValue: _userType,
                      activeColor: kGoldenBrown,
                    onChanged: (value) {
                      setState(() {
                        _userType = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Employer'),
                    value: 'employer',
                    groupValue: _userType,
                      activeColor: kGoldenBrown,
                    onChanged: (value) {
                      setState(() {
                        _userType = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
              if (_loading) const CircularProgressIndicator(color: kGoldenBrown),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            if (_success != null) ...[
              Text(_success!, style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: kGoldenBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _loading ? null : _register,
                child: const Text('Register'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onLoginTap,
              child: const Text(
                "Already have an account? Login",
                  style: TextStyle(color: kGoldenBrown, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            ),
        ),
      ),
    );
  }
} 