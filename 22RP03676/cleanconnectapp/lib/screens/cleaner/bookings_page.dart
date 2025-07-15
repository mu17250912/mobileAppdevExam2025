import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CleanerBookingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: const Color(0xFF6A8DFF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }
          final jobs = snapshot.data!.docs;
          final List<Map<String, dynamic>> myJobs = [];
          final Set<String> jobIds = {};
          for (var doc in jobs) {
            final job = doc.data() as Map<String, dynamic>;
            final jobId = doc.id;
            final applicants = (job['applicants'] as List?)?.cast<String>() ?? [];
            final hasApplied = applicants.contains(user.uid);
            final isAssigned = job['cleanerId'] == user.uid;
            if (isAssigned || hasApplied) {
              if (!jobIds.contains(jobId)) {
                myJobs.add({...job, 'id': jobId, 'isAssigned': isAssigned, 'hasApplied': hasApplied});
                jobIds.add(jobId);
              }
            }
          }
          if (myJobs.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myJobs.length,
            itemBuilder: (context, i) {
              final job = myJobs[i];
              final isAssigned = job['isAssigned'] as bool;
              final hasApplied = job['hasApplied'] as bool;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Color(0xFF6A8DFF)),
                  title: Text(job['title'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job['description'] ?? ''),
                      if (isAssigned)
                        Text('Status: Assigned', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      if (!isAssigned && hasApplied)
                        Text('Status: Applied', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: isAssigned && job['status'] == 'completed'
                      ? Text('Completed', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                      : isAssigned && (job['status'] == 'assigned' || job['status'] == 'accepted')
                          ? ElevatedButton(
                              onPressed: () async {
                                final jobId = job['id'];
                                await FirebaseFirestore.instance
                                    .collection('jobs')
                                    .doc(jobId)
                                    .update({'status': 'completed'});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Job marked as completed!')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A8DFF),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Mark as Completed'),
                            )
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CleanerBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _CleanerBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final service = booking['service'] ?? '';
    final customer = booking['customerName'] ?? '';
    final dateObj = booking['date'] is Timestamp
        ? (booking['date'] as Timestamp).toDate()
        : DateTime.tryParse(booking['date'] ?? '');
    final dateStr = dateObj != null
        ? '${dateObj.year}-${dateObj.month.toString().padLeft(2, '0')}-${dateObj.day.toString().padLeft(2, '0')}'
        : '';
    final time = booking['time'] ?? '';
    final status = booking['status'] ?? 'upcoming';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.event, color: Color(0xFF6A8DFF)),
        title: Text(service),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$dateStr at $time'),
            Text('Customer: $customer'),
            Text('Status: $status', style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
} 