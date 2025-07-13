import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/colors.dart';

class NotificationScreen extends StatelessWidget {
  final String? message;
  final Map<String, dynamic>? bookingDetails;

  const NotificationScreen({super.key, this.message, this.bookingDetails});

  @override
  Widget build(BuildContext context) {
    // If a message is passed (from booking), show the single notification as before
    if (message != null) {
      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: const Color(0xFF5EC2B7),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active, size: 80, color: theme.iconTheme.color),
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: TextStyle(fontSize: 18, color: theme.textTheme.bodyMedium?.color),
                      textAlign: TextAlign.center,
                    ),
                    if (bookingDetails != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Booking Details:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Trip: ${bookingDetails!['tripName']}',
                        style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                      ),
                      Text(
                        'Date: ${bookingDetails!['bookingDate'].split('T')[0]}',
                        style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                      ),
                      Text(
                        'Number of People: ${bookingDetails!['numberOfPeople']}',
                        style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Otherwise, show a list of booking notifications for the current user
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF5EC2B7),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Please log in to view notifications.'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('userId', isEqualTo: user.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF234F1E)));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error:  {snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No new notifications.', style: TextStyle(fontSize: 18, color: Colors.white)),
                    );
                  }
                  final bookings = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index].data();
                      final tripName = booking['tripName'] ?? 'Unknown Park';
                      final bookingDate = booking['bookingDate'] != null
                          ? booking['bookingDate'].toString().split('T')[0]
                          : 'N/A';
                      final status = booking['status'] ?? 'Pending';
                      final icon = status == 'Confirmed'
                          ? Icons.check_circle
                          : status == 'Completed'
                              ? Icons.celebration
                              : status == 'Cancelled'
                                  ? Icons.cancel
                                  : Icons.notifications_active;
                      final iconColor = status == 'Confirmed'
                          ? Colors.green
                          : status == 'Completed'
                              ? Colors.blue
                              : status == 'Cancelled'
                                  ? Colors.red
                                  : Color(0xFF616161);
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 5,
                        margin: const EdgeInsets.only(bottom: 18),
                        child: ListTile(
                          leading: Icon(icon, size: 38, color: iconColor),
                          title: Text(
                            'Your trip to $tripName',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text('Date: $bookingDate\nStatus: $status'),
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