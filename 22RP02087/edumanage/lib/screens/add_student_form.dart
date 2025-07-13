import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddStudentForm extends StatefulWidget {
  const AddStudentForm({Key? key}) : super(key: key);

  @override
  State<AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends State<AddStudentForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  String? _selectedGender;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Student'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Add New Student',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create a new student account with login credentials',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            
            // Full Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            
            // Student ID
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: 'Student ID *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            SizedBox(height: 16),
            
            // Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),
            
            // Password
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Password *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Confirm Password
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Gender Selection
            Text('Gender:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Male'),
                    value: 'Male',
                    groupValue: _selectedGender,
                    onChanged: (value) => setState(() => _selectedGender = value),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Female'),
                    value: 'Female',
                    groupValue: _selectedGender,
                    onChanged: (value) => setState(() => _selectedGender = value),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Add Student Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Add Student',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            SizedBox(height: 16),
            
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Student Account Created',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The student will be able to log in using their email and password. '
                      'They will have access to view their grades and attendance records.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStudent() async {
    // Validate all fields
    final name = _nameController.text.trim();
    final studentId = _idController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final gender = _selectedGender;

    if (name.isEmpty || studentId.isEmpty || email.isEmpty || 
        password.isEmpty || confirmPassword.isEmpty || gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 6 characters long.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password confirmation
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if email already exists in Firestore
      final existingUser = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: email)
          .get();

      if (existingUser.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A student with this email already exists.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Check if student ID already exists
      final existingStudentId = await FirebaseFirestore.instance
          .collection('students')
          .where('studentId', isEqualTo: studentId)
          .get();

      if (existingStudentId.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A student with this ID already exists.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Create Firebase Auth account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add student to Firestore
      await FirebaseFirestore.instance.collection('students').add({
        'name': name,
        'studentId': studentId,
        'email': email,
        'gender': gender,
        'role': 'Student', // Always set as Student for admin-created accounts
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user?.uid, // Link to Firebase Auth UID
      });

      // Clear form
      _nameController.clear();
      _idController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() => _selectedGender = null);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to admin dashboard
      Navigator.pushReplacementNamed(context, '/admin_dashboard');

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to create student account.';
      
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
} 