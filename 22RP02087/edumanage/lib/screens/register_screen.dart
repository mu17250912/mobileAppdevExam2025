import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? _selectedGender;
  String? _selectedRole;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // New controller

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Register',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _studentIdController,
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Gender:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'Male',
                          groupValue: _selectedGender,
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                        ),
                        const Text('Male'),
                        Radio<String>(
                          value: 'Female',
                          groupValue: _selectedGender,
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                        ),
                        const Text('Female'),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Role:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      hint: const Text('Select'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Admin',
                          child: Text('Admin'),
                        ),
                        DropdownMenuItem(
                          value: 'Student',
                          child: Text('Student'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_isLoading) return;
                    setState(() {
                      _isLoading = true;
                    });

                    final name = _nameController.text.trim();
                    final studentId = _studentIdController.text.trim();
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();
                    final confirmPassword = _confirmPasswordController.text.trim();
                    final gender = _selectedGender;
                    final role = _selectedRole;

                    if (name.isEmpty ||
                        studentId.isEmpty ||
                        email.isEmpty ||
                        password.isEmpty ||
                        confirmPassword.isEmpty ||
                        gender == null ||
                        role == null) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields.')),
                      );
                      return;
                    }

                    if (password != confirmPassword) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match.')),
                      );
                      return;
                    }

                    try {
                      // Register with Firebase Auth
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      // Add user to Firestore
                      await FirebaseFirestore.instance.collection('students').add({
                        'name': name,
                        'studentId': studentId,
                        'email': email,
                        'gender': gender,
                        'role': role,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      setState(() {
                        _isLoading = false;
                        _nameController.clear();
                        _studentIdController.clear();
                        _emailController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                        _selectedGender = null;
                        _selectedRole = null;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registration successful! Please log in.')),
                      );

                      await Future.delayed(const Duration(seconds: 1));
                      Navigator.pushReplacementNamed(context, '/login');
                    } on FirebaseAuthException catch (e) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message ?? 'Registration failed.')),
                      );
                    } catch (e) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Registration failed: ${e.toString()}')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Changed button color to green
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
