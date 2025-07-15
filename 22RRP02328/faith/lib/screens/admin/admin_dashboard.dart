import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/subscription_provider.dart'; // Added import for SubscriptionProvider
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart'; // Added import for AuthService
import '../../services/event_service.dart'; // Added import for EventService

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  bool _showAnalytics = false;
  Map<String, dynamic>? _analyticsData;
  bool _analyticsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _insertRambertAdminUser();
  }

  Future<void> _loadData() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    await eventProvider.loadEvents();
    await userProvider.loadServiceProviders();
    await userProvider.loadAllUsers();
  }

  Future<void> _insertRambertAdminUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final users = userProvider.serviceProviders;
    final exists = users.any((u) => u.email == 'rambert@gmail.com');
    if (!exists) {
      // Insert user using AuthService
      try {
        await AuthService.createUserWithEmailAndPassword(
          'rambert@gmail.com',
          'defaultPassword123', // You may want to change this
          'Rambert',
          '07890335790',
          AppConstants.userTypeAdmin,
        );
        // Optionally reload users
        await userProvider.loadServiceProviders();
      } catch (e) {
        // Handle error (user may already exist)
      }
    }
  }

  void _showAnalyticsPage() async {
    setState(() {
      _analyticsLoading = true;
      _showAnalytics = true;
    });
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final data = await subscriptionProvider.getSubscriptionAnalytics();
    setState(() {
      _analyticsData = data;
      _analyticsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showAnalytics) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _showAnalytics = false;
              });
            },
          ),
        ),
        body: _analyticsLoading
            ? const Center(child: CircularProgressIndicator())
            : _analyticsData == null
                ? const Center(child: Text('No analytics data'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Total Subscriptions: ${_analyticsData!['totalSubscriptions'] ?? 0}'),
                      Text('Active Subscriptions: ${_analyticsData!['activeSubscriptions'] ?? 0}'),
                      Text('Premium Subscriptions: ${_analyticsData!['premiumSubscriptions'] ?? 0}'),
                      Text('Business Subscriptions: ${_analyticsData!['businessSubscriptions'] ?? 0}'),
                      Text('Total Revenue: ${_analyticsData!['totalRevenue'] ?? 0}'),
                      Text('Average Revenue Per User: ${_analyticsData!['averageRevenuePerUser'] ?? 0}'),
                    ],
                  ),
      );
    }
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildEventsTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/LOGO.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            const Text('Admin Dashboard'),
            const Spacer(),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.userData;
                return PopupMenuButton<String>(
                  icon: CircleAvatar(
                    backgroundColor: const Color(AppColors.primaryColor),
                    backgroundImage: (user?.profileImage != null && user?.profileImage!.isNotEmpty == true)
                        ? NetworkImage(user!.profileImage!)
                        : null,
                    child: (user?.profileImage == null || user?.profileImage!.isEmpty == true)
                        ? Text(
                            (user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A'),
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  onSelected: (value) {
                    if (value == 'profile') {
                      // Show profile dialog
                      _showProfileDialog(context, user);
                    } else if (value == 'settings') {
                      setState(() {
                        _currentIndex = 3;
                      });
                    } else if (value == 'logout') {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      authProvider.signOut(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'profile', child: Text('Profile')),
                    const PopupMenuItem(value: 'settings', child: Text('Settings')),
                    const PopupMenuItem(value: 'logout', child: Text('Logout')),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Get.toNamed('/notifications');
            },
          ),
        ],
      ),
      body: Consumer2<UserProvider, EventProvider>(
        builder: (context, userProvider, eventProvider, child) {
          final totalUsers = userProvider.allUsers.length;
          final totalEvents = eventProvider.events.length;
          final serviceProviders = userProvider.allUsers.where((u) => u.userType == AppConstants.userTypeServiceProvider).length;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final userName = authProvider.userData?.name ?? 'Admin';
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(AppColors.primaryColor),
                            Color(AppColors.secondaryColor),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $userName!',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your Faith platform',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.people,
                        title: 'Total Users',
                        value: totalUsers.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.event,
                        title: 'Total Events',
                        value: totalEvents.toString(),
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.work,
                        title: 'Service Providers',
                        value: serviceProviders.toString(),
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.payment,
                        title: 'Revenue',
                        value: '₣12.5M', // TODO: Replace with real revenue if available
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Quick Actions
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.person_add,
                        title: 'Add User',
                        onTap: () {
                          _showAddUserDialog(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.analytics,
                        title: 'Analytics',
                        onTap: _showAnalyticsPage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.settings,
                        title: 'Settings',
                        onTap: () {
                          setState(() {
                            _currentIndex = 3; // Settings tab
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.support_agent,
                        title: 'Support',
                        onTap: () {
                          _showSupportDialog(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Recent Activity
                Text(
                  'Recent Activity',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActivityItem(
                  icon: Icons.person_add,
                  title: 'New user registered',
                  subtitle: 'John Doe joined as Event Organizer',
                  time: '2 hours ago',
                ),
                _buildActivityItem(
                  icon: Icons.event,
                  title: 'New event created',
                  subtitle: 'Wedding ceremony planned',
                  time: '4 hours ago',
                ),
                _buildActivityItem(
                  icon: Icons.work,
                  title: 'Service provider verified',
                  subtitle: 'Photography service approved',
                  time: '6 hours ago',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to add user
            },
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userProvider.allUsers.length,
            itemBuilder: (context, index) {
              final user = userProvider.allUsers[index];
              return _buildUserCard(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildEventsTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          if (eventProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: eventProvider.events.length,
            itemBuilder: (context, index) {
              final event = eventProvider.events[index];
              return _buildEventCard(event);
            },
          );
        },
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsItem(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification settings',
            onTap: () {
              Get.toNamed('/notification-settings');
            },
          ),
          _buildSettingsItem(
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Manage security settings',
            onTap: () {
              Get.toNamed('/security-settings');
            },
          ),
          _buildSettingsItem(
            icon: Icons.backup,
            title: 'Backup & Restore',
            subtitle: 'Manage data backup',
            onTap: () {
              Get.toNamed('/backup-settings');
            },
          ),
          _buildSettingsItem(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App information and version',
            onTap: () {
              Get.toNamed('/about');
            },
          ),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.signOut(context);
            },
          ),
        ],
      ),
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
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: const Color(AppColors.primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
                            backgroundColor: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
          child: Icon(
            icon,
            color: const Color(AppColors.primaryColor),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(AppColors.primaryColor),
          child: Text(
            user.name.substring(0, 1).toUpperCase(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getUserTypeColor(user.userType),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.userType.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditUserDialog(context, user);
            } else if (value == 'delete') {
              _showDeleteUserDialog(context, user);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          event.title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              event.description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.location,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(event.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                event.status.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (event.status != 'confirmed')
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                tooltip: 'Approve Event',
                onPressed: () async {
                  await EventService.updateEventStatus(event.id, 'confirmed');
                  final eventProvider = Provider.of<EventProvider>(context, listen: false);
                  await eventProvider.loadEvents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event approved!')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(AppColors.primaryColor)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case AppConstants.userTypeAdmin:
        return Colors.red;
      case AppConstants.userTypeServiceProvider:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.bookingConfirmed:
        return const Color(AppColors.successColor);
      case AppConstants.bookingPending:
        return const Color(AppColors.warningColor);
      case AppConstants.bookingCancelled:
        return const Color(AppColors.errorColor);
      default:
        return Colors.grey;
    }
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: const Text('User creation form goes here.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support'),
        content: const Text('Support information goes here.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
  void _showEditUserDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Text('Edit user: ${user.name}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
  void _showDeleteUserDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user: ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {/* TODO: Implement delete logic */ Navigator.pop(context);}, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, UserModel? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: user == null
            ? const Text('No user data')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${user.name}'),
                  Text('Email: ${user.email}'),
                  Text('Role: ${user.userType}'),
                ],
              ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
} 