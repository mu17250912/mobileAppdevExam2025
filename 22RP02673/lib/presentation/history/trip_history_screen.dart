import 'package:flutter/material.dart';
import '../../core/trip_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripHistoryScreen extends StatefulWidget {
  static const String routeName = '/trip_history';
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  // Removed in-memory trip logic and didChangeDependencies
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: TripManager.getPassengerTrips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Failed to load trips. Please try again later.', style: TextStyle(color: Colors.red)),
              ),
            );
          }
          final trips = snapshot.data?.docs ?? [];
          if (trips.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No trips yet. Your completed rides will appear here.', style: TextStyle(color: Colors.black54)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final trip = trips[i].data() as Map<String, dynamic>;
              final isAccepted = trip['status'] == 'accepted';
              final isArrived = trip['status'] == 'arrived';
              final isStarted = trip['status'] == 'started';
              final isCompleted = trip['status'] == 'completed';
              final isCancelled = trip['status'] == 'cancelled';
              final canCancel = !isStarted && !isCompleted && !isCancelled;
              return Card(
                color: isAccepted ? Colors.green.shade50 : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(trip['photo'] ?? ''),
                        backgroundColor: Colors.green,
                      ),
                      title: Text('${trip['pickup']} → ${trip['dropoff']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${trip['date']} at ${trip['time']}\nDriver: ${trip['driverName'] ?? ''}'),
                          Text('Status: ${trip['status']}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                          if (isCancelled && trip['cancelReason'] != null)
                            Text('Cancelled: ${trip['cancelReason']}', style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'RWF ${trip['fare']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Trip Details'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From: ${trip['pickup']}'),
                              Text('To: ${trip['dropoff']}'),
                              Text('Date: ${trip['date']}'),
                              Text('Time: ${trip['time']}'),
                              Text('Driver: ${trip['driverName'] ?? ''}'),
                              Text('Car: ${trip['car']}'),
                              Text('Fare: RWF ${trip['fare']}'),
                              Text('Status: ${trip['status']}'),
                              if (isCancelled && trip['cancelReason'] != null)
                                Text('Cancelled: ${trip['cancelReason']}', style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (canCancel)
                      ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final reason = await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  final controller = TextEditingController();
                                  return AlertDialog(
                                    title: const Text('Cancel Trip'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(labelText: 'Reason for cancellation'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Back'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, controller.text),
                                        child: const Text('Cancel Trip'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (reason != null && reason.isNotEmpty) {
                                await TripManager.cancelRide(trips[i].id, reason);
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  final String tripId;
  final String driverId;
  const _RatingDialog({required this.tripId, required this.driverId});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  double _rating = 5;
  bool _isSubmitting = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate your driver'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _rating,
            min: 1,
            max: 5,
            divisions: 4,
            label: _rating.toStringAsFixed(1),
            onChanged: (v) => setState(() => _rating = v),
          ),
          Text('Rating: ${_rating.toStringAsFixed(1)}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  // Store rating in Firestore as a subcollection under the trip
                  await FirebaseFirestore.instance
                      .collection('rideRequests')
                      .doc(widget.tripId)
                      .collection('reviews')
                      .add({
                        'driverId': widget.driverId,
                        'rating': _rating,
                        'reviewerId': FirebaseAuth.instance.currentUser?.uid,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  setState(() => _isSubmitting = false);
                  Navigator.pop(context, _rating);
                },
          child: _isSubmitting ? const CircularProgressIndicator() : const Text('Submit'),
        ),
      ],
    );
  }
} 