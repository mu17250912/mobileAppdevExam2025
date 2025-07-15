import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManagerNotifications extends StatelessWidget {
  const ManagerNotifications({Key? key}) : super(key: key);

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchNotifications() async {
    final managerId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance.collection('notifications').where('managerId', isEqualTo: managerId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: _fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          docs.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications found.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final notif = docs[i].data();
              return ListTile(
                leading: const Icon(Icons.notifications, color: Colors.deepPurple),
                title: Text(notif['message'] ?? ''),
                subtitle: notif['createdAt'] != null ? Text((notif['createdAt'] as Timestamp).toDate().toLocal().toString()) : null,
              );
            },
          );
        },
      ),
    );
  }
} 