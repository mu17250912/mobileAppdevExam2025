import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  final bool showAppBar;
  const NotificationsScreen({this.showAppBar = false, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: (ModalRoute.of(context)?.canPop ?? false)
          ? AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/available_cars_screen',
                    (route) => false,
                  );
                },
              ),
              title: const Text('Notifications'),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications.'));
          }
          // You may want to pass userRole as a parameter if needed
          final notifs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // For admin, show userId == null; for user, show userId == current user
            if (userId == null) return false;
            if (data['userId'] == null) {
              // Admin notification
              return true;
            } else {
              return data['userId'] == userId;
            }
          }).toList();
          if (notifs.isEmpty) {
            return const Center(child: Text('No notifications.'));
          }
          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              final data = notifs[index].data() as Map<String, dynamic>;
              final isRead = data['readBy'] != null && (data['readBy'] as List).contains(userId);
              // Format timestamp
              String timeStr = '';
              final ts = data['timestamp'];
              if (ts != null) {
                if (ts is Timestamp) {
                  final dt = ts.toDate();
                  timeStr = DateFormat('yyyy-MM-dd HH:mm').format(dt);
                } else if (ts is String) {
                  try {
                    final dt = DateTime.parse(ts);
                    timeStr = DateFormat('yyyy-MM-dd HH:mm').format(dt);
                  } catch (_) {
                    timeStr = ts;
                  }
                } else {
                  timeStr = ts.toString();
                }
              }
              // Find user info if available
              String userInfo = '';
              if (data['userName'] != null) {
                userInfo = 'By: ${data['userName']}';
              } else if (data['userEmail'] != null) {
                userInfo = 'By: ${data['userEmail']}';
              } else if (data['userId'] != null && data['userId'].toString().isNotEmpty) {
                userInfo = 'User ID: ${data['userId']}';
              }
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isRead ? null : theme.colorScheme.secondary.withOpacity(0.1),
                child: ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['message'] ?? ''),
                      if (userInfo.isNotEmpty) Text(userInfo, style: theme.textTheme.bodySmall),
                      Text('At: $timeStr', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  trailing: isRead ? null : Icon(Icons.fiber_new, color: theme.colorScheme.secondary),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 