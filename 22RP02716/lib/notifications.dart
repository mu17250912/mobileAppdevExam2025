import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'jobseeker_dashboard.dart'; // For JobseekerBottomNavBar

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('user_id', isEqualTo: user.uid)
            //.orderBy('created_at', descending: true) // Removed to avoid index requirement
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load notifications', style: TextStyle(color: Colors.red)));
          }
          final notifications = snapshot.data?.docs ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final notif = notifications[i].data() as Map<String, dynamic>;
              final type = notif['type'] ?? 'info';
              final message = notif['message'] ?? '';
              final timestamp = notif['created_at'] != null && notif['created_at'] is Timestamp
                  ? (notif['created_at'] as Timestamp).toDate()
                  : null;
              final isRead = notif['read'] == true;
              IconData icon;
              Color color;
              switch (type) {
                case 'success':
                  icon = Icons.check_circle;
                  color = Colors.green;
                  break;
                case 'error':
                  icon = Icons.error;
                  color = Colors.red;
                  break;
                case 'history':
                  icon = Icons.history;
                  color = Colors.blueGrey;
                  break;
                case 'job_saved':
                  icon = Icons.bookmark;
                  color = Colors.blue;
                  break;
                case 'application_submitted':
                  icon = Icons.send;
                  color = Colors.orange;
                  break;
                case 'premium_update':
                  icon = Icons.star;
                  color = Colors.amber;
                  break;
                default:
                  icon = Icons.notifications;
                  color = Colors.blue;
              }
              return Card(
                elevation: isRead ? 1 : 4,
                color: isRead ? Colors.white : Colors.blue[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(
                    message,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: isRead ? Colors.black87 : Colors.blue[900],
                    ),
                  ),
                  subtitle: timestamp != null
                      ? Text(DateFormat('yyyy-MM-dd HH:mm').format(timestamp))
                      : null,
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: JobseekerBottomNavBar(currentIndex: 5, context: context),
    );
  }
} 