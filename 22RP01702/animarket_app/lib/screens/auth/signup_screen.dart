import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import 'package:provider/provider.dart';
import '../common/complete_profile_screen.dart';
import '../../main.dart'; // Import for AuthGate

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String name = '';
  UserRole selectedRole = UserRole.buyer;
  bool isLoading = false;
  final TextEditingController _confirmPasswordController = TextEditingController();

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signUpWithEmail(email, password, name, selectedRole);
        
        final user = Provider.of<AuthProvider>(context, listen: false).user;
        if (user != null && (user.phone.isEmpty || user.location.isEmpty)) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => CompleteProfileScreen()),
          );
        } else {
          // Navigate to dashboard as usual
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: ${e.toString()}')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle(selectedRole);
      
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null && (user.phone.isEmpty || user.location.isEmpty)) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => CompleteProfileScreen()),
        );
      } else {
        // Navigate to dashboard as usual
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign in failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kDarkText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    onChanged: (value) => name = value,
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                    onChanged: (value) => email = value,
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    onChanged: (value) => password = value,
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Re-enter Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please re-enter your password';
                      }
                      if (value != password) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Role Selection
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'I am a',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: UserRole.buyer,
                        child: Text('Buyer'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.farmer,
                        child: Text('Farmer/Seller'),
                      ),
                    ],
                    onChanged: (UserRole? value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  SizedBox(height: 16),
                  
                  // Divider with "or" text
                  Row(
                    children: [
                      Expanded(child: Divider(color: kGrayText)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: kGrayText)),
                      ),
                      Expanded(child: Divider(color: kGrayText)),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Google Sign In Button
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kDarkText,
                      side: BorderSide(color: kGrayText),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/google_logo.png',
                      height: 24,
                      width: 24,
                    ),
                    label: Text(
                      'Sign up with Google',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
