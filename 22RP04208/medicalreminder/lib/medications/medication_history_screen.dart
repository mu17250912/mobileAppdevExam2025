import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MedicationHistoryScreen extends StatelessWidget {
  const MedicationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Medication History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('medication_history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No history yet.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final medName = data['medicationName'] ?? '';
              final status = data['status'] ?? 'taken';
              final ts = data['timestamp'] != null ? DateTime.tryParse(data['timestamp']) : null;
              return ListTile(
                leading: Icon(
                  status == 'taken' ? Icons.check_circle : Icons.cancel,
                  color: status == 'taken' ? Colors.green : Colors.red,
                ),
                title: Text(medName),
                subtitle: Text(status == 'taken' ? 'Taken' : 'Missed'),
                trailing: Text(ts != null ? DateFormat('yMMMd h:mm a').format(ts) : ''),
              );
            },
          );
        },
      ),
    );
  }
} 