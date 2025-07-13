import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import '../services/error_service.dart';
import '../services/analytics_service.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/error_message.dart';
import 'post_ride_screen.dart';
import 'booking_screen.dart';

class RideListScreen extends StatefulWidget {
  const RideListScreen({super.key});

  @override
  State<RideListScreen> createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen>
    with TickerProviderStateMixin {
  final RideService _rideService = RideService();
  final AuthService _authService = AuthService();
  final ErrorService _errorService = ErrorService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  RideStatus? _selectedStatus;
  VehicleType? _selectedVehicleType;
  bool _showPremiumOnly = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<RideModel> _allRides = [];
  List<RideModel> _filteredRides = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authService.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
        _loadRides();
        _animationController.forward();
      }
    } catch (e) {
      _errorService.logError('Error loading user data', e);
      if (mounted) {
        setState(() {
          _error = 'Failed to load user data';
          _isLoading = false;
        });
      }
    }
  }

  void _loadRides() {
    if (_currentUser == null) return;

    _rideService.getRidesByDriver(_currentUser!.id).listen(
      (rides) {
        if (mounted) {
          setState(() {
            _allRides.clear();
            _allRides.addAll(rides);
            _applyFilters();
          });
        }
      },
      onError: (e) {
        _errorService.logError('Error loading rides', e);
        if (mounted) {
          setState(() {
            _error = 'Failed to load rides';
          });
        }
      },
    );
  }

  void _applyFilters() {
    _filteredRides = _allRides.where((ride) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesOrigin = ride.origin.name.toLowerCase().contains(query);
        final matchesDestination =
            ride.destination.name.toLowerCase().contains(query);
        final matchesDescription =
            (ride.description ?? '').toLowerCase().contains(query);

        if (!matchesOrigin && !matchesDestination && !matchesDescription) {
          return false;
        }
      }

      // Status filter
      if (_selectedStatus != null && ride.status != _selectedStatus) {
        return false;
      }

      // Vehicle type filter
      if (_selectedVehicleType != null &&
          ride.vehicleType != _selectedVehicleType) {
        return false;
      }

      // Premium filter
      if (_showPremiumOnly && !ride.isPremium) {
        return false;
      }

      return true;
    }).toList();

    // Sort by departure time (newest first)
    _filteredRides.sort((a, b) => b.departureTime.compareTo(a.departureTime));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToPostRide(),
            tooltip: 'Post New Ride',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _error != null
              ? ErrorMessage(
                  error: _error,
                  onRetry: _loadUserData,
                )
              : Column(
                  children: [
                    _buildFilters(),
                    Expanded(
                      child: _filteredRides.isEmpty
                          ? _buildEmptyState()
                          : _buildRideList(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search rides...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status filter
                FilterChip(
                  label:
                      Text(_selectedStatus?.name.toUpperCase() ?? 'All Status'),
                  selected: _selectedStatus != null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? RideStatus.scheduled : null;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Vehicle type filter
                FilterChip(
                  label: Text(_selectedVehicleType?.name.toUpperCase() ??
                      'All Vehicles'),
                  selected: _selectedVehicleType != null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedVehicleType = selected ? VehicleType.bus : null;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Premium filter
                FilterChip(
                  label: const Text('Premium Only'),
                  selected: _showPremiumOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showPremiumOnly = selected;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Clear filters
                if (_selectedStatus != null ||
                    _selectedVehicleType != null ||
                    _showPremiumOnly)
                  FilterChip(
                    label: const Text('Clear'),
                    selected: false,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = null;
                        _selectedVehicleType = null;
                        _showPremiumOnly = false;
                        _applyFilters();
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No rides found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _allRides.isEmpty
                ? 'You haven\'t posted any rides yet'
                : 'Try adjusting your filters',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          if (_allRides.isEmpty)
            CustomButton(
              text: 'Post Your First Ride',
              onPressed: _navigateToPostRide,
              backgroundColor: Colors.deepPurple.shade600,
              textColor: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget _buildRideList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRides.length,
      itemBuilder: (context, index) {
        final ride = _filteredRides[index];
        return _buildRideCard(ride);
      },
    );
  }

  Widget _buildRideCard(RideModel ride) {
    final isPast = ride.departureTime.isBefore(DateTime.now());
    final isToday = ride.departureTime.day == DateTime.now().day &&
        ride.departureTime.month == DateTime.now().month &&
        ride.departureTime.year == DateTime.now().year;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              ride.isPremium ? Colors.amber.shade50 : Colors.grey.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and premium badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ride.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusDisplay(ride.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (ride.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Route information
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.green.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ride.origin.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.red.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ride.destination.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${ride.price.toStringAsFixed(0)} FRW',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                      Text(
                        'per seat',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Schedule and vehicle info
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(ride.departureTime),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    TimeOfDay.fromDateTime(ride.departureTime).format(context),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _getVehicleIcon(ride.vehicleType),
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ride.vehicleType.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Seats and booking info
              Row(
                children: [
                  Icon(
                    Icons.airline_seat_recline_normal,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.availableSeats}/${ride.totalSeats} seats available',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (ride.vehicleNumber != null &&
                      ride.vehicleNumber!.isNotEmpty)
                    Text(
                      ride.vehicleNumber!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              if (ride.description != null && ride.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ride.description!,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewBookings(ride),
                      icon: const Icon(Icons.people),
                      label: const Text('View Bookings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple.shade600,
                        side: BorderSide(color: Colors.deepPurple.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editRide(ride),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade600,
                        side: BorderSide(color: Colors.orange.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateRideStatus(ride),
                      icon: const Icon(Icons.update),
                      label: const Text('Status'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade600),
                      ),
                    ),
                  ),
                ],
              ),
              if (ride.status == RideStatus.scheduled) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteRide(ride),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Ride'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.scheduled:
        return Colors.blue.shade600;
      case RideStatus.inProgress:
        return Colors.orange.shade600;
      case RideStatus.completed:
        return Colors.green.shade600;
      case RideStatus.cancelled:
        return Colors.red.shade600;
    }
  }

  String _getStatusDisplay(RideStatus status) {
    switch (status) {
      case RideStatus.scheduled:
        return 'SCHEDULED';
      case RideStatus.inProgress:
        return 'IN PROGRESS';
      case RideStatus.completed:
        return 'COMPLETED';
      case RideStatus.cancelled:
        return 'CANCELLED';
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

  void _navigateToPostRide() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostRideScreen(),
      ),
    );

    if (result == true) {
      // Refresh the ride list
      _loadRides();
    }
  }

  void _editRide(RideModel ride) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostRideScreen(editRide: ride),
      ),
    );

    if (result == true) {
      // Refresh the ride list
      _loadRides();
    }
  }

  void _viewBookings(RideModel ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookingScreen(),
      ),
    );
  }

  void _updateRideStatus(RideModel ride) async {
    final newStatus = await showDialog<RideStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Ride Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RideStatus.values.map((status) {
            return ListTile(
              title: Text(_getStatusDisplay(status)),
              leading: Icon(
                Icons.circle,
                color: _getStatusColor(status),
                size: 16,
              ),
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null && newStatus != ride.status) {
      try {
        await _rideService.updateRideStatus(ride.id, newStatus);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Ride status updated to ${_getStatusDisplay(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _errorService.logError('Error updating ride status', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to update ride status: ${_errorService.getUserFriendlyErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteRide(RideModel ride) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ride'),
        content: const Text(
            'Are you sure you want to delete this ride? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _rideService.deleteRide(ride.id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _errorService.logError('Error deleting ride', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to delete ride: ${_errorService.getUserFriendlyErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
