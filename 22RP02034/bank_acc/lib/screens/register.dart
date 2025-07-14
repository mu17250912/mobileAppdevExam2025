import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool agree = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Add TextEditingControllers for the fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return Scaffold(
          resizeToAvoidBottomInset: true,
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
                    // Semi-transparent overlay
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
                                  fontSize: 32.0,
                                ),
                              ),
                              Icon(
                                Icons.account_balance,
                                color: Colors.blueAccent,
                                size: 32.0,
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
                                    fontSize: 40.0,
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
                                fontSize: 18.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Register card at the top right
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
                              'Register Here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 28.0,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 24),
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Colors.orange,
                                ),
                                hintText: 'Enter Username',
                                filled: true,
                                fillColor: Colors.transparent,
                                hintStyle: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 18,
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
                                fontSize: 16.0,
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Colors.orange,
                                ),
                                hintText: 'Enter Email',
                                filled: true,
                                fillColor: Colors.transparent,
                                hintStyle: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 18,
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
                                fontSize: 16.0,
                              ),
                            ),
                            SizedBox(height: 16),
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
                                hintText: 'Enter Password',
                                filled: true,
                                fillColor: Colors.transparent,
                                hintStyle: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 18,
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
                                fontSize: 16.0,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: agree,
                                  activeColor: Colors.orange,
                                  onChanged: (val) {
                                    setState(() {
                                      agree = val ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    'I agree to the terms & conditions',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: agree
                                  ? () async {
                                      setState(() { _isLoading = true; });
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => const Center(child: CircularProgressIndicator()),
                                      );
                                      await Future.delayed(const Duration(seconds: 3));
                                      Navigator.of(context).pop(); // Remove loading dialog
                                      setState(() { _isLoading = false; });
                                      final username = _usernameController.text;
                                      final email = _emailController.text;
                                      final password = _passwordController.text;
                                      if (username.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
                                        try {
                                          // Check if email already exists
                                          final query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
                                          if (query.docs.isNotEmpty) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Email already registered. Please login.')),
                                              );
                                            }
                                            return;
                                          }
                                          await FirebaseFirestore.instance.collection('users').add({
                                            'username': username,
                                            'email': email,
                                            'password': password,
                                            'createdAt': FieldValue.serverTimestamp(),
                                          });
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Registration successful! Please login.')),
                                            );
                                            Navigator.pushReplacementNamed(context, '/login');
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('An error occurred: $e')),
                                            );
                                          }
                                        }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Please fill all fields and agree to terms.')),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                              child: Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(color: Colors.green),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/login',
                                    );
                                  },
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                        // Branding and tagline at the top
                        Row(
                          children: [
                            Text(
                              'Bank Account Management ',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0,
                              ),
                            ),
                            Icon(
                              Icons.account_balance,
                              color: Colors.blueAccent,
                              size: 20.0,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Manage Your Finances &',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 22.0,
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
                                  fontSize: 22.0,
                                ),
                              ),
                              TextSpan(
                                text: '\nPlatform',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        if (isWide)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Our system helps you manage your bank accounts, \ntrack transactions, view balances, and ensure secure access to your financial data.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          Text(
                            'Our system helps you manage your bank accounts, \ntrack transactions, view balances, and ensure secure access to your financial data.',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 15.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        SizedBox(height: 16),
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
                              fontSize: 12.0,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        // Register form card below branding
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
                                'Register Here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28.0,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 24),
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: Colors.orange,
                                  ),
                                  hintText: 'Enter Username',
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  hintStyle: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 18,
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
                                  fontSize: 16.0,
                                ),
                              ),
                              SizedBox(height: 16),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.email,
                                    color: Colors.orange,
                                  ),
                                  hintText: 'Enter Email',
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  hintStyle: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 18,
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
                                  fontSize: 16.0,
                                ),
                              ),
                              SizedBox(height: 16),
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
                                  hintText: 'Enter Password',
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  hintStyle: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 18,
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
                                  fontSize: 16.0,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: agree,
                                    activeColor: Colors.orange,
                                    onChanged: (val) {
                                      setState(() {
                                        agree = val ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Text(
                                      'I agree to the terms & conditions',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: agree
                                    ? () async {
                                        setState(() { _isLoading = true; });
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => const Center(child: CircularProgressIndicator()),
                                        );
                                        await Future.delayed(const Duration(seconds: 3));
                                        Navigator.of(context).pop(); // Remove loading dialog
                                        setState(() { _isLoading = false; });
                                        final username = _usernameController.text;
                                        final email = _emailController.text;
                                        final password = _passwordController.text;
                                        if (username.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
                                          try {
                                            // Check if email already exists
                                            final query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
                                            if (query.docs.isNotEmpty) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Email already registered. Please login.')),
                                                );
                                              }
                                              return;
                                            }
                                            await FirebaseFirestore.instance.collection('users').add({
                                              'username': username,
                                              'email': email,
                                              'password': password,
                                              'createdAt': FieldValue.serverTimestamp(),
                                            });
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Registration successful! Please login.')),
                                              );
                                              Navigator.pushReplacementNamed(context, '/login');
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('An error occurred: $e')),
                                              );
                                            }
                                          }
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Please fill all fields and agree to terms.')),
                                            );
                                          }
                                        }
                                      }
                                    : null,
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account? ',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/login',
                                      );
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
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
                ),
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
