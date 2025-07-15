import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  void _openAdminRequests(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminRequestsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
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
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(data['email'] ?? ''),
                subtitle: Text('Role: ${data['role'] ?? 'user'}\nBlocked: ${data['blocked'] == true ? 'Yes' : 'No'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: data['role'] ?? 'user',
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (val) async {
                        if (val != null && val != data['role']) {
                          try {
                            await FirebaseFirestore.instance.collection('users').doc(user.id).update({'role': val});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Role updated to $val')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        data['blocked'] == true ? Icons.lock_open : Icons.block,
                        color: data['blocked'] == true ? Colors.green : Colors.red,
                      ),
                      tooltip: data['blocked'] == true ? 'Unblock User' : 'Block User',
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance.collection('users').doc(user.id).update({'blocked': !(data['blocked'] == true)});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(data['blocked'] == true ? 'User unblocked' : 'User blocked')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({Key? key}) : super(key: key);

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  String _search = '';

  Future<void> _approveRequest(BuildContext context, String userId, String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': 'admin'});
      await FirebaseFirestore.instance.collection('admin_requests').doc(requestId).delete();
      // Send notification to user
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'Admin Access Approved',
        'message': 'Your request for admin access has been approved. You now have admin privileges.',
        'sentAt': FieldValue.serverTimestamp(),
        'unread': true,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User promoted to admin.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectRequest(BuildContext context, String requestId, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('admin_requests').doc(requestId).delete();
      // Send notification to user
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'Admin Access Rejected',
        'message': 'Your request for admin access has been rejected. Please contact support for more information.',
        'sentAt': FieldValue.serverTimestamp(),
        'unread': true,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Access Requests')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by email',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('admin_requests').orderBy('requestedAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No admin requests.'));
                }
                final requests = snapshot.data!.docs.where((req) {
                  final data = req.data() as Map<String, dynamic>;
                  return _search.isEmpty || (data['email']?.toString().toLowerCase().contains(_search) ?? false);
                }).toList();
                if (requests.isEmpty) {
                  return const Center(child: Text('No requests match your search.'));
                }
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final data = req.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.admin_panel_settings),
                        title: Text(data['email'] ?? ''),
                        subtitle: Text('Requested at: ${data['requestedAt'] != null ? (data['requestedAt'] as Timestamp).toDate().toString() : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () => _approveRequest(context, data['userId'], req.id),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Approve'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _rejectRequest(context, req.id, data['userId']),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Reject'),
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
        ],
      ),
    );
  }
} 