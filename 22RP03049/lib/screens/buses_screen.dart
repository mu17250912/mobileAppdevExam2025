import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'seat_selection_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class BusesScreen extends StatelessWidget {
  final String routeId;
  final String routeName;
  const BusesScreen({super.key, required this.routeId, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buses for $routeName')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('buses').where('routeId', isEqualTo: routeId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No buses available for this route.'));
          }
          final buses = snapshot.data!.docs;
          return ListView.builder(
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];
              final data = bus.data() as Map<String, dynamic>;
              final imageUrl = data.containsKey('imageUrl')
                  ? data['imageUrl']
                  : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80';
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text('${data['company']} - ${data['plateNumber']}'),
                subtitle: Text('Departure: ${data['departureTime']} | Seats: ${data['availableSeats']}/${data['totalSeats']}'),
                trailing: const Icon(Icons.event_seat, color: Color(0xFFFFD600)),
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in to book.')),
                    );
                    return;
                  }
                  try {
                    final bookingRef = await FirebaseFirestore.instance.collection('bookings').add({
                      'userId': user.uid,
                      'busId': bus.id,
                      'routeId': data['routeId'],
                      'bookingTime': FieldValue.serverTimestamp(),
                      'status': 'confirmed',
                      'paymentStatus': 'pending',
                      'ticketCode': 'NYA- 2${DateTime.now().millisecondsSinceEpoch}',
                    });
                    // Log analytics event
                    await FirebaseAnalytics.instance.logEvent(
                      name: 'booking_created',
                      parameters: {
                        'userId': user.uid,
                        'busId': bus.id,
                        'routeId': data['routeId'],
                        'bookingId': bookingRef.id,
                        'timestamp': DateTime.now().toIso8601String(),
                      },
                    );
                    // Send booking confirmation notification
                    await FirebaseFirestore.instance.collection('notifications').add({
                      'userId': user.uid,
                      'title': 'Booking Confirmed',
                      'message': 'Your booking for bus ${data['company']} - ${data['plateNumber']} on ${data['departureTime']} is confirmed.',
                      'sentAt': FieldValue.serverTimestamp(),
                      'unread': true,
                      'auto': true,
                    });
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Booking Confirmed'),
                        content: const Text('Your booking has been created. Please proceed to payment.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Booking failed: $e')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
} 