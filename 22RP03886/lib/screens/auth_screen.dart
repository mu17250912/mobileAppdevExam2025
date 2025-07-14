import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AuthScreen extends StatefulWidget {
  final bool startWithSignUp;
  const AuthScreen({Key? key, this.startWithSignUp = false}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isLogin;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isLogin = !widget.startWithSignUp;
  }

  void _submit() async {
    // Validate inputs
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter your email address';
      });
      return;
    }
    
    if (_passwordController.text.isEmpty) {
      setState(() {
        _error = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      if (_isLogin) {
        await userProvider.signIn(_emailController.text.trim(), _passwordController.text);
        // Navigate to home on successful login
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        await userProvider.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // Navigate to home on successful signup
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 64),
                Image.network(
                  'https://i.postimg.cc/ryG8PfSY/Screenshot-2025-07-10-221456.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 20),
                Text('Smart Daily Planner', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 40),
                // Add Register button for easy access
                if (_isLogin) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/register');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF3975F6),
                        side: BorderSide(color: Color(0xFF3975F6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: Size(double.infinity, 48),
                      ),
                      child: Text('New User? Create Account', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                if (_error != null) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Forgot password?'),
                  ),
                ),
                SizedBox(height: 16),
                _isLoading
                    ? Container(
                        width: double.infinity,
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                          backgroundColor: Color(0xFF3975F6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _isLogin ? 'Log in' : 'Sign Up',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.login),
                  label: Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          final userProvider = Provider.of<UserProvider>(context, listen: false);
                          try {
                            await userProvider.signInWithGoogle();
                          } catch (e) {
                            setState(() {
                              _error = e.toString();
                            });
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(_isLogin ? 'Sign Up' : 'Already have an account? Log in'),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 