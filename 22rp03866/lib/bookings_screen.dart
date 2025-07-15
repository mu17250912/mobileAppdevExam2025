import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/colors.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildBookingList(List<DocumentSnapshot> bookings) {
    final theme = Theme.of(context);
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              'No bookings yet!',
              style: TextStyle(fontSize: 20, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
            ),
            Text(
              'Start planning your next adventure!',
              style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index].data() as Map<String, dynamic>;
          final String tripName = booking['tripName'] ?? 'N/A';
          final String destination = booking['tripDescription'] ?? 'N/A';
          final String bookingDate = booking['bookingDate'] != null
              ? DateTime.parse(booking['bookingDate']).toLocal().toString().split(' ')[0]
              : 'N/A';
          final String status = booking['status'] ?? 'N/A';
          final String imageUrl = booking['tripImage'] ?? '';
          final bool paid = booking['paid'] == true;

          Color statusColor = Colors.grey;
          if (status == 'Confirmed') {
            statusColor = Colors.green[700]!;
          } else if (status == 'Completed') {
            statusColor = Colors.blueAccent;
          } else if (status == 'Cancelled') {
            statusColor = Colors.red;
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: imageUrl.isNotEmpty
                        ? Image.asset(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80, height: 80, color: Colors.grey[200],
                                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                              );
                            },
                          )
                        : Container(
                            width: 80, height: 80, color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tripName,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination,
                          style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: $bookingDate',
                          style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (paid)
                          Text('Paid', style: TextStyle(fontSize: 13, color: AppColors.success)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline, color: AppColors.primary),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => BookingDetailsDialog(booking: booking),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(
        child: Text('Please log in to view your bookings.'),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF5EC2B7), // Teal background like home
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabButton('Upcoming', 0),
                  const SizedBox(width: 12),
                  _buildTabButton('Past', 1),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId', isEqualTo: _currentUser!.uid)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No bookings yet!',
                              style: TextStyle(fontSize: 20, color: Colors.grey),
                            ),
                            Text(
                              'Start planning your next adventure!',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final allBookings = snapshot.data!.docs;
                    final upcomingBookings = <DocumentSnapshot>[];
                    final pastBookings = <DocumentSnapshot>[];

                    final now = DateTime.now();

                    for (var doc in allBookings) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data != null && data.containsKey('bookingDate')) {
                        final bookingDateString = data['bookingDate'] as String;
                        final bookingDateTime = DateTime.parse(bookingDateString);
                        if (bookingDateTime.isAfter(now)) {
                          upcomingBookings.add(doc);
                        } else {
                          pastBookings.add(doc);
                        }
                      }
                    }

                    final selectedTab = _tabController.index;
                    final bookingsToShow = selectedTab == 0 ? upcomingBookings : pastBookings;
                    return _buildBookingList(bookingsToShow);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabController.index = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7B61FF) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                : [],
            border: Border.all(color: const Color(0xFF7B61FF), width: 1),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF7B61FF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BookingDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> booking;
  const BookingDetailsDialog({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final String status = booking['status'] ?? 'N/A';
    final bool paid = booking['paid'] == true;
    final String type = booking['type'] ?? 'flight';
    return AlertDialog(
      title: Text('Booking Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (booking['tripImage'] != null)
              Center(
                child: Image.asset(
                  booking['tripImage'],
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 12),
            if (type == 'hotel') ...[
              Text('Hotel: ${booking['hotelName'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Room: ${booking['roomType'] ?? 'N/A'}'),
              Text('Check-in: ${booking['checkIn'] ?? 'N/A'}'),
              Text('Check-out: ${booking['checkOut'] ?? 'N/A'}'),
            ] else ...[
              Text('Trip: ${booking['tripName'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Destination: ${booking['tripDescription'] ?? 'N/A'}'),
              Text('Date: ${booking['bookingDate'] != null ? booking['bookingDate'].split("T")[0] : 'N/A'}'),
              Text('People: ${booking['numberOfPeople'] ?? 'N/A'}'),
              Text('Premium: ${booking['isPremiumBooking'] == true ? 'Yes' : 'No'}'),
            ],
            const SizedBox(height: 8),
            Text('Total Price: \$${booking['totalPrice'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Status: $status', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (paid) ...[
              const Text('Payment Status: Paid', style: TextStyle(color: Colors.green)),
            ] else if (status == 'Confirmed') ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement payment logic here
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Proceed to payment (to be implemented)')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF234F1E)),
                child: const Text('Pay Now'),
              ),
            ] else if (status == 'Pending') ...[
              const SizedBox(height: 12),
              const Text('Awaiting admin approval.', style: TextStyle(color: Colors.orange)),
            ] else if (status == 'Cancelled') ...[
              const SizedBox(height: 12),
              const Text('Booking was cancelled.', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
} 