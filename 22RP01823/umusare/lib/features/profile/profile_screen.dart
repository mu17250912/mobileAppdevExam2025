import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/user_profile_widget.dart';
import '../../services/auth_service.dart';
import '../../widgets/main_bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF145A32),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF145A32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Profile Widget
            UserProfileWidget(
              onEditProfile: () {
                // TODO: Navigate to edit profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit profile feature coming soon!'),
                    backgroundColor: Color(0xFF145A32),
                  ),
                );
              },
              onLogout: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  final authService = AuthService();
                  await authService.signOut();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Color(0xFF145A32),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    context.go('/login');
                  }
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Account Settings Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.person,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit profile feature coming soon!'),
                          backgroundColor: Color(0xFF145A32),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.lock,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Change password feature coming soon!'),
                          backgroundColor: Color(0xFF145A32),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage your notification preferences',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications feature coming soon!'),
                          backgroundColor: Color(0xFF145A32),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    subtitle: 'Manage your privacy settings',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy settings feature coming soon!'),
                          backgroundColor: Color(0xFF145A32),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF145A32).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF145A32),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
    );
  }
} 