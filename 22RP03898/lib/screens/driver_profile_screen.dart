import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ride_service.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../services/error_service.dart';
import '../models/user_model.dart';
import '../models/ride_model.dart';
import '../models/booking_model.dart';

class DriverProfileScreen extends StatefulWidget {
  final String? driverId;

  const DriverProfileScreen({super.key, this.driverId});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen>
    with SingleTickerProviderStateMixin {
  final RideService _rideService = RideService();
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  final ErrorService _errorService = ErrorService();

  late TabController _tabController;

  UserModel? _driver;
  List<RideModel> _driverRides = [];
  List<BookingModel> _driverBookings = [];
  bool _isLoading = true;
  String? _error;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDriverData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    try {
      final driverId =
          widget.driverId ?? FirebaseAuth.instance.currentUser?.uid;
      if (driverId == null) {
        setState(() {
          _error = 'Driver not found';
          _isLoading = false;
        });
        return;
      }

      // Check if viewing own profile
      final currentUser = FirebaseAuth.instance.currentUser;
      _isCurrentUser = currentUser?.uid == driverId;

      // Load driver information
      final driver = await _authService.getUserById(driverId);
      if (driver == null) {
        setState(() {
          _error = 'Driver not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _driver = driver;
        _isLoading = false;
      });

      // Load driver's rides and bookings
      _loadDriverRides(driverId);
      _loadDriverBookings(driverId);
    } catch (e) {
      _errorService.logError('Error loading driver data', e);
      if (mounted) {
        setState(() {
          _error = 'Failed to load driver data';
          _isLoading = false;
        });
      }
    }
  }

  void _loadDriverRides(String driverId) {
    _rideService.getRidesByDriver(driverId).listen((rides) {
      if (mounted) {
        setState(() {
          _driverRides = rides;
        });
      }
    });
  }

  void _loadDriverBookings(String driverId) {
    _bookingService.getDriverBookingsStream(driverId).listen((bookings) {
      if (mounted) {
        setState(() {
          _driverBookings = bookings;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCurrentUser ? 'My Profile' : 'Driver Profile'),
        actions: [
          if (!_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: _contactDriver,
            ),
          if (!_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: _callDriver,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Rides'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _driver == null
                  ? _buildErrorWidget()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProfileTab(),
                        _buildRidesTab(),
                        _buildReviewsTab(),
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Driver not found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildDriverStats(),
          const SizedBox(height: 24),
          _buildContactInfo(),
          const SizedBox(height: 24),
          _buildVehicleInfo(),
          if (_driver?.bio != null && _driver!.bio!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildBioSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple.shade100,
              child: _driver?.profileImage != null
                  ? ClipOval(
                      child: Image.network(
                        _driver!.profileImage!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.deepPurple.shade700,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.deepPurple.shade700,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              _driver?.name ?? 'Driver',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _driver?.userTypeDisplay ?? 'Driver',
                    style: TextStyle(
                      color: Colors.deepPurple.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_driver?.isPremium == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_driver?.rating != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _driver!.rating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${_driver?.completedRides ?? 0} rides)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.directions_bus,
                    label: 'Total Rides',
                    value: '${_driver?.totalRides ?? 0}',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    value: '${_driver?.completedRides ?? 0}',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.calendar_today,
                    label: 'Member Since',
                    value: _getMemberSinceText(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_driver?.phone != null) ...[
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Phone'),
                subtitle: Text(_driver!.phone!),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: _callDriver,
                ),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(_driver?.email ?? 'Not provided'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_driver?.vehicleType != null) ...[
              ListTile(
                leading: const Icon(Icons.directions_bus),
                title: const Text('Vehicle Type'),
                subtitle: Text(_driver!.vehicleType!),
              ),
            ],
            if (_driver?.vehicleNumber != null) ...[
              ListTile(
                leading: const Icon(Icons.confirmation_number),
                title: const Text('Vehicle Number'),
                subtitle: Text(_driver!.vehicleNumber!),
              ),
            ],
            if (_driver?.licenseNumber != null) ...[
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('License Number'),
                subtitle: Text(_driver!.licenseNumber!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _driver!.bio!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesTab() {
    if (_driverRides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No rides posted yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _driverRides.length,
      itemBuilder: (context, index) {
        final ride = _driverRides[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: Icon(
                _getVehicleIcon(ride.vehicleType),
                color: Colors.deepPurple.shade700,
              ),
            ),
            title: Text(
              '${ride.origin.name} → ${ride.destination.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride.formattedDepartureTime),
                Text(
                  '${ride.vehicleTypeDisplay} • ${ride.formattedPrice}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${ride.availableSeats}/${ride.totalSeats}',
                  style: TextStyle(
                    color: ride.availableSeats > 0
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'seats',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/book-ride',
                arguments: ride.id,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    final reviews =
        _driverBookings.where((booking) => booking.rating != null).toList();

    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final booking = reviews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        booking.passengerName[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.passengerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            booking.formattedBookingTime,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (booking.review != null && booking.review!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    booking.review!,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _contactDriver() {
    if (_driver?.phone != null) {
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'otherUserId': _driver!.id,
          'otherUserName': _driver!.name,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Driver contact information not available')),
      );
    }
  }

  void _callDriver() {
    if (_driver?.phone != null) {
      // In a real app, you would use url_launcher to make a phone call
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calling ${_driver!.phone}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver phone number not available')),
      );
    }
  }

  String _getMemberSinceText() {
    if (_driver?.createdAt == null) return 'N/A';

    final now = DateTime.now();
    final createdAt = _driver!.createdAt;
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}m ago';
    } else {
      return '${difference.inDays}d ago';
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
