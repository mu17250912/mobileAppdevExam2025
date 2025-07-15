import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Color(0xFF7B8AFF),
      ),
      backgroundColor: Color(0xFF7B8AFF),
      body: Center(
        child: Card(
          margin: EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF7B8AFF),
                  child: Icon(Icons.person, size: 48, color: Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'No Name',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  user?.email ?? 'No Email',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text('Edit Profile'),
                  onPressed: () {
                    // TODO: Implement edit profile functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Edit profile coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7B8AFF),
                    foregroundColor: Colors.white,
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