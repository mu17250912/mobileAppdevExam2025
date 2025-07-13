import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingCancellationScreen extends StatefulWidget {
  @override
  _BookingCancellationScreenState createState() => _BookingCancellationScreenState();
}

class _BookingCancellationScreenState extends State<BookingCancellationScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (booking == null) {
      return Scaffold(
        body: Center(child: Text('No booking data provided!')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/available_cars_screen',
              (route) => false,
            );
          },
        ),
        title: const Text('Cancel Booking'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Please let us know why you are cancelling:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter your reason (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Abort'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            setState(() { _isLoading = true; });
                            try {
                              await FirebaseFirestore.instance.collection('bookings').doc(booking['id']).update({
                                'status': 'CANCELLED',
                                'cancellationReason': _reasonController.text.trim(),
                                'cancelledAt': DateTime.now(),
                              });
                              await FirebaseFirestore.instance.collection('notifications').add({
                                'userId': booking['userId'],
                                'title': 'Booking Cancelled',
                                'message': 'Your booking for ${booking['carName'] ?? 'a car'} on ${booking['date'] ?? ''} has been cancelled.',
                                'timestamp': FieldValue.serverTimestamp(),
                                'readBy': [],
                              });
                              // Admin notification
                              await FirebaseFirestore.instance.collection('notifications').add({
                                'userId': null,
                                'title': 'Booking Cancelled',
                                'message': 'Booking for ${booking['carName'] ?? 'a car'} on ${booking['date'] ?? ''} was cancelled.',
                                'timestamp': FieldValue.serverTimestamp(),
                                'readBy': [],
                              });
                              setState(() { _isLoading = false; });
                              Navigator.pop(context, {'cancelled': true});
                            } catch (e) {
                              setState(() { _isLoading = false; });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to cancel booking. Please try again.')),
                              );
                            }
                          },
                          child: const Text('Confirm Cancellation'),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
} 