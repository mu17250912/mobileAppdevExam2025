import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverTripHistoryScreen extends StatelessWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.green,
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rideRequests')
                  .where('driverId', isEqualTo: user.uid)
                  .where('status', whereIn: ['completed', 'cancelled'])
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final trips = snapshot.data?.docs ?? [];
                if (trips.isEmpty) {
                  return const Center(child: Text('No trip history found.'));
                }
                return ListView.builder(
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index].data() as Map<String, dynamic>;
                    final isCancelled = trip['status'] == 'cancelled';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          isCancelled ? Icons.cancel : Icons.check_circle,
                          color: isCancelled ? Colors.red : Colors.green,
                        ),
                        title: Text('${trip['pickup'] ?? ''} → ${trip['dropoff'] ?? ''}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${trip['date'] ?? ''}  Time: ${trip['time'] ?? ''}'),
                            Text('Fare: RWF ${trip['fare'] ?? ''}'),
                            Text('Status: ${trip['status'] ?? ''}'),
                            if (isCancelled && trip['cancelReason'] != null)
                              Text('Cancelled: ${trip['cancelReason']}', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
} 