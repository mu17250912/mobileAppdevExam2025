import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:hive/hive.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  String? _success;
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() { _isLoading = true; _error = null; });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      var userBox = await Hive.openBox('users');
      if (userBox.containsKey(email)) {
        setState(() { _isLoading = false; _error = 'Email already registered'; });
        return;
      }
      await userBox.put(email, {'email': email, 'password': password});
      setState(() { _isLoading = false; });
      // Navigate to LoginScreen and show success dialog there
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(showSuccessDialog: true),
          ),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Registration failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24, vertical: 32),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // App icon
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.deepPurple[100],
                          child: Icon(Icons.agriculture, size: 48, color: Colors.deepPurple[700], semanticLabel: 'Agriculture Icon'),
                        ),
                        const SizedBox(height: 16),
                        Text('Register', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple[700], letterSpacing: 1)),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email, color: Colors.deepPurple, semanticLabel: 'Email Icon'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.deepPurple[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock, color: Colors.deepPurple, semanticLabel: 'Password Icon'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.deepPurple[50],
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(_error!, style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                          ),
                        if (_success != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(_success!, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _register,
                            icon: Icon(Icons.app_registration, color: Colors.deepPurple, semanticLabel: 'Register Button Icon'),
                            label: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Register', style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account?', style: TextStyle(color: Colors.grey[700])),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                              },
                              icon: Icon(Icons.login, color: Colors.deepPurple, semanticLabel: 'Login Icon'),
                              label: Text('Login', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 