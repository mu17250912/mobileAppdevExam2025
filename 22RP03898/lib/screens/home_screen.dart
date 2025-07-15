/// Professional Home Screen for SafeRide
///
/// This is the main landing screen that provides navigation to all
/// app features and displays relevant information to users.
library;

import 'package:flutter/material.dart';
import 'package:saferide/utils/app_config.dart';
import 'package:saferide/services/auth_service.dart';
import 'package:saferide/models/user_model.dart';
import 'package:saferide/widgets/loading_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: AppConfig.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppConfig.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_taxi,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppConfig.spacingS),
          Text(
            AppConfig.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Navigate to notifications
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildRidesTab();
      case 2:
        return _buildBookingsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: AppConfig.spacingL),
          _buildQuickActions(),
          const SizedBox(height: AppConfig.spacingL),
          _buildRecentActivity(),
          const SizedBox(height: AppConfig.spacingL),
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.spacingL),
      decoration: BoxDecoration(
        gradient: AppConfig.primaryGradient,
        borderRadius: BorderRadius.circular(AppConfig.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      _currentUser?.name ?? 'User',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConfig.spacingM),
          Text(
            'Ready to travel? Find your next ride or post one for others.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConfig.spacingM),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppConfig.spacingM,
          mainAxisSpacing: AppConfig.spacingM,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              icon: Icons.search,
              title: 'Find Rides',
              subtitle: 'Browse available rides',
              color: AppConfig.primaryColor,
              onTap: () => Navigator.pushNamed(context, '/book-ride'),
            ),
            _buildActionCard(
              icon: Icons.directions_car,
              title: 'Post Ride',
              subtitle: 'Share your vehicle',
              color: AppConfig.successColor,
              onTap: () => Navigator.pushNamed(context, '/post-ride'),
            ),
            _buildActionCard(
              icon: Icons.history,
              title: 'My Bookings',
              subtitle: 'View booking history',
              color: AppConfig.infoColor,
              onTap: () => Navigator.pushNamed(context, '/booking-history'),
            ),
            _buildActionCard(
              icon: Icons.support_agent,
              title: 'Support',
              subtitle: 'Get help & contact us',
              color: AppConfig.warningColor,
              onTap: () => Navigator.pushNamed(context, '/support'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.cardRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.spacingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppConfig.spacingS),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConfig.spacingXS),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConfig.spacingM),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConfig.spacingM),
            child: Column(
              children: [
                _buildActivityItem(
                  icon: Icons.check_circle,
                  title: 'Booking Confirmed',
                  subtitle: 'Kigali → Musanze',
                  time: '2 hours ago',
                  color: AppConfig.successColor,
                ),
                const Divider(),
                _buildActivityItem(
                  icon: Icons.payment,
                  title: 'Payment Completed',
                  subtitle: 'FRW 5,000',
                  time: '1 day ago',
                  color: AppConfig.infoColor,
                ),
                const Divider(),
                _buildActivityItem(
                  icon: Icons.star,
                  title: 'Ride Rated',
                  subtitle: '5 stars - Great driver!',
                  time: '2 days ago',
                  color: AppConfig.warningColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConfig.spacingS),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppConfig.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConfig.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Rides',
                value: '24',
                icon: Icons.directions_car,
                color: AppConfig.primaryColor,
              ),
            ),
            const SizedBox(width: AppConfig.spacingM),
            Expanded(
              child: _buildStatCard(
                title: 'Total Spent',
                value: '₣125,000',
                icon: Icons.payment,
                color: AppConfig.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.spacingM),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: AppConfig.spacingS),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car,
            size: 64,
            color: AppConfig.primaryColor,
          ),
          SizedBox(height: AppConfig.spacingM),
          Text(
            'Available Rides',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConfig.spacingS),
          Text(
            'Find and book rides from other users',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_online,
            size: 64,
            color: AppConfig.primaryColor,
          ),
          SizedBox(height: AppConfig.spacingM),
          Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConfig.spacingS),
          Text(
            'View your booking history and status',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 64,
            color: AppConfig.primaryColor,
          ),
          SizedBox(height: AppConfig.spacingM),
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConfig.spacingS),
          Text(
            'Manage your account and preferences',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: AppConfig.primaryColor,
      unselectedItemColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car),
          label: 'Rides',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_online),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // Quick action - post a ride
        Navigator.pushNamed(context, '/post-ride');
      },
      backgroundColor: AppConfig.primaryColor,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }
}
