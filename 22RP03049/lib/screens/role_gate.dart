import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin/admin_dashboard.dart';
import 'routes_screen.dart';
import 'user_dashboard_screen.dart';
import '../main.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final role = data?['role'] ?? 'user';
        print('User role: $role'); // Debug print
        if (role == 'admin') {
          return const AdminDashboard();
        }
        return const MainScaffold();
      },
    );
  }
} 