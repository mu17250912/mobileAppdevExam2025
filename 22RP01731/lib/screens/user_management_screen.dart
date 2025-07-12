import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final email = userData['email'] ?? 'No email';
              final firstName = userData['firstName'] ?? 'No name';
              final lastName = userData['lastName'] ?? '';
              final isAdmin = userData['isAdmin'] ?? false;
              final createdAt = userData['createdAt'] as Timestamp?;
              final phone = userData['phone'] ?? 'No phone';
              final address = userData['address'] ?? 'No address';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? Colors.red : Colors.blue,
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text('$firstName $lastName'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: $email'),
                      Text('Phone: $phone'),
                      Text('Role: ${isAdmin ? 'Admin' : 'Customer'}'),
                      if (createdAt != null)
                        Text('Joined: ${createdAt.toDate().toLocal().toString().split('.')[0]}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'view_details') {
                        showDialog(
                          context: context,
                          builder: (context) => UserDetailsDialog(
                            userId: userId,
                            userData: userData,
                          ),
                        );
                      } else if (action == 'toggle_admin') {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .update({'isAdmin': !isAdmin});
                      } else if (action == 'delete_user') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete User'),
                            content: Text('Are you sure you want to delete $firstName $lastName? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey.shade600,
                                ),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red.shade600,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .delete();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view_details',
                        child: Text('View Details'),
                      ),
                      PopupMenuItem(
                        value: 'toggle_admin',
                        child: Text(isAdmin ? 'Remove Admin' : 'Make Admin'),
                      ),
                      const PopupMenuItem(
                        value: 'delete_user',
                        child: Text('Delete User'),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UserDetailsDialog extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserDetailsDialog({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final email = userData['email'] ?? 'No email';
    final firstName = userData['firstName'] ?? 'No name';
    final lastName = userData['lastName'] ?? '';
    final isAdmin = userData['isAdmin'] ?? false;
    final createdAt = userData['createdAt'] as Timestamp?;
    final phone = userData['phone'] ?? 'No phone';
    final address = userData['address'] ?? 'No address';

    return AlertDialog(
      title: Text('User Details - $firstName $lastName'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('User ID: ${userId.substring(0, 8)}...'),
            Text('Email: $email'),
            Text('Phone: $phone'),
            Text('Address: $address'),
            Text('Role: ${isAdmin ? 'Admin' : 'Customer'}'),
            if (createdAt != null)
              Text('Joined: ${createdAt.toDate().toLocal().toString().split('.')[0]}'),
            const SizedBox(height: 16),
            const Text('User Statistics:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final orderCount = snapshot.data!.docs.length;
                  final totalSpent = snapshot.data!.docs.fold<double>(
                    0,
                    (sum, doc) => sum + (doc.data() as Map<String, dynamic>)['total'],
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Orders: $orderCount'),
                      Text('Total Spent: \$${totalSpent.toStringAsFixed(2)}'),
                    ],
                  );
                }
                return const Text('Loading statistics...');
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }
} 