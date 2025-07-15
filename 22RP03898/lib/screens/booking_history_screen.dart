import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/error_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final ErrorService _errorService = ErrorService();

  late TabController _tabController;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final bookings = await _bookingService.getUserBookings(currentUser.uid);
      if (!mounted) return;

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Failed to load bookings';

      // Provide more specific error messages
      if (e.toString().contains('index')) {
        errorMessage =
            'Database is being updated. Please try again in a few minutes.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Access denied. Please check your account permissions.';
      } else if (e.toString().contains('unavailable')) {
        errorMessage =
            'Service temporarily unavailable. Please try again later.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });

      // Log the error for debugging
      _errorService.logError('Error loading booking history', e);

      // Show a user-friendly snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange.shade600,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadBookings,
            ),
          ),
        );
      }
    }
  }

  List<BookingModel> _getFilteredBookings() {
    switch (_tabController.index) {
      case 0: // All
        return _bookings;
      case 1: // Active
        return _bookings
            .where((b) =>
                b.status == BookingStatus.pending ||
                b.status == BookingStatus.confirmed)
            .toList();
      case 2: // Completed
        return _bookings
            .where((b) => b.status == BookingStatus.completed)
            .toList();
      default:
        return _bookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(_getFilteredBookings()),
                    _buildBookingsList(_getFilteredBookings()),
                    _buildBookingsList(_getFilteredBookings()),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBookings,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking history will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.driverName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${booking.pickupLocation ?? 'N/A'} → ${booking.dropoffLocation ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(booking.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.event_seat,
                  label: 'Seats',
                  value: booking.seatsBooked.toString(),
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  icon: Icons.attach_money,
                  label: 'Amount',
                  value: booking.formattedAmount,
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  icon: Icons.schedule,
                  label: 'Date',
                  value: _formatDate(booking.bookingTime),
                ),
              ],
            ),
            if (booking.rating != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.rating!.toStringAsFixed(1)} rating',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (booking.review != null && booking.review!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${booking.review!}"',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (booking.canBeRated) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/rating',
                          arguments: booking.id,
                        );
                      },
                      child: const Text('Rate Ride'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (booking.canBeCancelled) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelBooking(booking),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
                if (!booking.canBeRated && !booking.canBeCancelled) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewBookingDetails(booking),
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case BookingStatus.confirmed:
        color = Colors.blue;
        text = 'Confirmed';
        break;
      case BookingStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case BookingStatus.noShow:
        color = Colors.grey;
        text = 'No Show';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _cancelBooking(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _bookingService.cancelBooking(booking.id,
                    reason: 'Cancelled by user');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Booking cancelled successfully')),
                );
                _loadBookings();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to cancel booking: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _viewBookingDetails(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Driver', booking.driverName),
              _buildDetailRow('From', booking.pickupLocation ?? 'N/A'),
              _buildDetailRow('To', booking.dropoffLocation ?? 'N/A'),
              _buildDetailRow('Seats', booking.seatsBooked.toString()),
              _buildDetailRow('Amount', booking.formattedAmount),
              _buildDetailRow('Status', booking.statusDisplay),
              _buildDetailRow('Payment', booking.paymentStatusDisplay),
              _buildDetailRow('Booked', _formatDate(booking.bookingTime)),
              if (booking.completionTime != null)
                _buildDetailRow(
                    'Completed', _formatDate(booking.completionTime!)),
              if (booking.specialRequests != null &&
                  booking.specialRequests!.isNotEmpty)
                _buildDetailRow('Special Requests', booking.specialRequests!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
