import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_product_catalog.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'rwanda_colors.dart';

class UserAuthScreen extends StatefulWidget {
  const UserAuthScreen({Key? key}) : super(key: key);

  @override
  State<UserAuthScreen> createState() => _UserAuthScreenState();
}

class _UserAuthScreenState extends State<UserAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  bool _isLogin = true;
  String? _error;

  Future<void> _submit() async {
    setState(() => _error = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final referralCode = _referralController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password required');
      return;
    }
    try {
      UserCredential userCred;
      if (_isLogin) {
        userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        await FirebaseAnalytics.instance.logLogin(loginMethod: 'email');
      } else {
        userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        String? referredBy;
        if (referralCode.isNotEmpty) {
          // Check if referral code matches an existing user UID
          final refUser = await FirebaseFirestore.instance.collection('users').doc(referralCode).get();
          if (refUser.exists) {
            referredBy = referralCode;
          }
        }
        // Store user profile in Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'referralCode': userCred.user!.uid,
          if (referredBy != null) 'referredBy': referredBy,
        });
        await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email');
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserProductCatalog()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kRwandaBlue,
        title: Text(_isLogin ? 'User Login' : 'User Sign Up', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: kRwandaBlue.withOpacity(0.07),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),
                // Logo and app name
                FlutterLogo(size: 64),
                const SizedBox(height: 12),
                const Text('Shop Management App', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 32),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kRwandaBlue)),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kRwandaBlue)),
                          ),
                          obscureText: true,
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 18),
                          TextField(
                            controller: _referralController,
                            decoration: InputDecoration(
                              labelText: 'Referral Code (optional)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kRwandaGreen)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isLogin ? kRwandaBlue : kRwandaGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _submit,
                            child: Text(_isLogin ? 'Login' : 'Sign Up', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(_isLogin ? 'Don\'t have an account? Sign Up' : 'Already have an account? Login', style: TextStyle(color: kRwandaBlue, fontWeight: FontWeight.bold)),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
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