/// Driver Dashboard Screen for SafeRide
///
/// This screen provides drivers with access to all their features:
/// - Post and manage rides
/// - View and manage bookings
/// - Contact passengers
/// - Track performance and earnings
/// - Manage premium subscription
/// - View reviews and ratings
/// - Monitor ride statistics
/// - Real-time analytics and insights
///
/// TODO: Future Enhancements:
/// - Real-time ride tracking
/// - Advanced analytics dashboard
/// - Automated ride scheduling
/// - Driver verification system
/// - Earnings optimization
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/role_service.dart';
import '../services/ride_service.dart';
import '../services/booking_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../models/ride_model.dart';
import '../models/booking_model.dart';
import 'driver_earnings_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final AuthService _authService = AuthService();
  final RoleService _roleService = RoleService();
  final RideService _rideService = RideService();
  final BookingService _bookingService = BookingService();
  final AnalyticsService _analyticsService = AnalyticsService();

  UserModel? _currentUser;
  List<RideModel> _activeRides = [];
  List<BookingModel> _recentBookings = [];
  Map<String, dynamic> _performanceStats = {};
  List<Map<String, dynamic>> _recentReviews = [];
  bool _isLoading = true;
  String? _error;
  BannerAd? _bannerAd;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadActiveRides();
    _loadRecentBookings();
    _loadPerformanceStats();
    _loadRecentReviews();
    if (!kIsWeb) {
      _initAd();
    }
    _checkPremiumStatus();
    _analyticsService.logEvent('screen_view',
        parameters: {'screen_name': 'driver_dashboard'});
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load user data';
          _isLoading = false;
        });
      }
    }
  }

  void _loadActiveRides() {
    if (_currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _rideService.getRidesByDriver(_currentUser!.id).listen((rides) {
      if (mounted) {
        setState(() {
          _activeRides = rides
              .where((ride) =>
                  ride.status == RideStatus.scheduled ||
                  ride.status == RideStatus.inProgress)
              .take(5)
              .toList();
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load rides';
          _isLoading = false;
        });
      }
    });
  }

  void _loadRecentBookings() {
    if (_currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _bookingService.getDriverBookingsStream(_currentUser!.id).listen(
        (bookings) {
      if (mounted) {
        setState(() {
          _recentBookings = bookings.take(5).toList();
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load bookings';
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadPerformanceStats() async {
    if (_currentUser == null) return;

    try {
      final stats = await _rideService.getDriverRideStats(_currentUser!.id);
      if (mounted) {
        setState(() {
          _performanceStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRecentReviews() async {
    // Mock reviews data - replace with actual reviews service
    setState(() {
      _recentReviews = [
        {
          'id': '1',
          'passengerName': 'John Doe',
          'rating': 5.0,
          'comment': 'Excellent driver! Very punctual and friendly.',
          'date': DateTime.now().subtract(const Duration(days: 2)),
          'rideId': 'ride1',
        },
        {
          'id': '2',
          'passengerName': 'Jane Smith',
          'rating': 4.5,
          'comment': 'Good ride, comfortable journey.',
          'date': DateTime.now().subtract(const Duration(days: 5)),
          'rideId': 'ride2',
        },
        {
          'id': '3',
          'passengerName': 'Mike Johnson',
          'rating': 5.0,
          'comment': 'Professional and safe driver. Highly recommended!',
          'date': DateTime.now().subtract(const Duration(days: 7)),
          'rideId': 'ride3',
        },
      ];
    });
  }

  void _initAd() async {
    if (!kIsWeb) {
      await AdService().initialize();
      setState(() {
        _bannerAd = AdService().getBannerAd();
      });
    }
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final user = await _authService.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _isPremium = user?.isPremium ?? false;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Dashboard')),
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.grey.shade50,
      body: _buildDashboardContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.directions_car,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Driver Dashboard',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    if (_isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PREMIUM',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _currentUser?.name ?? 'Driver',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            await _analyticsService.logLogout();
            await AuthService().signOut();
            if (mounted) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadActiveRides();
        _loadRecentBookings();
        _loadPerformanceStats();
        _loadRecentReviews();
        _checkPremiumStatus();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Upgrade Banner (only show if not premium)
            if (!_isPremium) _buildPremiumBanner(),
            const SizedBox(height: 16),
            _buildPerformanceOverview(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildActiveRides(),
            const SizedBox(height: 24),
            _buildRecentBookings(),
            const SizedBox(height: 24),
            _buildRecentReviews(),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Card(
      color: Colors.amber.shade100,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.amber, size: 32),
        title: const Text('Upgrade to Premium'),
        subtitle: const Text(
            'Appear at the top of search results and get more bookings!'),
        trailing: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/premium'),
          child: const Text('Go Premium'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.analytics,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your earnings and performance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.directions_car,
                    title: 'Total Rides',
                    value: '${_performanceStats['totalRides'] ?? 0}',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    title: 'Completed',
                    value: '${_performanceStats['completedRides'] ?? 0}',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.attach_money,
                    title: 'Earnings',
                    value:
                        'FRW ${(_performanceStats['totalEarnings'] ?? 0).toStringAsFixed(0)}',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.star,
                    title: 'Rating',
                    value: _currentUser?.rating?.toStringAsFixed(1) ?? 'N/A',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.add_circle,
                    label: 'Post Ride',
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/post-ride'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.people,
                    label: 'My Bookings',
                    color: Colors.blue,
                    onTap: () =>
                        Navigator.pushNamed(context, '/driver-bookings'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.analytics,
                    label: 'Analytics',
                    color: Colors.purple,
                    onTap: () => _showAnalytics(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.star,
                    label: 'Reviews',
                    color: Colors.orange,
                    onTap: () => _showReviews(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.account_balance_wallet,
                    label: 'My Earnings',
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DriverEarningsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.subscriptions,
                    label: 'Premium',
                    color: Colors.amber,
                    onTap: () => Navigator.pushNamed(context, '/premium'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRides() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Active Rides',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/driver-rides'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_activeRides.isEmpty)
              _buildEmptyState(
                icon: Icons.directions_car,
                message: 'No active rides',
                actionText: 'Post your first ride',
                onAction: () => Navigator.pushNamed(context, '/post-ride'),
              )
            else
              Column(
                children:
                    _activeRides.map((ride) => _buildRideCard(ride)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getStatusColor(ride.status).withOpacity(0.2),
            child: Icon(
              _getStatusIcon(ride.status),
              color: _getStatusColor(ride.status),
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${ride.availableSeats}/${ride.totalSeats} seats • FRW ${ride.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _getStatusText(ride.status),
                  style: TextStyle(
                    color: _getStatusColor(ride.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleRideAction(value, ride),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16),
                    SizedBox(width: 8),
                    Text('Complete'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Recent Bookings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/driver-bookings'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentBookings.isEmpty)
              _buildEmptyState(
                icon: Icons.people,
                message: 'No recent bookings',
                actionText: 'Post rides to get bookings',
                onAction: () => Navigator.pushNamed(context, '/post-ride'),
              )
            else
              Column(
                children: _recentBookings
                    .map((booking) => _buildBookingCard(booking))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                _getBookingStatusColor(booking.status).withOpacity(0.2),
            child: Icon(
              _getBookingStatusIcon(booking.status),
              color: _getBookingStatusColor(booking.status),
              size: 20,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${booking.seatsBooked} seat(s) • FRW ${booking.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _getBookingStatusText(booking.status),
                  style: TextStyle(
                    color: _getBookingStatusColor(booking.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, size: 20),
            onPressed: () =>
                _contactPassenger(booking.passengerId, booking.passengerPhone),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviews() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Recent Reviews',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentReviews.isEmpty)
              _buildEmptyState(
                icon: Icons.star,
                message: 'No recent reviews',
                actionText: 'Post rides to get reviews',
                onAction: () => Navigator.pushNamed(context, '/post-ride'),
              )
            else
              Column(
                children: _recentReviews
                    .map((review) => _buildReviewCard(review))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                  5,
                  (index) => Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber.shade600,
                        size: 20,
                      )),
              const SizedBox(width: 8),
              Text(
                '${rating.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'] ?? 'No comment',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review['passengerName'] ?? 'Anonymous',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                review['date'] != null
                    ? DateFormat('MMM dd, yyyy').format(review['date']!)
                    : 'N/A',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/post-ride'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Post Ride'),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _loadUserData();
              _loadActiveRides();
              _loadRecentBookings();
              _loadPerformanceStats();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.scheduled:
        return Colors.blue;
      case RideStatus.inProgress:
        return Colors.orange;
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(RideStatus status) {
    switch (status) {
      case RideStatus.scheduled:
        return Icons.schedule;
      case RideStatus.inProgress:
        return Icons.directions_car;
      case RideStatus.completed:
        return Icons.check_circle;
      case RideStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.scheduled:
        return 'Scheduled';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getBookingStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.noShow:
        return Colors.grey;
    }
  }

  IconData _getBookingStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.noShow:
        return Icons.person_off;
    }
  }

  String _getBookingStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  // Action methods
  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            children: [
              _buildNotificationItem(
                'New Booking',
                'John Doe booked 2 seats for your ride to Kigali',
                Icons.people,
                Colors.green,
                '2 min ago',
              ),
              _buildNotificationItem(
                'Ride Reminder',
                'Your ride to Butare starts in 30 minutes',
                Icons.schedule,
                Colors.blue,
                '1 hour ago',
              ),
              _buildNotificationItem(
                'Payment Received',
                'FRW 5,000 received for ride to Gisenyi',
                Icons.payment,
                Colors.orange,
                '2 hours ago',
              ),
              _buildNotificationItem(
                'New Review',
                'You received a 5-star review from Jane Smith',
                Icons.star,
                Colors.amber,
                '1 day ago',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
      String title, String message, IconData icon, Color color, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            radius: 16,
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Analytics'),
        content: SizedBox(
          width: 400,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnalyticsCard(
                  'Total Rides',
                  '${_performanceStats['totalRides'] ?? 0}',
                  Icons.directions_car,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildAnalyticsCard(
                  'Completed Rides',
                  '${_performanceStats['completedRides'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildAnalyticsCard(
                  'Total Earnings',
                  'FRW ${(_performanceStats['totalEarnings'] ?? 0).toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildAnalyticsCard(
                  'Average Rating',
                  _currentUser?.rating?.toStringAsFixed(1) ?? 'N/A',
                  Icons.star,
                  Colors.amber,
                ),
                const SizedBox(height: 16),
                _buildAnalyticsCard(
                  'Active Bookings',
                  '${_recentBookings.where((b) => b.status == BookingStatus.confirmed).length}',
                  Icons.people,
                  Colors.purple,
                ),
                const SizedBox(height: 16),
                _buildAnalyticsCard(
                  'This Month',
                  'FRW ${((_performanceStats['totalEarnings'] ?? 0) * 0.3).toStringAsFixed(0)}',
                  Icons.calendar_today,
                  Colors.indigo,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviews() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Reviews'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: _recentReviews.isEmpty
              ? const Center(
                  child: Text('No reviews yet. Keep providing great service!'),
                )
              : ListView.builder(
                  itemCount: _recentReviews.length,
                  itemBuilder: (context, index) {
                    final review = _recentReviews[index];
                    return _buildReviewCard(review);
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRideBookings(RideModel ride) async {
    final bookings = await _bookingService.getRideBookingsStream(ride.id).first;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Bookings for ${ride.origin.name} → ${ride.destination.name}'),
        content: bookings.isEmpty
            ? const Text('No bookings for this ride yet.')
            : SizedBox(
                width: 350,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(booking.passengerName),
                      subtitle: Text('${booking.seatsBooked} seat(s)'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.blue),
                            tooltip: 'Call',
                            onPressed: () => _contactPassenger(
                                booking.passengerId, booking.passengerPhone),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat,
                                color: Colors.deepPurple),
                            tooltip: 'Message',
                            onPressed: () =>
                                _contactPassenger(booking.passengerId, null),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _contactPassenger(String passengerId, String? passengerPhone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Passenger'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (passengerPhone != null) ...[
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Call Passenger'),
                subtitle: Text(passengerPhone),
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(passengerPhone);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('Send Message'),
              subtitle: const Text('In-app messaging'),
              onTap: () {
                Navigator.pop(context);
                _sendMessage(passengerId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble, color: Colors.green),
              title: const Text('WhatsApp'),
              subtitle: passengerPhone != null
                  ? Text('+250 $passengerPhone')
                  : const Text('Phone number required'),
              onTap: passengerPhone != null
                  ? () {
                      Navigator.pop(context);
                      _openWhatsApp(passengerPhone);
                    }
                  : null,
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
    // TODO: Implement actual phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phoneNumber...')),
    );
  }

  void _sendMessage(String passengerId) {
    // TODO: Implement in-app messaging
    Navigator.pushNamed(context, '/chat',
        arguments: {'passengerId': passengerId});
  }

  void _openWhatsApp(String phoneNumber) {
    // TODO: Implement WhatsApp integration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening WhatsApp for $phoneNumber...')),
    );
  }

  void _handleRideAction(String action, RideModel ride) {
    switch (action) {
      case 'edit':
        Navigator.pushNamed(
          context,
          '/edit-ride',
          arguments: {'rideId': ride.id},
        );
        break;
      case 'delete':
        _showDeleteConfirmation(ride);
        break;
      case 'complete':
        _completeRide(ride);
        break;
    }
  }

  void _showDeleteConfirmation(RideModel ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ride'),
        content: Text(
            'Are you sure you want to delete the ride from ${ride.origin.name} to ${ride.destination.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRide(ride);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRide(RideModel ride) async {
    try {
      await _rideService.deleteRide(ride.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete ride: $e')),
        );
      }
    }
  }

  Future<void> _completeRide(RideModel ride) async {
    try {
      await _rideService.completeRide(ride.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride completed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete ride: $e')),
        );
      }
    }
  }
}
