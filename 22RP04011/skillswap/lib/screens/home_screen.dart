import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If user is not logged in, redirect to login
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('SkillSwap Home')),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading user data.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('User data not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = data['fullName'] ?? '';
          final skillsOffered = data['skillsOffered'] ?? '';
          final skillsToLearn = data['skillsToLearn'] ?? '';
          final phone = data['phone'] ?? '';
          final email = data['email'] ?? '';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, $fullName!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text('Skills you offer: $skillsOffered'),
                Text('Skills you want to learn: $skillsToLearn'),
                Text('Phone: $phone'),
                Text('Email: $email'),
              ],
            ),
          );
        },
      ),
    );
  }
}
