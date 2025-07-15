import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  late Future<String> _roleFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _roleFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((doc) => doc.data()?['role'] ?? 'user');
  }

  Future<void> _markAsReadAndNotifyAdmin(DocumentSnapshot notif, String userEmail) async {
    final data = notif.data() as Map<String, dynamic>;
    if (data['unread'] == true) {
      await notif.reference.update({'unread': false});
      if (data['senderAdminId'] != null) {
        await FirebaseFirestore.instance.collection('read_receipts').add({
          'adminId': data['senderAdminId'],
          'userId': data['userId'],
          'userEmail': userEmail,
          'notificationId': notif.id,
          'notificationTitle': data['title'],
          'readAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications.')),
      );
    }
    return FutureBuilder<String>(
      future: _roleFuture,
      builder: (context, roleSnapshot) {
        if (!roleSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = roleSnapshot.data!;
        final Stream<QuerySnapshot> notificationStream = (role == 'admin')
            ? FirebaseFirestore.instance
                .collection('notifications')
                .orderBy('sentAt', descending: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: user.uid)
                .orderBy('sentAt', descending: true)
                .snapshots();
        return Scaffold(
          appBar: AppBar(title: const Text('Notifications')),
          body: StreamBuilder<QuerySnapshot>(
            stream: notificationStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No notifications found.'));
              }
              final notifications = snapshot.data!.docs;
              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final data = notif.data() as Map<String, dynamic>;
                  final isUnread = data['unread'] == true;
                  return Card(
                    color: isUnread ? Colors.yellow[100] : null,
                    child: ListTile(
                      leading: Icon(Icons.notifications, color: isUnread ? Colors.red : null),
                      title: Text(data['title'] ?? ''),
                      subtitle: Text('${data['message'] ?? ''}\nSent: ${data['sentAt'] != null ? (data['sentAt'] as Timestamp).toDate().toString() : ''}'),
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(data['title'] ?? ''),
                            content: Text('${data['message'] ?? ''}\n\nSent: ${data['sentAt'] != null ? (data['sentAt'] as Timestamp).toDate().toString() : ''}'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                        await _markAsReadAndNotifyAdmin(notif, user.email ?? user.uid);
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
} 