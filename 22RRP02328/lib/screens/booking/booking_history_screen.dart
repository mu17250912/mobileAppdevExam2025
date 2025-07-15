import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../utils/constants.dart';
import '../../services/notification_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookings());
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _loadBookings();
      } else {
        _loadProviderBookings();
      }
    });
  }

  void _loadBookings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.setViewMode('user');
    if (authProvider.currentUser != null) {
      bookingProvider.loadBookingsForUser(authProvider.currentUser!.uid);
    }
  }

  void _loadProviderBookings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.setViewMode('provider');
    if (authProvider.currentUser != null) {
      bookingProvider.loadBookingsForProvider(authProvider.currentUser!.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Bookings'),
            Tab(text: 'Received Bookings'),
          ],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (bookingProvider.bookings.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookingProvider.bookings.length,
            itemBuilder: (context, index) {
              final booking = bookingProvider.bookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.event_available, color: Color(AppColors.primaryColor)),
                  title: Text(
                    booking.serviceType.isNotEmpty ? booking.serviceType : 'Booking',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Provider: ${booking.providerId}\nEvent: ${booking.eventId}\nDate: ${booking.preferredDate.toLocal().toString().split(" ")[0]}\nTime: ${booking.preferredTime}\nStatus: ${booking.status}'),
                      if (bookingProvider.viewMode == 'provider' && booking.status == 'pending')
                        Row(
                          children: [
                            TextButton(
                              onPressed: () async {
                                await bookingProvider.updateBookingStatus(booking.id, 'approved');
                                await NotificationService.saveNotification(
                                  userId: booking.userId,
                                  title: 'Booking Approved',
                                  message: 'Your booking for ${booking.preferredDate.toLocal().toString().split(" ")[0]} at ${booking.preferredTime} was approved.',
                                );
                              },
                              child: const Text('Approve'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await bookingProvider.updateBookingStatus(booking.id, 'rejected');
                                await NotificationService.saveNotification(
                                  userId: booking.userId,
                                  title: 'Booking Rejected',
                                  message: 'Your booking for ${booking.preferredDate.toLocal().toString().split(" ")[0]} at ${booking.preferredTime} was rejected.',
                                );
                              },
                              child: const Text('Reject', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 