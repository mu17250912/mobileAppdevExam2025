import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/error_service.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';
import '../models/ride_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import 'monetization_dashboard_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final ErrorService _errorService = ErrorService();
  final AdminService _adminService = AdminService();

  late TabController _tabController;

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  // Analytics data
  int _totalUsers = 0;
  int _totalDrivers = 0;
  int _totalBookings = 0;
  double _totalRevenue = 0;
  int _activeRides = 0;
  int _pendingBookings = 0;

  // Helper methods for user display
  Widget _buildStatusChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.grey.shade800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Colors.red;
      case UserType.driver:
        return Colors.blue;
      case UserType.passenger:
        return Colors.green;
    }
  }

  IconData _getUserTypeIcon(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Icons.admin_panel_settings;
      case UserType.driver:
        return Icons.drive_eta;
      case UserType.passenger:
        return Icons.person;
    }
  }

  String _getUserResponsibilities(UserModel user) {
    switch (user.userType) {
      case UserType.admin:
        return 'System administrator with full access to manage users, rides, analytics, and system settings. Can ban/unban users, generate reports, and configure app-wide settings.';
      case UserType.driver:
        return 'Transport provider responsible for posting rides, managing bookings, ensuring passenger safety, and maintaining vehicle standards. Must verify documents and maintain good ratings.';
      case UserType.passenger:
        return 'Transport user who books rides, provides feedback, and follows community guidelines. Responsible for timely payments and respectful behavior during trips.';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 6, vsync: this); // Added monetization tab
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    try {
      final user = await _authService.getCurrentUserModel();
      if (user == null || user.userType != UserType.admin) {
        setState(() {
          _error = 'Access denied. Admin privileges required.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      _loadAnalytics();
    } catch (e) {
      _errorService.logError('Error loading admin data', e);
      if (mounted) {
        setState(() {
          _error = 'Failed to load admin data';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _adminService.loadAnalytics();

      if (mounted) {
        setState(() {
          _totalUsers = analytics['users']['total'] ?? 0;
          _totalDrivers = analytics['users']['drivers'] ?? 0;
          _totalBookings = analytics['bookings']['total'] ?? 0;
          _totalRevenue = analytics['revenue']['total'] ?? 0.0;
          _activeRides = analytics['rides']['active'] ?? 0;
          _pendingBookings = analytics['bookings']['pending'] ?? 0;
        });
      }
    } catch (e) {
      _errorService.logError('Error loading analytics', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Users'),
            Tab(text: 'Rides'),
            Tab(text: 'Payments'),
            Tab(text: 'Monetization'),
            Tab(text: 'Reports'),
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
                    _buildDashboardTab(),
                    _buildUsersTab(),
                    _buildRidesTab(),
                    _buildPaymentsTab(),
                    _buildMonetizationTab(),
                    _buildReportsTab(),
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
            _error!,
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

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: _currentUser?.profileImage != null
                      ? ClipOval(
                          child: Image.network(
                            _currentUser!.profileImage!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.admin_panel_settings,
                                size: 25,
                                color: Colors.deepPurple.shade700,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.admin_panel_settings,
                          size: 25,
                          color: Colors.deepPurple.shade700,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${_currentUser?.name ?? 'Admin'}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here\'s what\'s happening with SafeRide today',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.people,
          title: 'Total Users',
          value: _totalUsers.toString(),
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.drive_eta,
          title: 'Total Drivers',
          value: _totalDrivers.toString(),
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.directions_bus,
          title: 'Active Rides',
          value: _activeRides.toString(),
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.book_online,
          title: 'Pending Bookings',
          value: _pendingBookings.toString(),
          color: Colors.red,
        ),
        _buildStatCard(
          icon: Icons.attach_money,
          title: 'Total Revenue',
          value: 'NGN ${_totalRevenue.toStringAsFixed(0)}',
          color: Colors.purple,
        ),
        _buildStatCard(
          icon: Icons.analytics,
          title: 'Total Bookings',
          value: _totalBookings.toString(),
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.person_add,
                    label: 'Add User/Driver',
                    onTap: _addUser,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.block,
                    label: 'Ban User',
                    onTap: _banUser,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.analytics,
                    label: 'Generate Report',
                    onTap: _generateReport,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.settings,
                    label: 'System Settings',
                    onTap: _systemSettings,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.notifications_active,
                    label: 'Send Notification',
                    onTap: _showSendNotificationDialog,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha((0.3 * 255).toInt())),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
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

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('bookings')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bookings = snapshot.data!.docs;
                if (bookings.isEmpty) {
                  return Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return Column(
                  children: bookings.map((doc) {
                    final booking = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(
                          Icons.book_online,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      title: Text(
                          'New booking by ${booking['passengerName'] ?? 'User'}'),
                      subtitle: Text(
                        '${booking['origin']} → ${booking['destination']}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: Text(
                        _formatTime(
                            (booking['createdAt'] as Timestamp).toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final user = UserModel.fromMap(userData, users[index].id);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey.shade200,
                          child: user.profileImage != null
                              ? ClipOval(
                                  child: Image.network(
                                    user.profileImage!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        color: Colors.grey.shade600,
                                        size: 25,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: Colors.grey.shade600,
                                  size: 25,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('View Details'),
                              onTap: () => _viewUserDetails(user),
                            ),
                            PopupMenuItem(
                              child: Text(
                                  user.isBanned ? 'Unban User' : 'Ban User'),
                              onTap: () => _toggleUserBan(user),
                            ),
                            PopupMenuItem(
                              child: const Text('Delete User'),
                              onTap: () => _deleteUser(user),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Role & Status Section
                    Row(
                      children: [
                        _buildStatusChip(
                          label: user.userTypeDisplay,
                          color: _getUserTypeColor(user.userType),
                          icon: _getUserTypeIcon(user.userType),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          label: user.isVerified ? 'Verified' : 'Unverified',
                          color: user.isVerified ? Colors.green : Colors.orange,
                          icon:
                              user.isVerified ? Icons.verified : Icons.warning,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          label: user.isBanned ? 'Banned' : 'Active',
                          color: user.isBanned ? Colors.red : Colors.green,
                          icon:
                              user.isBanned ? Icons.block : Icons.check_circle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Responsibilities Section
                    Text(
                      'Responsibilities & Role',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getUserResponsibilities(user),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Performance Metrics
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Total Rides',
                            value: user.totalRides.toString(),
                            icon: Icons.directions_car,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Completed',
                            value: user.completedRides.toString(),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Rating',
                            value: user.rating?.toStringAsFixed(1) ?? 'N/A',
                            icon: Icons.star,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Additional Info
                    if (user.isDriver) ...[
                      _buildInfoRow(
                          'Vehicle Type', user.vehicleType ?? 'Not specified'),
                      _buildInfoRow('Vehicle Number',
                          user.vehicleNumber ?? 'Not specified'),
                      _buildInfoRow('License Number',
                          user.licenseNumber ?? 'Not specified'),
                    ],
                    _buildInfoRow('Member Since', _formatDate(user.createdAt)),
                    _buildInfoRow('Last Active', _formatDate(user.lastActive)),
                    if (user.isPremium)
                      _buildInfoRow('Premium Status', 'Premium Member',
                          color: Colors.purple),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRidesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('rides').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rides = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final rideData = rides[index].data() as Map<String, dynamic>;
            final ride = RideModel.fromMap(rideData);

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
                title: Text('${ride.origin.name} → ${ride.destination.name}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.driverName),
                    Text(
                      '${ride.formattedDepartureTime} • ${ride.formattedPrice}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('View Details'),
                      onTap: () => _viewRideDetails(ride),
                    ),
                    PopupMenuItem(
                      child: const Text('Cancel Ride'),
                      onTap: () => _cancelRide(ride),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentStatsCard(),
          const SizedBox(height: 16),
          _buildPaymentActionsCard(),
        ],
      ),
    );
  }

  Widget _buildPaymentStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withValues(alpha: 0.1),
              Colors.green.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Colors.green.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPaymentStatItem(
                'Total Revenue',
                '${_totalRevenue.toStringAsFixed(0)} FRW (\$${(_totalRevenue / 1000).toStringAsFixed(2)} USD)',
                Icons.attach_money),
            _buildPaymentStatItem(
                'MTN Mobile Money', '65%', Icons.phone_android),
            _buildPaymentStatItem('Airtel Money', '25%', Icons.phone_android),
            _buildPaymentStatItem('M-Pesa', '10%', Icons.phone_android),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withValues(alpha: 0.1),
              Colors.blue.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Colors.blue.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPaymentActionButton(
              'View Payment History',
              Icons.history,
              Colors.blue,
              () {
                // TODO: Implement payment history view
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Payment history feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentActionButton(
              'Generate Payment Report',
              Icons.assessment,
              Colors.green,
              () {
                // TODO: Implement payment report generation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Payment report feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildMonetizationTab() {
    return const MonetizationDashboardScreen();
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReportCard(
            title: 'User Growth Report',
            description: 'Monthly user registration trends',
            icon: Icons.trending_up,
            onTap: () => _generateUserReport(),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            title: 'Revenue Report',
            description: 'Monthly revenue and booking statistics',
            icon: Icons.attach_money,
            onTap: () => _generateRevenueReport(),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            title: 'Ride Performance Report',
            description: 'Popular routes and driver performance',
            icon: Icons.analytics,
            onTap: () => _generateRideReport(),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            title: 'System Health Report',
            description: 'App performance and error logs',
            icon: Icons.health_and_safety,
            onTap: () => _generateSystemReport(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
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
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action methods
  void _addUser() {
    showDialog(
      context: context,
      builder: (context) => _AddUserDialog(
        onUserAdded: () {
          _loadAnalytics();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _banUser() {
    showDialog(
      context: context,
      builder: (context) => _BanUserDialog(
        onUserBanned: () {
          _loadAnalytics();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _generateReport() {
    showDialog(
      context: context,
      builder: (context) => _GenerateReportDialog(
        onReportGenerated: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _systemSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _SystemSettingsScreen(),
      ),
    );
  }

  void _viewUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => _UserDetailsDialog(
        user: user,
        onEdit: user.isDriver
            ? () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => _EditDriverDialog(
                    user: user,
                    onDriverUpdated: _loadAnalytics,
                  ),
                );
              }
            : null,
      ),
    );
  }

  void _toggleUserBan(UserModel user) async {
    try {
      final success =
          await _adminService.toggleUserBan(user.id, !user.isBanned);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${user.name} has been ${user.isBanned ? 'unbanned' : 'banned'}')),
        );
        _loadAnalytics();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user status')),
        );
      }
    } catch (e) {
      _errorService.logError('Error toggling user ban', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _deleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final success = await _adminService.deleteUser(user.id);
                if (!mounted) return;
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${user.name} has been deleted')),
                  );
                  _loadAnalytics();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete user')),
                  );
                }
              } catch (e) {
                _errorService.logError('Error deleting user', e);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewRideDetails(RideModel ride) {
    showDialog(
      context: context,
      builder: (context) => _RideDetailsDialog(ride: ride),
    );
  }

  void _cancelRide(RideModel ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: Text(
            'Are you sure you want to cancel this ride from ${ride.origin.name} to ${ride.destination.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final success = await _adminService.cancelRide(ride.id);
                if (!mounted) return;
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ride has been cancelled')),
                  );
                  _loadAnalytics();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to cancel ride')),
                  );
                }
              } catch (e) {
                _errorService.logError('Error cancelling ride', e);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _generateUserReport() async {
    try {
      final report = await _adminService.generateUserReport();
      if (!mounted) return;
      _showReportDialog('User Growth Report', _formatReport(report));
    } catch (e) {
      _errorService.logError('Error generating user report', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _generateRevenueReport() async {
    try {
      final report = await _adminService.generateRevenueReport();
      if (!mounted) return;
      _showReportDialog('Revenue Report', _formatReport(report));
    } catch (e) {
      _errorService.logError('Error generating revenue report', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _generateRideReport() async {
    try {
      final report = await _adminService.generateRideReport();
      if (!mounted) return;
      _showReportDialog('Ride Performance Report', _formatReport(report));
    } catch (e) {
      _errorService.logError('Error generating ride report', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _generateSystemReport() async {
    try {
      final report = await _adminService.getSystemHealth();
      if (!mounted) return;
      _showReportDialog('System Health Report', _formatReport(report));
    } catch (e) {
      _errorService.logError('Error generating system report', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _formatReport(Map<String, dynamic> report) {
    final buffer = StringBuffer();

    void addSection(String title, Map<String, dynamic> data) {
      buffer.writeln('$title:');
      data.forEach((key, value) {
        if (value is Map) {
          buffer.writeln('  $key:');
          value.forEach((subKey, subValue) {
            buffer.writeln('    $subKey: $subValue');
          });
        } else {
          buffer.writeln('  $key: $value');
        }
      });
      buffer.writeln();
    }

    report.forEach((key, value) {
      if (value is Map) {
        addSection(key.toUpperCase(), Map<String, dynamic>.from(value));
      } else {
        buffer.writeln('$key: $value');
      }
    });

    return buffer.toString();
  }

  void _showReportDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
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

  void _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      _errorService.logError('Error during logout', e);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
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

  void _showSendNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => _SendNotificationDialog(),
    );
  }
}

// Dialog Classes
class _AddUserDialog extends StatefulWidget {
  final VoidCallback onUserAdded;

  const _AddUserDialog({required this.onUserAdded});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  UserType _selectedUserType = UserType.passenger;
  bool _isLoading = false;

  // Driver-specific fields
  VehicleType? _vehicleType;
  final _vehicleNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New User or Driver'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Email is required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings,
                        color: Colors.green.shade600, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'As an admin, you can create driver accounts',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserType>(
                value: _selectedUserType,
                decoration: const InputDecoration(labelText: 'User Type'),
                items: UserType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value!;
                  });
                },
              ),
              if (_selectedUserType == UserType.driver) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<VehicleType>(
                  value: _vehicleType,
                  decoration: const InputDecoration(labelText: 'Vehicle Type'),
                  items: VehicleType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _vehicleType = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select vehicle type' : null,
                ),
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration:
                      const InputDecoration(labelText: 'Vehicle Number'),
                  validator: (value) => value?.isEmpty == true
                      ? 'Vehicle number is required'
                      : null,
                ),
                TextFormField(
                  controller: _licenseNumberController,
                  decoration:
                      const InputDecoration(labelText: 'License Number'),
                  validator: (value) => value?.isEmpty == true
                      ? 'License number is required'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addUser,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add User'),
        ),
      ],
    );
  }

  void _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'userType': _selectedUserType.name,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'isVerified': false,
        'isBanned': false,
        'status': 'active',
        'preferences': {},
        'totalRides': 0,
        'completedRides': 0,
        'isPremium': false,
      };
      if (_selectedUserType == UserType.driver) {
        userData['vehicleType'] = _vehicleType?.name ?? '';
        userData['vehicleNumber'] =
            _vehicleNumberController.text.trim().isNotEmpty
                ? _vehicleNumberController.text.trim()
                : '';
        userData['licenseNumber'] =
            _licenseNumberController.text.trim().isNotEmpty
                ? _licenseNumberController.text.trim()
                : '';
        userData['isDriver'] = true;
      }
      await firestore.collection('users').add(userData);
      widget.onUserAdded();

      // Generate a temporary password for the user
      final tempPassword = 'TempPass${DateTime.now().millisecondsSinceEpoch}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedUserType == UserType.driver
                    ? 'Driver account created successfully'
                    : 'User added successfully',
              ),
              Text(
                'Temporary password: $tempPassword',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class _BanUserDialog extends StatefulWidget {
  final VoidCallback onUserBanned;

  const _BanUserDialog({required this.onUserBanned});

  @override
  State<_BanUserDialog> createState() => _BanUserDialogState();
}

class _BanUserDialogState extends State<_BanUserDialog> {
  final _searchController = TextEditingController();
  final AdminService _adminService = AdminService();
  List<UserModel> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _adminService.getUsers(limit: 50);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ban/Unban User'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Users',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          trailing: Text(
                            user.isBanned ? 'Banned' : 'Active',
                            style: TextStyle(
                              color: user.isBanned ? Colors.red : Colors.green,
                            ),
                          ),
                          onTap: () => _toggleBan(user),
                        );
                      },
                    ),
            ),
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

  void _toggleBan(UserModel user) async {
    try {
      final success =
          await _adminService.toggleUserBan(user.id, !user.isBanned);
      if (success) {
        widget.onUserBanned();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${user.name} has been ${user.isBanned ? 'unbanned' : 'banned'}'),
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

class _GenerateReportDialog extends StatefulWidget {
  final VoidCallback onReportGenerated;

  const _GenerateReportDialog({required this.onReportGenerated});

  @override
  State<_GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<_GenerateReportDialog> {
  String _selectedReportType = 'user';
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: const Text('User Growth Report'),
            value: 'user',
            groupValue: _selectedReportType,
            onChanged: (value) {
              setState(() {
                _selectedReportType = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Revenue Report'),
            value: 'revenue',
            groupValue: _selectedReportType,
            onChanged: (value) {
              setState(() {
                _selectedReportType = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Ride Performance Report'),
            value: 'ride',
            groupValue: _selectedReportType,
            onChanged: (value) {
              setState(() {
                _selectedReportType = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('System Health Report'),
            value: 'system',
            groupValue: _selectedReportType,
            onChanged: (value) {
              setState(() {
                _selectedReportType = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isGenerating ? null : _generateReport,
          child: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }

  void _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final adminService = AdminService();
      Map<String, dynamic> report;

      switch (_selectedReportType) {
        case 'user':
          report = await adminService.generateUserReport();
          break;
        case 'revenue':
          report = await adminService.generateRevenueReport();
          break;
        case 'ride':
          report = await adminService.generateRideReport();
          break;
        case 'system':
          report = await adminService.getSystemHealth();
          break;
        default:
          report = {};
      }

      Navigator.pop(context);
      widget.onReportGenerated();

      // Show report in dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${_selectedReportType.toUpperCase()} Report'),
          content: SingleChildScrollView(
            child: Text(_formatReport(report)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _formatReport(Map<String, dynamic> report) {
    final buffer = StringBuffer();

    void addSection(String title, Map<String, dynamic> data) {
      buffer.writeln('$title:');
      data.forEach((key, value) {
        if (value is Map) {
          buffer.writeln('  $key:');
          value.forEach((subKey, subValue) {
            buffer.writeln('    $subKey: $subValue');
          });
        } else {
          buffer.writeln('  $key: $value');
        }
      });
      buffer.writeln();
    }

    report.forEach((key, value) {
      if (value is Map) {
        addSection(key.toUpperCase(), Map<String, dynamic>.from(value));
      } else {
        buffer.writeln('$key: $value');
      }
    });

    return buffer.toString();
  }
}

class _UserDetailsDialog extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onEdit;
  const _UserDetailsDialog({required this.user, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final userTypeController = ValueNotifier<UserType>(user.userType);
    return AlertDialog(
      title: Text('User Details: ${user.name}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Name', user.name),
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Phone', user.phone ?? 'Not provided'),
            Row(
              children: [
                const Text('User Type: '),
                Expanded(
                  child: ValueListenableBuilder<UserType>(
                    valueListenable: userTypeController,
                    builder: (context, value, _) => DropdownButton<UserType>(
                      value: value,
                      items: UserType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (newType) async {
                        if (newType != null && newType != user.userType) {
                          final firestore = FirebaseFirestore.instance;
                          await firestore
                              .collection('users')
                              .doc(user.id)
                              .update({
                            'userType': newType.name,
                            'updatedAt': DateTime.now(),
                          });
                          userTypeController.value = newType;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'User type updated to ${newType.name}')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildDetailRow('Status', user.isBanned ? 'Banned' : 'Active'),
                if (user.isBanned)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.block, color: Colors.red, size: 18),
                  ),
              ],
            ),
            Row(
              children: [
                _buildDetailRow('Verified', user.isVerified ? 'Yes' : 'No'),
                if (user.isVerified)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.verified, color: Colors.green, size: 18),
                  ),
              ],
            ),
            _buildDetailRow('Created', _formatDate(user.createdAt)),
            if (user.preferences.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Preferences:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...user.preferences.entries.map((entry) =>
                  _buildDetailRow(entry.key, entry.value.toString())),
            ],
          ],
        ),
      ),
      actions: [
        if (user.isDriver) ...[
          TextButton(
            onPressed: () async {
              final firestore = FirebaseFirestore.instance;
              await firestore.collection('users').doc(user.id).update({
                'isVerified': !user.isVerified,
                'updatedAt': DateTime.now(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(user.isVerified
                        ? 'Driver unverified'
                        : 'Driver verified')),
              );
            },
            child: Text(user.isVerified ? 'Unverify' : 'Verify'),
          ),
          TextButton(
            onPressed: () async {
              final firestore = FirebaseFirestore.instance;
              await firestore.collection('users').doc(user.id).update({
                'isBanned': !user.isBanned,
                'updatedAt': DateTime.now(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        user.isBanned ? 'Driver unbanned' : 'Driver banned')),
              );
            },
            child: Text(user.isBanned ? 'Unban' : 'Ban'),
          ),
        ],
        TextButton(
          onPressed: () async {
            try {
              await FirebaseAuth.instance
                  .sendPasswordResetEmail(email: user.email);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset email sent')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          },
          child: const Text('Reset Password'),
        ),
        if (onEdit != null)
          TextButton(
            onPressed: onEdit,
            child: const Text('Edit'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _RideDetailsDialog extends StatelessWidget {
  final RideModel ride;

  const _RideDetailsDialog({required this.ride});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ride Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
                'Route', '${ride.origin.name} → ${ride.destination.name}'),
            _buildDetailRow('Driver', ride.driverName),
            _buildDetailRow('Vehicle',
                '${ride.vehicleType.name}${ride.vehicleNumber != null ? ' - ${ride.vehicleNumber}' : ''}'),
            _buildDetailRow('Price', ride.formattedPrice),
            _buildDetailRow('Status', ride.status.name.toUpperCase()),
            _buildDetailRow('Departure', ride.formattedDepartureTime),
            _buildDetailRow('Available Seats', ride.availableSeats.toString()),
            _buildDetailRow('Created', _formatDate(ride.createdAt)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _SystemSettingsScreen extends StatefulWidget {
  const _SystemSettingsScreen();
  @override
  State<_SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<_SystemSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookingFeeController = TextEditingController();
  final _premiumPlanPriceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('main')
          .get();
      final data = doc.data() ?? {};
      _bookingFeeController.text = (data['bookingFee'] ?? '').toString();
      _premiumPlanPriceController.text =
          (data['premiumPlanPrice'] ?? '').toString();
    } catch (e) {}
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _bookingFeeController.dispose();
    _premiumPlanPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _bookingFeeController,
                      decoration:
                          const InputDecoration(labelText: 'Booking Fee (NGN)'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter booking fee' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _premiumPlanPriceController,
                      decoration: const InputDecoration(
                          labelText: 'Premium Plan Price (NGN)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter premium plan price'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSettings,
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance.collection('settings').doc('main').set({
        'bookingFee': double.tryParse(_bookingFeeController.text) ?? 0.0,
        'premiumPlanPrice':
            double.tryParse(_premiumPlanPriceController.text) ?? 0.0,
        'updatedAt': DateTime.now(),
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class _SendNotificationDialog extends StatefulWidget {
  @override
  State<_SendNotificationDialog> createState() =>
      _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<_SendNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _target = 'all';
  String? _singleUserId;
  bool _isSending = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Notification'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a message' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _target,
                decoration: const InputDecoration(labelText: 'Target Audience'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                  DropdownMenuItem(
                      value: 'drivers', child: Text('Drivers Only')),
                  DropdownMenuItem(
                      value: 'passengers', child: Text('Passengers Only')),
                  DropdownMenuItem(value: 'single', child: Text('Single User')),
                ],
                onChanged: (val) {
                  setState(() {
                    _target = val!;
                  });
                },
              ),
              if (_target == 'single') ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'User ID'),
                  onChanged: (val) => _singleUserId = val.trim(),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter user ID' : null,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendNotification,
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send'),
        ),
      ],
    );
  }

  void _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      final notificationService = NotificationService();
      final firestore = FirebaseFirestore.instance;
      List<String> userIds = [];
      if (_target == 'all') {
        final users = await firestore.collection('users').get();
        userIds = users.docs.map((doc) => doc.id).toList();
      } else if (_target == 'drivers') {
        final users = await firestore
            .collection('users')
            .where('userType', isEqualTo: 'driver')
            .get();
        userIds = users.docs.map((doc) => doc.id).toList();
      } else if (_target == 'passengers') {
        final users = await firestore
            .collection('users')
            .where('userType', isEqualTo: 'passenger')
            .get();
        userIds = users.docs.map((doc) => doc.id).toList();
      } else if (_target == 'single') {
        if (_singleUserId == null || _singleUserId!.isEmpty) {
          setState(() {
            _isSending = false;
            _error = 'Please enter a user ID.';
          });
          return;
        }
        userIds = [_singleUserId!];
      }
      for (final userId in userIds) {
        await notificationService.sendNotification(
          userId: userId,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent!')),
        );
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _error = 'Failed to send notification: \\${e.toString()}';
      });
    }
  }
}

class _EditDriverDialog extends StatefulWidget {
  final UserModel user;
  final VoidCallback onDriverUpdated;
  const _EditDriverDialog({required this.user, required this.onDriverUpdated});
  @override
  State<_EditDriverDialog> createState() => _EditDriverDialogState();
}

class _EditDriverDialogState extends State<_EditDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  late VehicleType _vehicleType;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _licenseNumberController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _vehicleType = VehicleType.values.firstWhere(
      (e) => e.name == (widget.user.vehicleType ?? 'bus'),
      orElse: () => VehicleType.bus,
    );
    _vehicleNumberController =
        TextEditingController(text: widget.user.vehicleNumber ?? '');
    _licenseNumberController =
        TextEditingController(text: widget.user.licenseNumber ?? '');
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Driver Details'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<VehicleType>(
                value: _vehicleType,
                decoration: const InputDecoration(labelText: 'Vehicle Type'),
                items: VehicleType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _vehicleType = value!;
                  });
                },
              ),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(labelText: 'Vehicle Number'),
                validator: (value) => value?.isEmpty == true
                    ? 'Vehicle number is required'
                    : null,
              ),
              TextFormField(
                controller: _licenseNumberController,
                decoration: const InputDecoration(labelText: 'License Number'),
                validator: (value) => value?.isEmpty == true
                    ? 'License number is required'
                    : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Phone is required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(widget.user.id).update({
        'vehicleType': _vehicleType.name,
        'vehicleNumber': _vehicleNumberController.text.trim(),
        'licenseNumber': _licenseNumberController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': DateTime.now(),
      });
      widget.onDriverUpdated();
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver details updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
