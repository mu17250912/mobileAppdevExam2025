import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:commissioner/screens/login_screen.dart';
import 'buyer_requests_screen.dart';
import 'commissioner_dashboard_screen.dart';
import 'notifications_screen.dart';
import 'admin_setup_screen.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService.getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              if (unreadCount > 0)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return _buildBody(context, authProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider authProvider) {
    if (authProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (authProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${authProvider.error}', style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => authProvider.loadCurrentUser(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Only show login/signup if truly logged out
    if (!authProvider.isAuthenticated) {
      return _buildLoginSection(context);
    }

    // If authenticated but user profile is missing
    if (authProvider.currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Profile not found!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your account is logged in, but your profile data could not be loaded.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => authProvider.loadCurrentUser(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show the real profile section for logged-in users
    return _buildProfileSection(context, authProvider);
  }

  Widget _buildLoginSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            'Welcome to Commissioner',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Sign in to access your profile, save favorites, and manage your property listings.',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xl),
          ElevatedButton(
            onPressed: () {
              debugPrint('Sign In button pressed');
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Sign In'),
          ),
          const SizedBox(height: AppSizes.md),
          OutlinedButton(
            onPressed: () {
              debugPrint('Create Account button pressed');
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()), // You can replace with RegisterScreen if you have one
              );
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(user),
          const SizedBox(height: AppSizes.lg),

          // Quick Stats
          _buildQuickStats(),
          const SizedBox(height: AppSizes.lg),

          // Menu Items
          _buildMenuItems(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.textInverse.withOpacity(0.2),
            child: Icon(
              Icons.person,
              size: 40,
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  user.email,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textInverse.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textInverse.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    user.userType.isNotEmpty
                        ? user.userType[0].toUpperCase() + user.userType.substring(1)
                        : '',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Navigate to edit profile
            },
            icon: Icon(
              Icons.edit,
              color: AppColors.textInverse.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.favorite,
            title: 'Favorites',
            value: '12',
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _buildStatCard(
            icon: Icons.search,
            title: 'Searches',
            value: '8',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _buildStatCard(
            icon: Icons.visibility,
            title: 'Viewed',
            value: '24',
            color: AppColors.success,
          ),
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
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            value,
            style: AppTextStyles.heading5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final menuItems = [
      // Only show commissioner dashboard for admin users
      if (authProvider.currentUser?.isCommissioner == true)
        {
          'icon': Icons.admin_panel_settings,
          'title': 'Commissioner Dashboard',
          'subtitle': 'Manage purchase requests',
          'onTap': () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CommissionerDashboardScreen()),
            );
          },
        },
      {
        'icon': Icons.receipt_long,
        'title': 'My Purchase Requests',
        'subtitle': 'View your submitted requests',
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BuyerRequestsScreen()),
          );
        },
      },
      {
        'icon': Icons.favorite,
        'title': 'My Favorites',
        'subtitle': 'View your saved properties',
        'onTap': () {},
      },
      {
        'icon': Icons.search,
        'title': 'Saved Searches',
        'subtitle': 'Manage your search criteria',
        'onTap': () {},
      },
      {
        'icon': Icons.history,
        'title': 'Viewing History',
        'subtitle': 'Recently viewed properties',
        'onTap': () {},
      },
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'subtitle': 'Manage your alerts',
        'onTap': () {},
      },
      {
        'icon': Icons.help,
        'title': 'Help & Support',
        'subtitle': 'Get help and contact support',
        'onTap': () {},
      },
      {
        'icon': Icons.info,
        'title': 'About',
        'subtitle': 'App information and version',
        'onTap': () {},
      },
    ];

    return Column(
      children: [
        ...menuItems.map((item) {
          return Card(
            margin: const EdgeInsets.only(bottom: AppSizes.sm),
            child: ListTile(
              leading: Icon(
                item['icon'] as IconData,
                color: AppColors.primary,
              ),
              title: Text(
                item['title'] as String,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                item['subtitle'] as String,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: item['onTap'] as VoidCallback,
            ),
          );
        }),
        // Logout item with context
        Card(
          margin: const EdgeInsets.only(bottom: AppSizes.sm),
          child: ListTile(
            leading: Icon(Icons.logout, color: AppColors.primary),
            title: Text('Logout', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('Sign out of your account', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 