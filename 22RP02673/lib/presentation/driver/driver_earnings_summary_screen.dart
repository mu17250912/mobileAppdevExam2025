import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DriverEarningsSummaryScreen extends StatelessWidget {
  const DriverEarningsSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings Summary'),
        backgroundColor: Colors.green,
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rideRequests')
                  .where('driverId', isEqualTo: user.uid)
                  .where('status', isEqualTo: 'completed')
                  // .orderBy('createdAt', descending: true) // Removed to avoid index error
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var trips = snapshot.data?.docs ?? [];
                // Sort trips by createdAt descending in Dart
                trips.sort((a, b) {
                  final aTime = (a['createdAt'] is Timestamp) ? a['createdAt'].toDate() : DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
                  final bTime = (b['createdAt'] is Timestamp) ? b['createdAt'].toDate() : DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
                  return bTime.compareTo(aTime);
                });
                if (trips.isEmpty) {
                  return const Center(child: Text('No completed trips yet.'));
                }
                double totalEarnings = 0;
                Map<String, double> monthlyEarnings = {};
                for (var doc in trips) {
                  final trip = doc.data() as Map<String, dynamic>;
                  final fare = (trip['fare'] ?? 0).toDouble();
                  totalEarnings += fare;
                  final date = trip['date'] ?? '';
                  if (date.isNotEmpty) {
                    final month = date.toString().substring(0, 7); // yyyy-MM
                    monthlyEarnings[month] = (monthlyEarnings[month] ?? 0) + fare;
                  }
                }
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Card(
                      color: Colors.green.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Earnings', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('RWF ${totalEarnings.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 16),
                            Text('Total Trips: ${trips.length}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Monthly Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...monthlyEarnings.entries.map((entry) => ListTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.green),
                          title: Text(DateFormat('MMMM yyyy').format(DateTime.parse('${entry.key}-01'))),
                          trailing: Text('RWF ${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        )),
                  ],
                );
              },
            ),
    );
  }
} 