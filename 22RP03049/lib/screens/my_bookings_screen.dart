import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in');
      return const Center(child: Text('Please log in to view your bookings.'));
    }
    print('Current user UID:  [32m${user.uid} [0m');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('bookingTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('No bookings found for user: ${user.uid}');
          return const Center(child: Text('No bookings found.'));
        }
        final bookings = snapshot.data!.docs;
        print('Fetched ${bookings.length} bookings for user: ${user.uid}');
        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final data = booking.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFD600),
              child: ListTile(
                leading: const Icon(Icons.confirmation_num, color: Color(0xFF003366), size: 36),
                title: Text('Ticket: ${data['ticketCode'] ?? ''}', style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bus:  [31m${data['busId'] ?? 'N/A'} [0m', style: const TextStyle(color: Color(0xFF003366))),
                    Text('Seat: ${data['seatNumber'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF003366))),
                    Text('Status: ${data['status'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF003366))),
                    Text('Payment: ${data['paymentStatus'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF003366))),
                    Text('Booked: ${data['bookingTime'] != null ? data['bookingTime'].toDate().toString() : 'N/A'}', style: const TextStyle(color: Color(0xFF003366))),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.qr_code, color: Color(0xFF003366)),
                  tooltip: 'Show E-Ticket',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('E-Ticket'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.confirmation_num, size: 48, color: Color(0xFF003366)),
                            const SizedBox(height: 8),
                            Text('Ticket: ${data['ticketCode'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Bus: ${data['busId'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
} 