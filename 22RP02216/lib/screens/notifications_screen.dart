import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Not logged in.')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            //.orderBy('timestamp', descending: true) // Removed to avoid index
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No notifications.',
                style: GoogleFonts.poppins(color: Colors.deepPurple),
              ),
            );
          }
          var notifications = snapshot.data!.docs;
          // Sort notifications by timestamp descending in Dart
          notifications = List.from(notifications);
          notifications.sort((a, b) {
            final aTime = a['timestamp'];
            final bTime = b['timestamp'];
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final notif = notifications[i];
              final data = notif.data() as Map<String, dynamic>;
              final isRead = data['read'] == true;
              return ListTile(
                tileColor: isRead
                    ? Colors.grey[100]
                    : Colors.deepPurple.withOpacity(0.08),
                leading: Icon(
                  isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: isRead ? Colors.grey : Colors.deepPurple,
                ),
                title: Text(
                  data['title'] ?? '',
                  style: GoogleFonts.poppins(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: isRead ? Colors.grey[700] : Colors.deepPurple,
                  ),
                ),
                subtitle: Text(
                  data['body'] ?? '',
                  style: GoogleFonts.poppins(
                    color: isRead ? Colors.grey[600] : Colors.black,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                    color: isRead ? Colors.deepPurple : Colors.grey,
                  ),
                  tooltip: isRead ? 'Mark as unread' : 'Mark as read',
                  onPressed: () async {
                    await notif.reference.update({'read': !isRead});
                  },
                ),
                onTap: () async {
                  await notif.reference.update({'read': !isRead});
                },
              );
            },
          );
        },
      ),
    );
  }
}
