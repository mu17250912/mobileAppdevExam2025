import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/notifications_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  IconData _getIcon(String title) {
    if (title.toLowerCase().contains('alert') || title.toLowerCase().contains('overspending')) {
      return Icons.warning_amber_rounded;
    } else if (title.toLowerCase().contains('saved')) {
      return Icons.check_circle_rounded;
    } else if (title.toLowerCase().contains('report')) {
      return Icons.info_rounded;
    }
    return Icons.notifications;
  }

  Color _getIconColor(String title) {
    if (title.toLowerCase().contains('alert') || title.toLowerCase().contains('overspending')) {
      return Colors.orange;
    } else if (title.toLowerCase().contains('saved')) {
      return Colors.green;
    } else if (title.toLowerCase().contains('report')) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to see notifications.')),
      );
    }
    print('Current userId: ${user.uid}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('No notifications yet.', style: TextStyle(fontSize: 18)));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('No notifications yet.', style: TextStyle(fontSize: 18)));
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Notification';
                final body = data['body'] ?? '';
                DateTime? date;
                if (data['date'] is Timestamp) {
                  date = (data['date'] as Timestamp).toDate();
                } else if (data['date'] is DateTime) {
                  date = data['date'] as DateTime;
                }
                final icon = _getIcon(title);
                final iconColor = _getIconColor(title);
                final timeAgo = date != null ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}" : '';
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 16, top: 2),
                          child: Icon(icon, color: iconColor, size: 36),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () async {
                                      await docs[index].reference.delete();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 