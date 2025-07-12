import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../clients/client_home.dart';
import '../sellers/seller_home.dart';
import 'register_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kBackgroundColor = Color(0xFFF5F6FA);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final (userCredential, errorMessage) = await _authService.signInWithEmail(
      email,
      password,
    );

    if (userCredential != null) {
      // Log login event
      await FirebaseAnalytics.instance.logEvent(
        name: 'login',
        parameters: {
          'user_id': userCredential.user!.uid,
          'login_method': 'email',
        },
      );
      final role = await _authService.getUserRole(userCredential.user!.uid);
      _navigateToDashboard(role);
    } else {
      _showError(errorMessage ?? "Login failed");
    }
  }

  void _loginWithGoogle() async {
    final (userCredential, errorMessage) = await _authService
        .signInWithGoogle();

    if (userCredential != null) {
      // Log login event
      await FirebaseAnalytics.instance.logEvent(
        name: 'login',
        parameters: {
          'user_id': userCredential.user!.uid,
          'login_method': 'google',
        },
      );
      final role = await _authService.getUserRole(userCredential.user!.uid);
      _navigateToDashboard(role);
    } else {
      _showError(errorMessage ?? "Google Sign-In failed");
    }
  }

  void _navigateToDashboard(String? role) {
    if (role == 'seller') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerHomePage()),
      );
    } else if (role == 'buyer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClientHomePage()),
      );
    } else {
      _showError('User role not found.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'PhoneStore',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email, color: kPrimaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock, color: kPrimaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _loginWithEmail,
                          child: const Text("Login with Email"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Image.network(
                            'https://i.postimg.cc/8khbKp14/icons8-google-48.png',
                            height: 24,
                            width: 24,
                          ),
                          label: const Text("Continue with Google"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: BorderSide(color: kPrimaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _loginWithGoogle,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Don't have an account? Register here",
                          style: TextStyle(color: kPrimaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
