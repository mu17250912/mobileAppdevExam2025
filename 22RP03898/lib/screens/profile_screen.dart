/// Professional Profile Screen for SafeRide
///
/// This screen provides comprehensive user profile management with
/// modern UI design, settings, and account management features.
library;

import 'package:flutter/material.dart';
import 'package:saferide/utils/app_config.dart';
import 'package:saferide/services/auth_service.dart';
import 'package:saferide/models/user_model.dart';
import 'package:saferide/widgets/loading_overlay.dart';
import 'package:saferide/widgets/error_message.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

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
          _errorMessage = 'Failed to load profile data';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: AppConfig.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text('Profile'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                // TODO: Navigate to edit profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile coming soon!')),
                );
              },
            ),
          ],
        ),
        body: _currentUser == null
            ? _buildErrorState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppConfig.spacingM),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: AppConfig.spacingL),
                    _buildProfileStats(),
                    const SizedBox(height: AppConfig.spacingL),
                    _buildProfileActions(),
                    const SizedBox(height: AppConfig.spacingL),
                    _buildSettingsSection(),
                    const SizedBox(height: AppConfig.spacingL),
                    _buildSupportSection(),
                    const SizedBox(height: AppConfig.spacingL),
                    _buildLogoutButton(),
                    const SizedBox(height: AppConfig.spacingXXL),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppConfig.errorColor,
          ),
          const SizedBox(height: AppConfig.spacingM),
          Text(
            'Failed to load profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConfig.spacingS),
          if (_errorMessage != null) ...[
            ErrorMessage(error: _errorMessage!),
            const SizedBox(height: AppConfig.spacingM),
          ],
          ElevatedButton(
            onPressed: _loadUserData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.spacingL),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 50,
                color: AppConfig.primaryColor,
              ),
            ),

            const SizedBox(height: AppConfig.spacingM),

            // User Name
            Text(
              _currentUser?.name ?? 'User',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: AppConfig.spacingS),

            // User Type Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConfig.spacingM,
                vertical: AppConfig.spacingS,
              ),
              decoration: BoxDecoration(
                color: _getUserTypeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getUserTypeColor(),
                  width: 1,
                ),
              ),
              child: Text(
                _getUserTypeLabel(),
                style: TextStyle(
                  color: _getUserTypeColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: AppConfig.spacingM),

            // Contact Info
            _buildContactInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: _currentUser?.email ?? 'N/A',
        ),
        const SizedBox(height: AppConfig.spacingS),
        _buildInfoRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: _currentUser?.phone ?? 'N/A',
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: AppConfig.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStats() {
    return Row(
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
            title: 'Rating',
            value: '4.8',
            icon: Icons.star,
            color: AppConfig.warningColor,
          ),
        ),
        const SizedBox(width: AppConfig.spacingM),
        Expanded(
          child: _buildStatCard(
            title: 'Member Since',
            value: '2024',
            icon: Icons.calendar_today,
            color: AppConfig.infoColor,
          ),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileActions() {
    return Card(
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () {
              // TODO: Navigate to edit profile
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile coming soon!')),
              );
            },
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.verified_user_outlined,
            title: 'Verify Account',
            subtitle: 'Complete account verification',
            onTap: () {
              // TODO: Navigate to verification
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Account verification coming soon!')),
              );
            },
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.history,
            title: 'Ride History',
            subtitle: 'View your past rides',
            onTap: () => Navigator.pushNamed(context, '/booking-history'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConfig.spacingM),
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          _buildActionTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              // TODO: Navigate to notifications settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notification settings coming soon!')),
              );
            },
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Manage privacy settings',
            onTap: () {
              // TODO: Navigate to privacy settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings coming soon!')),
              );
            },
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'Change app language',
            onTap: () {
              // TODO: Navigate to language settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConfig.spacingM),
            child: Text(
              'Support',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          _buildActionTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Get help and support',
            onTap: () => Navigator.pushNamed(context, '/support'),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts with us',
            onTap: () {
              // TODO: Navigate to feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback feature coming soon!')),
              );
            },
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppConfig.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppConfig.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _handleLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConfig.errorColor,
          side: BorderSide(color: AppConfig.errorColor),
          padding: const EdgeInsets.symmetric(vertical: AppConfig.spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.cardRadius),
          ),
        ),
        child: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getUserTypeColor() {
    switch (_currentUser?.userType) {
      case UserType.passenger:
        return AppConfig.primaryColor;
      case UserType.driver:
        return AppConfig.successColor;
      case UserType.admin:
        return AppConfig.warningColor;
      default:
        return AppConfig.primaryColor;
    }
  }

  String _getUserTypeLabel() {
    switch (_currentUser?.userType) {
      case UserType.passenger:
        return 'Passenger';
      case UserType.driver:
        return 'Driver';
      case UserType.admin:
        return 'Administrator';
      default:
        return 'User';
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppConfig.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: ${AppConfig.appVersion}'),
            const SizedBox(height: AppConfig.spacingS),
            Text('${AppConfig.appDescription}'),
            const SizedBox(height: AppConfig.spacingM),
            Text('© 2024 ${AppConfig.companyName}'),
            const SizedBox(height: AppConfig.spacingS),
            Text('All rights reserved'),
          ],
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
}
