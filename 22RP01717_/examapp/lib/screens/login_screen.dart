import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_screen.dart';
import 'trainer_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isLogin;
  const LoginScreen({Key? key, this.isLogin = true}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String? _error;
  bool _loading = false;
  bool _showPassword = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  Future<void> createUserIfNotExists(User firebaseUser) async {
    print('createUserIfNotExists called for UID: ${firebaseUser.uid}');
    final userDoc = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) {
      // Check if this is the first user
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final isFirstUser = usersSnapshot.docs.isEmpty;
      final userType = isFirstUser ? 'admin' : 'user';
      print('Assigning userType: $userType');
      try {
        await userDoc.set({
          'email': firebaseUser.email,
          'displayName': firebaseUser.displayName ?? '',
          'avatarUrl': '',
          'userType': userType,
          // If admin, add a flag for clarity
          if (isFirstUser) 'isManager': true,
        });
        print('User doc created successfully.');
      } catch (e) {
        print('Error creating user doc: $e');
      }
    } else {
      print('User doc already exists.');
    }
  }

  void _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      User? user;
      if (_isLogin) {
        user = await _authService.signIn(_emailController.text, _passwordController.text);
      } else {
        user = await _authService.signUp(_emailController.text, _passwordController.text);
      }
      if (user != null) {
        await createUserIfNotExists(user);
        // Manual test write to Firestore
        try {
          await FirebaseFirestore.instance.collection('test').add({'test': 'hello', 'uid': user.uid});
          print('Manual test write to Firestore succeeded.');
        } catch (e) {
          print('Manual test write to Firestore failed: $e');
        }
        // Fetch user doc and set in provider
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userModel = UserModel.fromMap(userDoc.data()!..['uid'] = user.uid);
          Provider.of<UserProvider>(context, listen: false).setUser(userModel);
          print('UserProvider set with user: ' + user.uid);
          // Route based on userType
          if (userModel.userType == 'trainer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TrainerDashboardScreen(
                  displayName: userModel.displayName,
                  email: userModel.email,
                ),
              ),
            );
            return;
          } else if (userModel.userType == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(), // HomeScreen will show AdminPanelScreen for admin
              ),
            );
            return;
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(),
              ),
            );
            return;
          }
        } else {
          print('User doc not found after creation!');
        }
      }
      // Navigate to home screen after successful login
      // (This is now handled above by userType check)
      if (_isLogin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        // After registration, go back to WelcomeScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! Please log in.')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F8FFF), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo or App Icon
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.indigo[100],
                          child: Icon(Icons.school, color: Colors.indigo, size: 40),
                        ),
                        SizedBox(height: 18),
                        Text(
                          _isLogin ? 'Login to your account' : 'Create a new account',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.indigo[900]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Welcome back! Please login to continue.' : 'Register to get started.',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.indigo[400]),
                        ),
                        SizedBox(height: 28),
                        Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email, color: Colors.indigo),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  filled: true,
                                  fillColor: Colors.indigo[50],
                                  hintText: 'Enter your email',
                                ),
                                style: TextStyle(color: Colors.indigo[900]),
                                validator: (val) => val != null && val.contains('@') ? null : 'Enter a valid email',
                              ),
                              SizedBox(height: 18),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock, color: Colors.indigo),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  filled: true,
                                  fillColor: Colors.indigo[50],
                                  hintText: 'Enter your password',
                                  suffixIcon: IconButton(
                                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.indigo),
                                    onPressed: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                  ),
                                ),
                                style: TextStyle(color: Colors.indigo[900]),
                                obscureText: !_showPassword,
                                validator: (val) => val != null && val.length >= 6 ? null : 'Password too short',
                              ),
                              SizedBox(height: 18),
                              if (_error != null)
                                Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(child: Text(_error!, style: TextStyle(color: Colors.red, fontSize: 14))),
                                    ],
                                  ),
                                ),
                              _loading
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: CircularProgressIndicator(color: Colors.indigo),
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState?.validate() ?? false) {
                                            _submit();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: Text(_isLogin ? 'Login' : 'Register'),
                                      ),
                                    ),
                              SizedBox(height: 16),
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: TextButton(
                                  key: ValueKey(_isLogin),
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                    });
                                  },
                                  child: Text(
                                    _isLogin
                                        ? "Don't have an account? Register"
                                        : "Already have an account? Login",
                                    style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // (Optional) Social login placeholder
                        // SizedBox(height: 18),
                        // Text('or', style: TextStyle(color: Colors.indigo[300])),
                        // SizedBox(height: 12),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     IconButton(icon: Icon(Icons.g_mobiledata, color: Colors.red), onPressed: () {}),
                        //     IconButton(icon: Icon(Icons.facebook, color: Colors.blue), onPressed: () {}),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}