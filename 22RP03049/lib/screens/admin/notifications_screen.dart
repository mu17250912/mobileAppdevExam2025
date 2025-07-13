import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final unread = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('unread', isEqualTo: true)
        .get();
    for (final doc in unread.docs) {
      await doc.reference.update({'unread': false});
    }
  }

  @override
  Widget build(BuildContext context) {
    // _markAllAsRead(); // Removed to prevent marking all as read on open
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('sentAt', descending: true)
            .snapshots(),
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
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: (data['unread'] == true) ? Colors.red : null,
                  ),
                  title: Text(data['title'] ?? ''),
                  subtitle: Text('${data['message'] ?? ''}\nSent: ${data['sentAt'] != null ? (data['sentAt'] as Timestamp).toDate().toString() : ''}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'promotion',
            backgroundColor: Colors.purple,
            child: const Icon(Icons.campaign),
            tooltip: 'Send Promotion',
            onPressed: () {
              final formKey = GlobalKey<FormState>();
              final titleController = TextEditingController();
              final messageController = TextEditingController();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Send Promotion'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(labelText: 'Promotion Title'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: messageController,
                            decoration: const InputDecoration(labelText: 'Promotion Message'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          // Send to all users
                          final usersSnap = await FirebaseFirestore.instance.collection('users').get();
                          for (final user in usersSnap.docs) {
                            await FirebaseFirestore.instance.collection('notifications').add({
                              'userId': user.id,
                              'title': titleController.text.trim(),
                              'message': messageController.text.trim(),
                              'sentAt': FieldValue.serverTimestamp(),
                              'unread': true,
                              'senderAdminId': FirebaseAuth.instance.currentUser?.uid,
                              'promotion': true,
                            });
                          }
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Promotion sent to all users!')),
                          );
                        }
                      },
                      child: const Text('Send'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'notification',
            onPressed: () => _showNotificationDialog(context),
            child: const Icon(Icons.add),
            tooltip: 'Send Notification',
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    List<QueryDocumentSnapshot> users = [];
    String? selectedUserId;
    String? selectedUserEmail;
    // Fetch users for dropdown
    try {
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      users = usersSnap.docs;
    } catch (_) {}
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedUserId,
                  items: users.map((user) {
                    final data = user.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: user.id,
                      child: Text(data['email'] ?? user.id),
                    );
                  }).toList(),
                  onChanged: (val) {
                    selectedUserId = val;
                    QueryDocumentSnapshot? user;
                    try {
                      user = users.firstWhere((u) => u.id == val);
                    } catch (_) {
                      user = null;
                    }
                    if (user != null) {
                      final data = user.data() as Map<String, dynamic>;
                      selectedUserEmail = data['email'];
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Select User'),
                  validator: (v) => v == null || v.isEmpty ? 'Select a user' : null,
                ),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final currentAdmin = FirebaseAuth.instance.currentUser;
                final data = {
                  'userId': selectedUserId,
                  'title': titleController.text.trim(),
                  'message': messageController.text.trim(),
                  'sentAt': FieldValue.serverTimestamp(),
                  'unread': true,
                  'senderAdminId': currentAdmin?.uid,
                };
                try {
                  await FirebaseFirestore.instance.collection('notifications').add(data);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification sent')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
} 