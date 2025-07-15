import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rwanda_colors.dart';

class AdminBookingManagement extends StatelessWidget {
  const AdminBookingManagement({Key? key}) : super(key: key);

  CollectionReference get _bookingsRef => FirebaseFirestore.instance.collection('bookings');

  void _updateStatus(BuildContext context, String bookingId, String newStatus) async {
    await _bookingsRef.doc(bookingId).update({'status': newStatus});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking status updated to $newStatus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kRwandaBlue,
        title: Row(
          children: [
            const Text('Manage Bookings', style: TextStyle(color: Colors.white)),
            const Spacer(),
            Icon(Icons.wb_sunny, color: kRwandaSun, size: 28),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _bookingsRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }
          double totalCommission = 0;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final commission = double.tryParse(data['commission']?.toString() ?? '0') ?? 0;
            totalCommission += commission;
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: kRwandaYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Text('Total Commission: \$${totalCommission.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Pending';
                    final paid = data['paid'] == true;
                    return Card(
                      color: kRwandaGreen.withOpacity(0.08),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        title: Text(data['productName'] ?? 'Unknown Product', style: TextStyle(color: kRwandaBlue, fontWeight: FontWeight.bold)),
                        subtitle: Text('Status: $status\nPaid: ${paid ? 'Yes' : 'No'}\nUser: ${data['userEmail'] ?? data['userUid'] ?? 'Unknown'}\nBooking ID: ${doc.id}\nCommission: \$${data['commission'] ?? '0.00'}'),
                        isThreeLine: true,
                        trailing: DropdownButton<String>(
                          value: status,
                          items: const [
                            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                            DropdownMenuItem(value: 'Canceled', child: Text('Canceled')),
                          ],
                          onChanged: (value) {
                            if (value != null && value != status) {
                              _updateStatus(context, doc.id, value);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 