import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManagerAddEditEmployee extends StatefulWidget {
  const ManagerAddEditEmployee({Key? key}) : super(key: key);

  @override
  State<ManagerAddEditEmployee> createState() => _ManagerAddEditEmployeeState();
}

class _ManagerAddEditEmployeeState extends State<ManagerAddEditEmployee> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _role = 'Employee';
  bool _isLoading = false;

  Future<void> _addEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final managerId = FirebaseAuth.instance.currentUser?.uid;
      if (managerId == null) throw Exception('Manager not logged in');
      // Create employee user in Firebase Auth
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Store employee profile in Firestore
      await FirebaseFirestore.instance.collection('employees').doc(cred.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'department': _departmentController.text.trim(),
        'role': _role,
        'managerId': managerId,
        'createdAt': FieldValue.serverTimestamp(),
        'password': _passwordController.text.trim(), // Note: Storing plain password is insecure!
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee added successfully!')),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Failed to add employee.';
      if (e.code == 'email-already-in-use') msg = 'Email already in use.';
      if (e.code == 'weak-password') msg = 'Password is too weak.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add employee: $e')),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Employee'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email is required';
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');
                  if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
                validator: (value) => value == null || value.isEmpty ? 'Department is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                items: const [
                  DropdownMenuItem(value: 'Employee', child: Text('Employee')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() { _role = value!; });
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addEmployee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Add Employee', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 