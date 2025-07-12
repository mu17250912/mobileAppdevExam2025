import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rwanda_colors.dart';

class UserBookingStatusScreen extends StatefulWidget {
  const UserBookingStatusScreen({Key? key}) : super(key: key);

  @override
  State<UserBookingStatusScreen> createState() => _UserBookingStatusScreenState();
}

class _UserBookingStatusScreenState extends State<UserBookingStatusScreen> {
  String? _userUid;
  Map<String, String> _lastStatuses = {};

  CollectionReference get _bookingsRef => FirebaseFirestore.instance.collection('bookings');

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userUid = user.uid;
    }
  }

  void _checkStatusChanges(List<QueryDocumentSnapshot> docs) {
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final id = doc.id;
      final status = data['status'] ?? 'Pending';
      if (_lastStatuses.containsKey(id) && _lastStatuses[id] != status) {
        // Status changed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking for ${data['productName']} is now $status!')),
          );
        });
      }
      _lastStatuses[id] = status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userUid == null) {
      return const Scaffold(body: Center(child: Text('You must be logged in.')));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kRwandaBlue,
        title: const Text('My Bookings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: kRwandaBlue.withOpacity(0.07),
        child: StreamBuilder<QuerySnapshot>(
          stream: _bookingsRef
              .where('userUid', isEqualTo: _userUid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error:  ${snapshot.error}'));
            }
            final docs = snapshot.data?.docs ?? [];
            _checkStatusChanges(docs);
            if (docs.isEmpty) {
              return const Center(child: Text('No bookings found.'));
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'Pending';
                Color statusColor;
                if (status == 'Completed') {
                  statusColor = kRwandaGreen;
                } else if (status == 'Pending') {
                  statusColor = kRwandaYellow;
                } else {
                  statusColor = Colors.redAccent;
                }
                return Card(
                  color: statusColor.withOpacity(0.08),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                  child: ListTile(
                    title: Text(data['productName'] ?? 'Unknown Product', style: TextStyle(color: kRwandaBlue, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: $status', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                        Text('Booking ID: ${doc.id}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 