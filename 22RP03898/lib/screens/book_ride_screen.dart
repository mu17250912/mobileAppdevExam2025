import 'package:flutter/material.dart';
import 'dart:async';
import 'package:saferide/models/ride_model.dart';
import 'package:saferide/models/booking_model.dart';
import 'package:saferide/models/payment_method.dart';
import 'package:saferide/models/user_model.dart';
import 'package:saferide/services/booking_service.dart';
import 'package:saferide/services/ride_service.dart';
import 'package:saferide/services/auth_service.dart';
import 'package:saferide/services/error_service.dart';
import 'package:saferide/screens/payment_screen.dart';
import 'package:saferide/widgets/custom_button.dart';
import 'package:saferide/widgets/custom_text_field.dart';
import 'package:saferide/widgets/loading_overlay.dart';
import 'package:saferide/widgets/error_message.dart';
import 'package:url_launcher/url_launcher.dart';

class BookRideScreen extends StatefulWidget {
  final String? rideId;

  const BookRideScreen({super.key, this.rideId});

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen>
    with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final RideService _rideService = RideService();
  final AuthService _authService = AuthService();
  final ErrorService _errorService = ErrorService();

  RideModel? _ride;
  UserModel? _currentUser;
  BookingModel? _currentBooking;
  bool _isLoading = true;
  bool _isBooking = false;
  bool _isRefreshing = false;
  String? _error;

  // Booking form
  int _seatsToBook = 1;
  String _pickupLocation = '';
  String _dropoffLocation = '';
  String _specialRequests = '';
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  // Form validation
  final _formKey = GlobalKey<FormState>();
  bool _isFormValid = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Real-time updates
  StreamSubscription<RideModel>? _rideSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRideDetails();
    _loadUserData();
    _loadCurrentBooking();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _rideSubscription?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _startRealTimeUpdates() {
    if (widget.rideId != null) {
      // For now, we'll use a simple timer to refresh data
      // TODO: Implement proper stream when RideService supports it
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted) {
          _refreshRideData();
        } else {
          timer.cancel();
        }
      });
    }
  }

  Future<void> _loadRideDetails() async {
    try {
      if (widget.rideId != null) {
        final ride = await _rideService.getRideById(widget.rideId!);
        if (!mounted) return;
        setState(() {
          _ride = ride;
          _isLoading = false;
        });
        _validateForm();
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'Ride not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      _errorService.logError('Error loading ride details', e);
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load ride details';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      _errorService.logError('Error loading user data', e);
    }
  }

  Future<void> _loadCurrentBooking() async {
    try {
      if (widget.rideId != null && _currentUser != null) {
        final bookings =
            await _bookingService.getUserBookings(_currentUser!.id);
        final booking = bookings
            .where((b) => b.rideId == (widget.rideId ?? ''))
            .firstOrNull;
        if (mounted) {
          setState(() {
            _currentBooking = booking;
          });
        }
      }
    } catch (e) {
      _errorService.logError('Error loading current booking', e);
    }
  }

  void _validateForm() {
    if (_ride != null) {
      final isValid = _seatsToBook > 0 &&
          _seatsToBook <= _ride!.availableSeats &&
          _currentUser != null;
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _refreshRideData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadRideDetails();
      await _loadCurrentBooking();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _pickLocation(bool isPickup) async {
    try {
      // For now, we'll use a simple dialog to pick location
      // TODO: Implement proper location picker when LocationService supports it
      final location = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title:
              Text(isPickup ? 'Pick Pickup Location' : 'Pick Dropoff Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Current Location'),
                onTap: () => Navigator.pop(context, 'Current Location'),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () => Navigator.pop(context, 'Home'),
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Work'),
                onTap: () => Navigator.pop(context, 'Work'),
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

      if (location != null) {
        setState(() {
          if (isPickup) {
            _pickupLocation = location;
          } else {
            _dropoffLocation = location;
          }
        });
      }
    } catch (e) {
      _errorService.logError('Error picking location', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick location')),
        );
      }
    }
  }

  void _contactDriver() {
    if (_ride?.driverPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver contact not available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact ${_ride!.driverName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Call Driver'),
              subtitle: Text(_ride!.driverPhone!),
              onTap: () => _makePhoneCall(_ride!.driverPhone!),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble, color: Colors.green),
              title: const Text('WhatsApp'),
              subtitle: Text('+250 ${_ride!.driverPhone!}'),
              onTap: () => _openWhatsApp(_ride!.driverPhone!),
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('Send SMS'),
              subtitle: Text('+250 ${_ride!.driverPhone!}'),
              onTap: () => _sendSMS(_ride!.driverPhone!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:+250$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
    Navigator.pop(context);
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final url =
        'https://wa.me/250$phoneNumber?text=Hi, I have a question about the ride.';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
    Navigator.pop(context);
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final url =
        'sms:+250$phoneNumber?body=Hi, I have a question about the ride.';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
    Navigator.pop(context);
  }

  void _showBookingConfirmation(BookingModel booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Booking Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking ID: ${booking.id}'),
            const SizedBox(height: 8),
            Text('Driver: ${booking.driverName}'),
            const SizedBox(height: 8),
            Text('From: ${booking.pickupLocation ?? _ride!.origin.name}'),
            const SizedBox(height: 8),
            Text('To: ${booking.dropoffLocation ?? _ride!.destination.name}'),
            const SizedBox(height: 8),
            Text('Seats: ${booking.seatsBooked}'),
            const SizedBox(height: 8),
            Text('Amount: ${booking.formattedAmount}'),
            const SizedBox(height: 8),
            Text('Status: ${booking.statusDisplay}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will receive a confirmation SMS shortly. Please arrive 10 minutes before departure.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushNamed(context, '/booking-history');
            },
            child: const Text('View Bookings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildProfessionalAppBar(),
      body: _isLoading
          ? const FullScreenLoading(message: 'Loading ride details...')
          : _error != null
              ? ErrorMessage(
                  error: _error!,
                  onRetry: _loadRideDetails,
                )
              : _ride == null
                  ? ErrorMessage(
                      error: 'Ride not found',
                      onRetry: _loadRideDetails,
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildBookingForm(),
                      ),
                    ),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar() {
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
      actions: [
        if (_ride != null)
          IconButton(
            onPressed: _isRefreshing ? null : _refreshRideData,
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple.shade600,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        if (_ride != null)
          IconButton(
            onPressed: _contactDriver,
            icon: const Icon(Icons.contact_phone),
            tooltip: 'Contact Driver',
          ),
      ],
    );
  }

  Widget _buildBookingForm() {
    final totalAmount = _ride!.price * _seatsToBook;
    final premiumFee = _ride!.isPremium ? (totalAmount * 0.1) : 0.0;
    final finalTotal = totalAmount + premiumFee;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRideDetailsCard(),
            const SizedBox(height: 24),
            _buildBookingFormCard(),
            const SizedBox(height: 24),
            _buildPaymentSection(),
            const SizedBox(height: 24),
            _buildFareBreakdown(totalAmount, premiumFee, finalTotal),
            const SizedBox(height: 32),
            _buildActionButtons(finalTotal),
            const SizedBox(height: 100), // Space for bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildRideDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getVehicleIcon(_ride!.vehicleType),
                    color: Colors.deepPurple.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_ride!.origin.name} → ${_ride!.destination.name}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _ride!.formattedDepartureTime,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_ride!.isPremium)
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.person,
                      label: 'Driver',
                      value: _ride!.driverName,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.event_seat,
                      label: 'Available',
                      value: '${_ride!.availableSeats} seats',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.attach_money,
                      label: 'Price per Seat',
                      value: _ride!.formattedPrice,
                    ),
                  ),
                ],
              ),
            ),
            if (_ride!.driverRating != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_ride!.driverRating!.toStringAsFixed(1)} rating',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_ride!.driverPhone != null)
                      TextButton.icon(
                        onPressed: _contactDriver,
                        icon: const Icon(Icons.contact_phone, size: 16),
                        label: const Text('Contact'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.amber.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (_ride!.description != null &&
                _ride!.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _ride!.description!,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBookingFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: Colors.deepPurple.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Seats Selection
            Row(
              children: [
                const Text('Number of Seats:'),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _seatsToBook > 1
                            ? () {
                                setState(() {
                                  _seatsToBook--;
                                });
                                _validateForm();
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_seatsToBook',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _seatsToBook < _ride!.availableSeats
                            ? () {
                                setState(() {
                                  _seatsToBook++;
                                });
                                _validateForm();
                              }
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pickup Location
            CustomTextField(
              labelText: 'Pickup Location (Optional)',
              hintText: 'Specific pickup point',
              prefixIcon: Icons.location_on,
              onChanged: (value) {
                setState(() {
                  _pickupLocation = value;
                });
              },
              suffixIcon: IconButton(
                onPressed: () => _pickLocation(true),
                icon: const Icon(Icons.my_location),
                tooltip: 'Pick from map',
              ),
            ),
            const SizedBox(height: 12),

            // Dropoff Location
            CustomTextField(
              labelText: 'Drop-off Location (Optional)',
              hintText: 'Specific drop-off point',
              prefixIcon: Icons.location_on_outlined,
              onChanged: (value) {
                setState(() {
                  _dropoffLocation = value;
                });
              },
              suffixIcon: IconButton(
                onPressed: () => _pickLocation(false),
                icon: const Icon(Icons.my_location),
                tooltip: 'Pick from map',
              ),
            ),
            const SizedBox(height: 12),

            // Special Requests
            CustomTextField(
              labelText: 'Special Requests (Optional)',
              hintText: 'Any special requirements or preferences',
              prefixIcon: Icons.note,
              onChanged: (value) {
                setState(() {
                  _specialRequests = value;
                });
              },
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.deepPurple.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // MTN Mobile Money Option
            RadioListTile<PaymentMethod>(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.phone_android,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('MTN Mobile Money'),
                ],
              ),
              subtitle: const Text('Pay with MTN Mobile Money (Recommended)'),
              value: PaymentMethod.mobileMoney,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),

            // Airtel Money Option
            RadioListTile<PaymentMethod>(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.phone_android,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Airtel Money'),
                ],
              ),
              subtitle: const Text('Pay with Airtel Money'),
              value: PaymentMethod.bankTransfer,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),

            // Cash Option
            RadioListTile<PaymentMethod>(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.money,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Cash Payment'),
                ],
              ),
              subtitle: const Text('Pay in cash to the driver'),
              value: PaymentMethod.cash,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareBreakdown(
      double totalAmount, double premiumFee, double finalTotal) {
    return Card(
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Colors.deepPurple.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Fare Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price per seat:'),
                Text(_ride!.formattedPrice),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seats:'),
                Text('$_seatsToBook'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text('${totalAmount.toStringAsFixed(0)} FRW'),
              ],
            ),
            if (_ride!.isPremium) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Premium fee (10%):'),
                  Text('${premiumFee.toStringAsFixed(0)} FRW'),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${finalTotal.toStringAsFixed(0)} FRW',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Text(
                      '\$${(finalTotal / 1000).toStringAsFixed(2)} USD',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(double finalTotal) {
    final hasActiveBooking = _currentBooking != null &&
        _currentBooking!.status != BookingStatus.cancelled &&
        _currentBooking!.status != BookingStatus.completed;
    return Column(
      children: [
        if (hasActiveBooking) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have already booked this ride. Check your booking history for details.',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Book Button
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: _ride!.availableSeats == 0
                ? 'Ride Full'
                : hasActiveBooking
                    ? 'Already Booked'
                    : 'Book Now',
            onPressed: (_isBooking ||
                    _ride!.availableSeats == 0 ||
                    !_isFormValid ||
                    hasActiveBooking)
                ? null
                : () => _bookRide(finalTotal),
            isLoading: _isBooking,
            backgroundColor: _ride!.availableSeats == 0 || hasActiveBooking
                ? Colors.grey.shade400
                : Colors.deepPurple.shade600,
          ),
        ),

        // Cancel Booking Button
        if (hasActiveBooking) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _cancelBooking(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade600),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel Booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _bookRide(double finalTotal) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book a ride')),
      );
      return;
    }

    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your booking details')),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      // Handle payment based on selected method
      if (_selectedPaymentMethod == PaymentMethod.mobileMoney ||
          _selectedPaymentMethod == PaymentMethod.bankTransfer) {
        final originName = _ride!.origin.name;
        final destinationName = _ride!.destination.name;
        final description = 'Booking: $originName → $destinationName';
        final paymentSuccess = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              amount: finalTotal,
              description: description,
              rideId: _ride!.id,
            ),
          ),
        );

        if (paymentSuccess != true) {
          setState(() {
            _isBooking = false;
          });
          return;
        }
      }

      // Create the booking
      final booking = await _bookingService.createBooking(
        rideId: _ride?.id ?? '',
        seatsBooked: _seatsToBook,
        pickupLocation: _pickupLocation.isNotEmpty ? _pickupLocation : '',
        dropoffLocation: _dropoffLocation.isNotEmpty ? _dropoffLocation : '',
        specialRequests: _specialRequests.isNotEmpty ? _specialRequests : null,
        paymentMethod: _selectedPaymentMethod,
      );

      // TODO: Add analytics logging when Firebase Analytics is properly configured

      if (mounted) {
        _showBookingConfirmation(booking);
      }
    } catch (e) {
      _errorService.logError('Error booking ride', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Booking failed: ${_errorService.getBookingErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _bookingService.cancelBooking(
        _currentBooking!.id,
        reason: 'Cancelled by passenger',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        setState(() {
          _currentBooking = _currentBooking!.copyWith(
            status: BookingStatus.cancelled,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: ${e.toString()}'),
          ),
        );
      }
    }
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
