import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final start = DateTime.now();
    try {
      await AuthService().signInWithEmail(_emailController.text.trim(), _passwordController.text);
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final minDuration = 3000;
      if (elapsed < minDuration) {
        await Future.delayed(Duration(milliseconds: minDuration - elapsed));
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); });
      }
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  Future<void> _googleLogin() async {
    setState(() { _loading = true; _error = null; });
    final start = DateTime.now();
    try {
      await AuthService().signInWithGoogle();
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final minDuration = 3000;
      if (elapsed < minDuration) {
        await Future.delayed(Duration(milliseconds: minDuration - elapsed));
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); });
      }
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, color: Colors.white, size: 70),
              SizedBox(height: 18),
              Text('FITINITY', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 2)),
              SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                ),
              ),
              SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                ),
              ),
              SizedBox(height: 18),
              if (_error != null) Text(_error!, style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF22A6F2),
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: TextStyle(fontSize: 18),
                  elevation: 2,
                ),
                child: _loading ? CircularProgressIndicator() : Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _googleLogin,
                icon: Icon(Icons.login, color: const Color(0xFF22A6F2)),
                label: Text('Sign in with Google', style: TextStyle(color: const Color(0xFF22A6F2), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  side: BorderSide(color: Colors.white),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 18),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
                child: Text("Don't have an account? Sign up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 