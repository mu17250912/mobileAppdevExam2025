import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/colors.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          final users = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final isAdmin = user['isAdmin'] == true;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? AppColors.primary : AppColors.lightGrey,
                    child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.white),
                  ),
                  title: Row(
                    children: [
                      Text(user['displayName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                      if (isAdmin)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.verified, color: Colors.green, size: 18),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['email'] ?? 'No email', style: const TextStyle(color: AppColors.textSecondary)),
                      Text('Joined: ${_formatTimestamp(user['createdAt'])}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (user['lastLogin'] != null)
                        Text('Last login: ${_formatTimestamp(user['lastLogin'])}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isAdmin ? Icons.person_remove : Icons.admin_panel_settings, color: isAdmin ? AppColors.warning : AppColors.info),
                        tooltip: isAdmin ? 'Remove Admin' : 'Make Admin',
                        onPressed: () => _toggleAdminStatus(context, userId, isAdmin, user['displayName']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.book_online, color: AppColors.success),
                        tooltip: 'View Bookings',
                        onPressed: () => _viewUserBookings(context, userId, user['displayName']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.danger),
                        tooltip: 'Delete User',
                        onPressed: () => _showDeleteConfirmation(context, userId, user['displayName']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleAdminStatus(BuildContext context, String userId, bool currentStatus, String? userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentStatus ? 'Remove Admin Status' : 'Make Admin'),
        content: Text(currentStatus
            ? 'Are you sure you want to remove admin privileges from "$userName"?'
            : 'Are you sure you want to make "$userName" an admin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'isAdmin': !currentStatus,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(currentStatus ? 'Admin removed' : 'User is now admin')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update user: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: currentStatus ? AppColors.warning : AppColors.primary),
            child: Text(currentStatus ? 'Remove Admin' : 'Make Admin'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String userId, String? userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "$userName"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                // Delete user's bookings first
                final bookingsSnapshot = await FirebaseFirestore.instance
                    .collection('bookings')
                    .where('userId', isEqualTo: userId)
                    .get();
                for (var doc in bookingsSnapshot.docs) {
                  await doc.reference.delete();
                }
                // Delete user document
                await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User $userName deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete user: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewUserBookings(BuildContext context, String userId, String? userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('$userName\'s Bookings'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: userId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No bookings found.'));
              }
              final bookings = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(booking['tripName'] ?? booking['hotelName'] ?? 'Unknown', style: const TextStyle(color: AppColors.text)),
                      subtitle: Text('Status: ${booking['status'] ?? 'N/A'}', style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (timestamp is String) {
      try {
        final dateTime = DateTime.parse(timestamp);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        return 'Invalid date';
      }
    }
    return 'N/A';
  }
} 