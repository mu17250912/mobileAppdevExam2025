import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkTheme = false;
  bool notificationsEnabled = true;
  String language = 'English';

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signOut();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully logged out'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Student';
          final userEmail = user?.email ?? 'No email';
          
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: [
                // Profile Section
                Text('Profile', style: AppTextStyles.subheading),
                const SizedBox(height: 8),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: AppTextStyles.heading.copyWith(
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    userEmail,
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Consumer<PremiumProvider>(
                                    builder: (context, premiumProvider, child) {
                                      if (premiumProvider.isPremium) {
                                        return Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.amber[600],
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Premium User',
                                              style: AppTextStyles.body.copyWith(
                                                color: Colors.amber[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Preferences Section
                Text('Preferences', style: AppTextStyles.subheading),
                const SizedBox(height: 8),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('Dark Theme', style: AppTextStyles.body),
                        subtitle: Text(
                          'Switch to dark mode',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        value: isDarkTheme,
                        onChanged: (val) {
                          setState(() => isDarkTheme = val);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text('Language', style: AppTextStyles.body),
                        subtitle: Text(
                          'Choose your preferred language',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: language,
                          items: const [
                            DropdownMenuItem(value: 'English', child: Text('English')),
                            DropdownMenuItem(value: 'French', child: Text('French')),
                            DropdownMenuItem(value: 'Kinyarwanda', child: Text('Kinyarwanda')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => language = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Notification Settings Section
                Text('Notification Settings', style: AppTextStyles.subheading),
                const SizedBox(height: 8),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: Text('Enable Notifications', style: AppTextStyles.body),
                    subtitle: Text(
                      'Receive reminders for tasks and goals',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    value: notificationsEnabled,
                    onChanged: (val) {
                      setState(() => notificationsEnabled = val);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Account Actions Section
                Text('Account', style: AppTextStyles.subheading),
                const SizedBox(height: 8),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.security, color: Colors.blue),
                        title: Text('Privacy Policy', style: AppTextStyles.body),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Navigate to privacy policy
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Privacy Policy coming soon')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help, color: Colors.green),
                        title: Text('Help & Support', style: AppTextStyles.body),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Navigate to help screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help & Support coming soon')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info, color: Colors.orange),
                        title: Text('About', style: AppTextStyles.body),
                        subtitle: Text(
                          'StudyMate v1.0.0',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Navigate to about screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('About StudyMate coming soon')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'Logout',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Sign out of your account',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    onTap: authProvider.isLoading ? null : _logout,
                    trailing: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
} 