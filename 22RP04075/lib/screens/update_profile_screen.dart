import 'package:flutter/material.dart';
import '../db/database_helper_stub.dart'
    if (dart.library.io) '../db/database_helper.dart'
    if (dart.library.html) '../db/database_helper_hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateProfileScreen extends StatefulWidget {
  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  bool isPremium = false;
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController studyTimeController;
  int sessionsCreated = 0;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    studyTimeController = TextEditingController();
    _loadUserProfile();
    _loadPremiumStatus();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    studyTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      emailController.text = user.email ?? '';
      // Load additional info from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data['name'] ?? '';
      }
      // Load sessions count
      final sessions = await FirebaseFirestore.instance.collection('sessions').where('userId', isEqualTo: user.uid).get();
      setState(() {
        sessionsCreated = sessions.size;
        studyTimeController.text = sessionsCreated > 5 ? '09:00 AM - 06:00 PM' : '08:00 AM - 05:00 PM';
      });
    }
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final dbHelper = DatabaseHelper();
      final users = await dbHelper.getUsers();
      if (users.isNotEmpty && users.first['premium'] == true) {
        setState(() => isPremium = true);
      }
    } catch (_) {}
  }

  Future<void> _setPremiumStatus() async {
    final dbHelper = DatabaseHelper();
    final users = await dbHelper.getUsers();
    if (users.isNotEmpty) {
      final user = users.first;
      user['premium'] = true;
      if (dbHelper is dynamic && dbHelper.updateUser != null) {
        await dbHelper.updateUser(user);
      }
      setState(() => isPremium = true);
    }
  }

  void _showPayPalDialog() {
    final paymentNameController = TextEditingController();
    final paymentEmailController = TextEditingController();
    final paymentAmountController = TextEditingController(text: '10.00');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.blue),
            SizedBox(width: 8),
            Text('Pay with PayPal'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Fill in your payment details to unlock premium features.'),
            SizedBox(height: 12),
            TextField(
              controller: paymentNameController,
              decoration: InputDecoration(labelText: 'Name on Account'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: paymentEmailController,
              decoration: InputDecoration(labelText: 'PayPal Email'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: paymentAmountController,
              decoration: InputDecoration(labelText: 'Amount (USD)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && paymentNameController.text.isNotEmpty && paymentEmailController.text.isNotEmpty && paymentAmountController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('payments').add({
                  'uid': user.uid,
                  'name': paymentNameController.text.trim(),
                  'email': paymentEmailController.text.trim(),
                  'amount': paymentAmountController.text.trim(),
                  'timestamp': DateTime.now(),
                });
                Navigator.pop(context);
                await _setPremiumStatus();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment successful! You are now premium.')),
                );
              } else {
                // Show error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all payment fields.')),
                );
              }
            },
            child: Text('Pay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture and name
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.blueGrey[100],
                      child: Icon(Icons.person, size: 48, color: Colors.blueGrey[400]),
                    ),
                    SizedBox(height: 12),
                    _buildTextField(nameController, hintText: 'Your Full Name'),
                  ],
                ),
              ),

              SizedBox(height: 24),
              _sectionTitle('Contact Info'),

              _buildTextField(emailController, hintText: 'Email Address'),
              SizedBox(height: 16),

              _sectionTitle('Account Security'),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Account Security: ${sessionsCreated > 5 ? 'Strong (many sessions)' : 'Basic (few sessions)'}',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),

              SizedBox(height: 24),
              _sectionTitle('Study Preferences'),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Study Time: ${studyTimeController.text}',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),

              SizedBox(height: 16),
              Row(
                children: [
                  _infoCard('4', 'Hours / Day'),
                  SizedBox(width: 12),
                  _infoCard('5', 'Sessions / Week'),
                ],
              ),

              SizedBox(height: 24),
              if (isPremium)
                Chip(
                  label: Text('Premium User', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.amber[800],
                  avatar: Icon(Icons.star, color: Colors.white),
                ),

              if (!isPremium)
                ElevatedButton.icon(
                  onPressed: _showPayPalDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(Icons.workspace_premium),
                  label: Text('Upgrade to Premium'),
                ),

              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'name': nameController.text.trim(),
                        // Add more fields as needed
                      });
                      // Optionally show a snackbar or dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Profile updated!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[300],
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save Changes', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/find-partner');
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/join-session');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Partner'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Session'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller,
      {String? hintText, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _infoCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
