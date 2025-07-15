import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Uint8List? certificateBytes;
  String? certificateName;
  String? certificateUrl;
  String? certificateError;

  Future<bool> isIdNumberUnique(String idNumber) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('idNumber', isEqualTo: idNumber)
        .get();
    return query.docs.isEmpty;
  }

  Future<bool> isTelephoneUnique(String telephone) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('telephone', isEqualTo: telephone)
        .get();
    return query.docs.isEmpty;
  }

  Future<void> registerUser({
    required String idNumber,
    required String fullName,
    required String telephone,
    required String email,
    required String password,
  }) async {
    try {
      // Uniqueness checks
      bool idUnique = await isIdNumberUnique(idNumber);
      bool telUnique = await isTelephoneUnique(telephone);
      if (!idUnique) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ID Number already exists.')),
        );
        return;
      }
      if (!telUnique) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Telephone number already exists.')),
        );
        return;
      }
      // Step 1: Register the user using Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      // Step 2: Save extra user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'idNumber': idNumber,
        'fullName': fullName,
        'telephone': telephone,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'documents': [],
      });
      print("✅ User registered and saved in Firestore.");
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: {
          'isAdmin': false,
          'isLoggedIn': true,
          'userEmail': email,
        },
      );
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth error: \\${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } catch (e) {
      print("General error: \\${e}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: \\${e.toString()}')),
      );
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (certificateBytes == null) {
        setState(() {
          certificateError = 'You must upload a certificate to register.';
        });
        return;
      }
      setState(() {
        certificateError = null;
      });
      // Upload certificate to Firebase Storage
      String? uploadedCertificateUrl;
      if (certificateBytes != null && certificateName != null) {
        final ref = FirebaseStorage.instance.ref().child('documents/certificates/${idController.text}_${DateTime.now().millisecondsSinceEpoch}_$certificateName');
        await ref.putData(certificateBytes!);
        uploadedCertificateUrl = await ref.getDownloadURL();
      }
      await registerUser(
        idNumber: idController.text.trim(),
        fullName: nameController.text.trim(),
        telephone: phoneController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/me.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: idController,
                    decoration: InputDecoration(labelText: 'ID Number'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter ID number';
                      }
                      if (!RegExp(r'^\d{16}?$').hasMatch(value)) {
                        return 'ID must be exactly 16 digits';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Full Name'),
                    validator: (value) => value!.isEmpty ? 'Enter full name' : null,
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Telephone'),
                    validator: (value) => value!.isEmpty ? 'Enter telephone' : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (value) => value!.isEmpty ? 'Enter email' : null,
                  ),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'Enter password' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await registerUser(
                          idNumber: idController.text.trim(),
                          fullName: nameController.text.trim(),
                          telephone: phoneController.text.trim(),
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );
                      }
                    },
                    child: Text('Register'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 