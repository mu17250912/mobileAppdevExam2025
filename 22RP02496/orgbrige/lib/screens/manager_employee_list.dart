import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManagerEmployeeList extends StatelessWidget {
  const ManagerEmployeeList({Key? key}) : super(key: key);

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchEmployees() async {
    final managerId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance.collection('employees').where('managerId', isEqualTo: managerId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: _fetchEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No employees found.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final emp = docs[i].data();
              return ListTile(
                leading: CircleAvatar(child: Text(emp['name']?[0] ?? '?')),
                title: Text(emp['name'] ?? ''),
                subtitle: Text('Email: \\${emp['email']}\nDepartment: \\${emp['department']}'),
                trailing: Text(emp['role'] ?? ''),
                onTap: () {}, // For future edit
              );
            },
          );
        },
      ),
    );
  }
} 