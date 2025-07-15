import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverNotificationsScreen extends StatelessWidget {
  const DriverNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.green,
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rideRequests')
                  .where('driverId', isEqualTo: user.uid)
                  .where('status', whereIn: ['pending', 'accepted', 'arrived', 'started', 'cancelled'])
                  // .orderBy('createdAt', descending: true) // Removed to avoid index error
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var requests = snapshot.data?.docs ?? [];
                // Sort requests by createdAt descending in Dart
                requests.sort((a, b) {
                  final aTime = (a['createdAt'] is Timestamp) ? a['createdAt'].toDate() : DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
                  final bTime = (b['createdAt'] is Timestamp) ? b['createdAt'].toDate() : DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
                  return bTime.compareTo(aTime);
                });
                if (requests.isEmpty) {
                  return const Center(child: Text('No notifications.'));
                }
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index].data() as Map<String, dynamic>;
                    String statusMsg = '';
                    switch (req['status']) {
                      case 'pending':
                        statusMsg = 'New ride request from ${req['passengerName'] ?? 'Passenger'}';
                        break;
                      case 'accepted':
                        statusMsg = 'You accepted a ride request.';
                        break;
                      case 'arrived':
                        statusMsg = 'You have arrived at the pickup location.';
                        break;
                      case 'started':
                        statusMsg = 'Ride started.';
                        break;
                      case 'cancelled':
                        statusMsg = 'Ride was cancelled.';
                        break;
                      default:
                        statusMsg = 'Status updated.';
                    }
                    return ListTile(
                      leading: Icon(Icons.notifications, color: Colors.green.shade700),
                      title: Text(statusMsg),
                      subtitle: Text('From: ${req['pickup'] ?? ''} To: ${req['dropoff'] ?? ''}'),
                      trailing: Text(req['status'] ?? ''),
                    );
                  },
                );
              },
            ),
    );
  }
} 