import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPinController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final String _registerAs = 'User';
  bool _obscurePin = true;
  bool _regObscurePin = true;
  bool _acceptTerms = false;
  String? _loginError;
  String? _registerError;
  bool _isLoadingLogin = false;
  bool _isLoadingRegister = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    _phoneController.dispose();
    _regEmailController.dispose();
    _regPinController.dispose();
    _regPhoneController.dispose();
    super.dispose();
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loginError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_loginError!, style: const TextStyle(color: Colors.red)),
              ),
            const Text('Email'),
            const SizedBox(height: 4),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'e.g. example@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Text('PIN'),
            const SizedBox(height: 4),
            TextField(
              controller: _pinController,
              obscureText: _obscurePin,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'PIN (6 digits)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
                counterText: '',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 4),
            const Text('6 digits (0-9)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('Mobile number (optional)'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Text('🇷🇼', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 4),
                      Text('+250', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 78xxxxxxxx (optional)',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Enter your phone number without the country code (optional).', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD6E53B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                onPressed: _isLoadingLogin ? null : () async {
                  setState(() { _isLoadingLogin = true; _loginError = null; });
                  try {
                    final email = _emailController.text.trim();
                    final pin = _pinController.text.trim();
                    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pin);
                    await logAdminEvent('login', {});
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    setState(() { _loginError = 'Login failed: \n${e.toString()}'; });
                  } finally {
                    setState(() { _isLoadingLogin = false; });
                  }
                },
                child: _isLoadingLogin ? const CircularProgressIndicator() : const Text('LOG IN'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Forgot PIN?', style: TextStyle(decoration: TextDecoration.underline)),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text("Don't have an account? Join", style: TextStyle(decoration: TextDecoration.underline)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_registerError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_registerError!, style: const TextStyle(color: Colors.red)),
              ),
            const Text('Email'),
            const SizedBox(height: 4),
            TextField(
              controller: _regEmailController,
              decoration: const InputDecoration(
                hintText: 'e.g. example@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Text('PIN'),
            const SizedBox(height: 4),
            TextField(
              controller: _regPinController,
              obscureText: _regObscurePin,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'PIN (6 digits)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_regObscurePin ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _regObscurePin = !_regObscurePin),
                ),
                counterText: '',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 4),
            const Text('6 digits (0-9)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('Mobile number (optional)'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Text('🇷🇼', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 4),
                      Text('+250', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _regPhoneController,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 78xxxxxxxx (optional)',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Enter your phone number without the country code (optional).', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                ),
                const Expanded(
                  child: Text(
                    'By creating an account you confirm that you are over 18 years old, and accept the Terms and Conditions',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD6E53B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                onPressed: _isLoadingRegister ? null : () async {
                  setState(() { _registerError = null; });
                  final email = _regEmailController.text.trim();
                  final pin = _regPinController.text.trim();
                  setState(() { _isLoadingRegister = true; });
                  try {
                    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pin);
                    await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                      'email': email,
                      'phone': _regPhoneController.text.trim(),
                      'role': 'user', // always set to user
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    await logAdminEvent('register', {'role': 'user'});
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    setState(() { _registerError = 'Registration failed: \n${e.toString()}'; });
                  } finally {
                    setState(() { _isLoadingRegister = false; });
                  }
                },
                child: _isLoadingRegister ? const CircularProgressIndicator() : const Text('JOIN'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => _tabController.animateTo(0),
                child: const Text('Already have an account? Log In', style: TextStyle(decoration: TextDecoration.underline)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/splash_screen/splash.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Container(
                  width: 400,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF2196F3),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF2196F3),
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(icon: Icon(Icons.login), text: 'Log In'),
                          Tab(icon: Icon(Icons.person_add), text: 'Join'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 500,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLoginForm(),
                            _buildJoinForm(),
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
    );
  }
} 