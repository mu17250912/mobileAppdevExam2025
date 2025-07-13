import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return Scaffold(
          body: isWide
              ? Stack(
                  children: [
                    // Background image
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/home.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Semi-transparent overlayr
                    Positioned.fill(
                      child: Container(color: Colors.black.withOpacity(0.4)),
                    ),
                    // Branding and tagline at the top left
                    Positioned(
                      top: 40,
                      left: 32,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Bank Account Management ',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isWide ? 32.0 : 20.0,
                                ),
                              ),
                              Icon(
                                Icons.account_balance,
                                color: Colors.blueAccent,
                                size: isWide ? 32.0 : 20.0,
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Manage Your Finances &',
                            style: TextStyle(
                              color: isWide ? Colors.white : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: isWide ? 40.0 : 22.0,
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Innovation',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isWide ? 40.0 : 22.0,
                                  ),
                                ),
                                TextSpan(
                                  text: '\nPlatform',
                                  style: TextStyle(
                                    color: isWide ? Colors.white : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isWide ? 32.0 : 16.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Our system helps you manage your bank accounts,\n track transactions, view balances, and ensure secure access to your financial data.',
                            style: TextStyle(
                              color: isWide ? Colors.white : Colors.green,
                              fontSize: isWide ? 20.0 : 15.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {},
                            child: Text(
                              'JOIN US',
                              style: TextStyle(
                                fontSize: isWide ? 18.0 : 12.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Login card at the top right (or centered on small screens)
                    Positioned(
                      top: 40,
                      right: 32,
                      child: Container(
                        width: 420,
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Login Here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isWide ? 28.0 : 20.0,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: isWide ? 24 : 12),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Colors.orange,
                                ),
                                hintText: 'Enter Email Here',
                                filled: true,
                                fillColor: Colors.transparent,
                                hintStyle: TextStyle(
                                  color: Colors.orange,
                                  fontSize: isWide ? 18 : 14,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.orange,
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: isWide ? 16 : 12,
                              ),
                            ),
                            SizedBox(height: isWide ? 16 : 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.orange,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                hintText: 'Enter Password Here',
                                filled: true,
                                fillColor: Colors.transparent,
                                hintStyle: TextStyle(
                                  color: Colors.orange,
                                  fontSize: isWide ? 18 : 14,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.orange,
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: isWide ? 16 : 12,
                              ),
                            ),
                            SizedBox(height: isWide ? 24 : 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isWide ? 14 : 8,
                                ),
                              ),
                              onPressed: () async {
                                setState(() { _isLoading = true; });
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(child: CircularProgressIndicator()),
                                );
                                await Future.delayed(const Duration(seconds: 3));
                                Navigator.of(context).pop(); // Remove loading dialog
                                setState(() { _isLoading = false; });
                                final email = _emailController.text.trim();
                                final password = _passwordController.text
                                    .trim();
                                print(
                                  'Trying login: email=[$email], password=[$password]',
                                );
                                if (email.isNotEmpty && password.isNotEmpty) {
                                  try {
                                    // Print all users for debugging, safely handle missing fields
                                    final allUsers = await FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .get();
                                    for (var doc in allUsers.docs) {
                                      final data = doc.data();
                                      final userEmail =
                                          data.containsKey('email')
                                          ? data['email']
                                          : '(no email)';
                                      final userPassword =
                                          data.containsKey('password')
                                          ? data['password']
                                          : '(no password)';
                                      print(
                                        'User doc: email=[$userEmail], password=[$userPassword]',
                                      );
                                    }
                                    final query = await FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .where('email', isEqualTo: email)
                                        .where('password', isEqualTo: password)
                                        .get();
                                    if (query.docs.isNotEmpty) {
                                      final userData = query.docs.first.data();
                                      final username =
                                          userData['username'] ?? '';
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Login successful!'),
                                          ),
                                        );
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/dashboard',
                                          arguments: {
                                            'userEmail': email,
                                            'username': username,
                                          },
                                        );
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Incorrect email or password. Please try again.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'An error occurred: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter email and password.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: isWide ? 20.0 : 14.0,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.green),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/register',
                                    );
                                  },
                                  child: const Text(
                                    'Sign up',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Text(
                                  ' here',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Branding and tagline at the top left
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Bank Account Management ',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isWide ? 32.0 : 20.0,
                                  ),
                                ),
                                Icon(
                                  Icons.account_balance,
                                  color: Colors.blueAccent,
                                  size: isWide ? 32.0 : 20.0,
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Manage Your Finances &',
                              style: TextStyle(
                                color: isWide ? Colors.white : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: isWide ? 40.0 : 22.0,
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Innovation',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isWide ? 40.0 : 22.0,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '\nPlatform',
                                    style: TextStyle(
                                      color: isWide
                                          ? Colors.white
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isWide ? 32.0 : 16.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Our system helps you manage your bank accounts,\n track transactions, view balances, and ensure secure access to your financial data.',
                              style: TextStyle(
                                color: isWide ? Colors.white : Colors.green,
                                fontSize: isWide ? 20.0 : 15.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {},
                              child: Text(
                                'JOIN US',
                                style: TextStyle(
                                  fontSize: isWide ? 18.0 : 12.0,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Login Here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isWide ? 28.0 : 20.0,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: isWide ? 24 : 12),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.email,
                                    color: Colors.orange,
                                  ),
                                  hintText: 'Enter Email Here',
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  hintStyle: TextStyle(
                                    color: Colors.orange,
                                    fontSize: isWide ? 18 : 14,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.orange,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.orange,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: isWide ? 16 : 12,
                                ),
                              ),
                              SizedBox(height: isWide ? 16 : 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: Colors.orange,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  hintText: 'Enter Password Here',
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  hintStyle: TextStyle(
                                    color: Colors.orange,
                                    fontSize: isWide ? 18 : 14,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.orange,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.orange,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: isWide ? 16 : 12,
                                ),
                              ),
                              SizedBox(height: isWide ? 24 : 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () {
                                  // Handle email/password login
                                },
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: isWide ? 18.0 : 12.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(color: Colors.green),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/register',
                                      );
                                    },
                                    child: const Text(
                                      'Sign up',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    ' here',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Log in with',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.green),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Removed social login IconButtons
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
