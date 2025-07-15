import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../services/booking_service.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import '../services/error_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/error_message.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:saferide/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BookingScreen extends StatefulWidget {
  final bool isPremium;
  const BookingScreen({super.key, this.isPremium = false});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with TickerProviderStateMixin {
  final RideService _rideService = RideService();
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  final ErrorService _errorService = ErrorService();

  List<RideModel> _availableRides = [];
  List<BookingModel> _bookingHistory = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isBooking = false;
  String? _error;
  BannerAd? _bannerAd;
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _initAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initAd() async {
    await AdService().initialize();
    setState(() {
      _bannerAd = AdService().getBannerAd();
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load current user
      _currentUser = await _authService.getCurrentUserModel();

      // Load available rides
      _rideService.getAvailableRides().listen((rides) {
        if (mounted) {
          setState(() {
            _availableRides = rides;
            _isLoading = false;
          });
        }
      });

      // Load booking history
      if (_currentUser != null) {
        _bookingService
            .getUserBookingsStream(_currentUser!.id)
            .listen((bookings) {
          if (mounted) {
            setState(() {
              _bookingHistory = bookings;
            });
          }
        });
      }
    } catch (e) {
      _errorService.logError('Error loading booking data', e);
      if (mounted) {
        setState(() {
          _error = 'Failed to load rides';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _bookRide(RideModel ride) async {
    if (ride.availableSeats > 0) {
      setState(() {
        _isBooking = true;
      });

      try {
        final booking = await _bookingService.createBooking(
          rideId: ride.id,
          seatsBooked: 1,
          pickupLocation: ride.origin.name,
          dropoffLocation: ride.destination.name,
        );

        await FirebaseAnalytics.instance.logEvent(
          name: 'ride_booked',
          parameters: {
            'origin': ride.origin.name,
            'destination': ride.destination.name,
            'departureTime': ride.departureTime.toIso8601String(),
            'bookingId': booking.id,
          },
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking confirmed! Booking ID: ${booking.id}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (e) {
        _errorService.logError('Booking error', e);
        if (!mounted) return;
        final errorMsg = e.toString().contains('not found') ||
                e.toString().contains('not available')
            ? 'This ride is no longer available. Please choose another.'
            : 'Booking failed: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isBooking = false;
          });
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No seats available for this ride.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _contactDriver(RideModel ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.contact_phone, color: Colors.deepPurple.shade600),
            const SizedBox(width: 8),
            const Text('Contact Driver'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((ride.driverPhone ?? '').isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Call Driver'),
                subtitle: Text(ride.driverPhone ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  if (ride.driverPhone != null) {
                    _makePhoneCall(ride.driverPhone!);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble, color: Colors.green),
                title: const Text('WhatsApp'),
                subtitle: Text('+250 ${ride.driverPhone ?? ''}'),
                onTap: () {
                  Navigator.pop(context);
                  if (ride.driverPhone != null) {
                    _openWhatsApp(ride.driverPhone!);
                  }
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('Send Message'),
              subtitle: const Text('In-app messaging'),
              onTap: () {
                Navigator.pop(context);
                if (ride.driverId != null) {
                  _sendMessage(ride.driverId!);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) {
    // Implementation for making phone call
  }

  void _openWhatsApp(String phoneNumber) {
    // Implementation for opening WhatsApp
  }

  void _sendMessage(String driverId) {
    // Implementation for sending in-app message
  }

  List<RideModel> _getFilteredRides() {
    var rides = _availableRides;

    if (_searchQuery.isNotEmpty) {
      rides = rides
          .where((ride) =>
              ride.origin.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              ride.destination.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              ride.driverName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    switch (_selectedFilter) {
      case 'Premium':
        rides = rides.where((ride) => ride.isPremium).toList();
        break;
      case 'Today':
        final today = DateTime.now();
        rides = rides
            .where((ride) =>
                ride.departureTime.day == today.day &&
                ride.departureTime.month == today.month &&
                ride.departureTime.year == today.year)
            .toList();
        break;
      case 'Available':
        rides = rides.where((ride) => ride.availableSeats > 0).toList();
        break;
    }

    return rides;
  }

  List<BookingModel> _getFilteredBookings() {
    var bookings = _bookingHistory;

    if (_searchQuery.isNotEmpty) {
      bookings = bookings
          .where((booking) =>
              booking.driverName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (booking.pickupLocation ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (booking.dropoffLocation ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return bookings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading rides...'),
                ],
              ),
            )
          : _error != null
              ? ErrorMessage(
                  error: _error!,
                  onRetry: _loadData,
                )
              : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.deepPurple,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.book_online,
              color: Colors.deepPurple.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Book Ride',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Available Rides'),
          Tab(text: 'My Bookings'),
        ],
        labelColor: Colors.deepPurple,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRidesTab(),
              _buildBookingsTab(),
            ],
          ),
        ),
        if (_bannerAd != null && !kIsWeb)
          SizedBox(
            height: 60,
            child: AdWidget(ad: _bannerAd!),
          ),
        if (kIsWeb)
          Container(
            height: 60,
            color: Colors.grey.shade200,
            child: const Center(
              child: Text(
                'Ad Space (Mobile Only)',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          CustomTextField(
            hintText: 'Search rides or bookings...',
            prefixIcon: Icons.search,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Premium'),
                _buildFilterChip('Today'),
                _buildFilterChip('Available'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.deepPurple.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.deepPurple.shade700 : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildRidesTab() {
    final filteredRides = _getFilteredRides();

    if (filteredRides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No rides available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
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
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRides.length,
        itemBuilder: (context, index) {
          return _buildRideCard(filteredRides[index]);
        },
      ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getVehicleIcon(ride.vehicleType),
                    color: Colors.deepPurple.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ride.origin.name} → ${ride.destination.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ride.formattedDepartureTime,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ride.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Premium',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.person,
                    label: 'Driver',
                    value: ride.driverName,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.event_seat,
                    label: 'Available',
                    value: '${ride.availableSeats} seats',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.attach_money,
                    label: 'Price',
                    value: ride.formattedPrice,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: ride.availableSeats == 0 ? 'Full' : 'Book Now',
                    onPressed:
                        ride.availableSeats == 0 ? null : () => _bookRide(ride),
                    isLoading: _isBooking,
                    backgroundColor: ride.availableSeats == 0
                        ? Colors.grey.shade300
                        : Colors.deepPurple.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactDriver(ride),
                    icon: const Icon(Icons.contact_phone),
                    label: const Text('Contact'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple.shade600,
                      side: BorderSide(color: Colors.deepPurple.shade600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    final filteredBookings = _getFilteredBookings();

    if (filteredBookings.isEmpty) {
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
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(filteredBookings[index]);
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
                        '${booking.pickupLocation ?? 'N/A'} → ${booking.dropoffLocation ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Driver: ${booking.driverName}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
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
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.event_seat,
                    label: 'Seats',
                    value: booking.seatsBooked.toString(),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.attach_money,
                    label: 'Amount',
                    value: booking.formattedAmount,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.schedule,
                    label: 'Booked',
                    value: _formatDate(booking.bookingTime),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewBookingDetails(booking),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                if (booking.status == BookingStatus.pending ||
                    booking.status == BookingStatus.confirmed)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _cancelBooking(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
              ],
            ),
          ],
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
                await _bookingService.cancelBooking(
                  booking.id,
                  reason: 'Cancelled by user',
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking cancelled successfully'),
                  ),
                );
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

  IconData _getVehicleIcon(VehicleType vehicleType) {
    switch (vehicleType) {
      case VehicleType.bus:
        return Icons.directions_bus;
      case VehicleType.minibus:
        return Icons.airport_shuttle;
      case VehicleType.moto:
        return Icons.motorcycle;
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.truck:
        return Icons.local_shipping;
    }
  }
}
