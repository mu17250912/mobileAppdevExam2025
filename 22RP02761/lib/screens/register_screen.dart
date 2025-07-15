import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String selectedRole = 'donor';
  bool _isLoading = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleRegister(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final role = selectedRole;
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 6 characters long.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user already exists
      final isRegistered = await _authService.isUserRegistered(email);
      if (isRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User with this email already exists. Please login instead.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Register the user
      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        role: role,
        firstName: firstName,
        lastName: lastName,
      );

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        // Check if user already exists
        final isRegistered = await _authService.isUserRegistered(user.email ?? '');
        if (isRegistered) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google account already registered. Please login instead.'),
              backgroundColor: Colors.orange,
            ),
          );
          await _authService.signOut();
          return;
        }

        // Create user profile for new Google user
        await _authService.createUserProfile(user.uid, user.email ?? '', selectedRole);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Enhanced app title with red highlighting
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.person_add,
                        size: 60,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Join Our Mission',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Enhanced role dropdown
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Select Role',
                    labelStyle: TextStyle(color: Colors.red[700]),
                    prefixIcon: Icon(Icons.person, color: Colors.red[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'donor', child: Text('Blood Donor')),
                    DropdownMenuItem(value: 'collector', child: Text('Blood Collector')),
                  ],
                  onChanged: _isLoading ? null : (value) {
                    setState(() => selectedRole = value!);
                  },
                ),
                const SizedBox(height: 16),
                // Enhanced input fields
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    labelStyle: TextStyle(color: Colors.red[700]),
                    prefixIcon: Icon(Icons.person_outline, color: Colors.red[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    labelStyle: TextStyle(color: Colors.red[700]),
                    prefixIcon: Icon(Icons.person_outline, color: Colors.red[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.red[700]),
                    prefixIcon: Icon(Icons.email, color: Colors.red[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password (min 6 characters)',
                    labelStyle: TextStyle(color: Colors.red[700]),
                    prefixIcon: Icon(Icons.lock, color: Colors.red[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                  ),
                  obscureText: true,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 30),
                // Enhanced register button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => handleRegister(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                      shadowColor: Colors.red.withOpacity(0.5),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                // Enhanced Google sign-up button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login, color: Colors.red),
                    label: Text(
                      _isLoading ? 'Signing up...' : 'Sign up with Google',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isLoading ? null : handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Enhanced login link
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
                  ),
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
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
