/// Admin Dashboard Screen for SafeRide
///
/// This screen provides admins with access to all their features:
/// - Manage users (activate/suspend/ban)
/// - Moderate ride content
/// - Verify premium payments
/// - View analytics and reports
/// - Send push notifications
///
/// TODO: Future Enhancements:
/// - Advanced analytics dashboard
/// - User search and filtering
/// - Bulk actions
/// - Notification scheduling
library;

import 'package:flutter/material.dart';
import '../services/role_service.dart';
import '../services/auth_service.dart'; // Added import for AuthService
import '../utils/test_user_creator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added import for FirebaseFirestore
import '../utils/firestore_migration.dart';
import 'package:saferide/services/analytics_service.dart';
import '../models/user_model.dart'; // Added import for UserType

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final RoleService _roleService = RoleService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AnalyticsService().logLogout();
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.build),
            tooltip: 'Fix User Roles',
            onPressed: _fixUserRoles,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, '/admin-notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeatureOverview(),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildAdminFeatures(),
            const SizedBox(height: 24),
            _buildUserManagementSection(),
            const SizedBox(height: 24),
            _buildDriverCreationSection(),
            const SizedBox(height: 24),
            _buildContentModerationSection(),
            const SizedBox(height: 24),
            _buildPaymentVerificationSection(),
            const SizedBox(height: 24),
            _buildAnalyticsSection(),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/admin-analytics'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.analytics),
        label: const Text('View Analytics'),
      ),
    );
  }

  Future<void> _createTestUsers() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating test users...'),
            ],
          ),
        ),
      );

      await TestUserCreator.createAllTestUsers();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Test Users Created'),
            content: const Text(
              'Test users created successfully!\n\n'
              'Admin: admin@gmail.com / admin123\n'
              'Passenger: passenger@gmail.com / passenger123\n'
              'Driver: driver@gmail.com / driver123',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create test users: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _fixUserRoles() async {
    final firestore = FirebaseFirestore.instance;
    final usersRef = firestore.collection('users');
    final users = await usersRef.get();
    int fixed = 0;
    for (final doc in users.docs) {
      final data = doc.data();
      String? userType = data['userType']?.toString().toLowerCase();
      if (userType == null ||
          !(userType == 'passenger' ||
              userType == 'driver' ||
              userType == 'admin')) {
        await doc.reference.update({'userType': 'passenger'});
        fixed++;
      } else if (userType != data['userType']) {
        await doc.reference.update({'userType': userType});
        fixed++;
      }
    }
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('User Roles Fixed'),
          content: Text('Fixed roles for $fixed users.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _fixRideDates() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Fixing ride date fields...'),
            ],
          ),
        ),
      );
      await migrateRideDateFieldsToTimestamps();
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ride Dates Fixed'),
            content: const Text(
                'All ride date fields have been fixed (converted to timestamps where needed).'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to fix ride dates: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildFeatureOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
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
                    Icons.admin_panel_settings,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Features',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage users, rides, payments, analytics, and more',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '5 Core Features Available',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
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
                Icon(Icons.flash_on, color: Colors.red.shade600),
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
                    icon: Icons.people,
                    label: 'Manage Users',
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/admin-users'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.report,
                    label: 'Moderate Content',
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/admin-content'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.verified,
                    label: 'Verify Payments',
                    color: Colors.green,
                    onTap: () =>
                        Navigator.pushNamed(context, '/admin-payments'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.notifications,
                    label: 'Send Notifications',
                    color: Colors.purple,
                    onTap: () =>
                        Navigator.pushNamed(context, '/admin-notifications'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.person_add,
                    label: 'Create Test Users',
                    color: Colors.teal,
                    onTap: _createTestUsers,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.build,
                    label: 'Fix User Roles',
                    color: Colors.amber,
                    onTap: _fixUserRoles,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.update,
                    label: 'Fix Ride Dates',
                    color: Colors.deepPurple,
                    onTap: _fixRideDates,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Container()),
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

  Widget _buildAdminFeatures() {
    final features = _roleService.getAdminFeatures();
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
                Icon(Icons.featured_play_list, color: Colors.red.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Admin Features',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              return _buildFeatureItem(index + 1, feature);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(int number, String feature) {
    final parts = feature.split(' - ');
    final emoji = parts[0];
    final title = parts.length > 1 ? parts[1] : feature;
    final description = parts.length > 2 ? parts[2] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementSection() {
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
                Icon(Icons.people, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'User Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5, // Placeholder for user count
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text('User $index'),
                    subtitle: const Text('user@email.com'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {},
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'activate', child: Text('Activate')),
                        const PopupMenuItem(
                            value: 'suspend', child: Text('Suspend')),
                        const PopupMenuItem(value: 'ban', child: Text('Ban')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentModerationSection() {
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
                Icon(Icons.report, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Content Moderation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5, // Placeholder for ride count
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text('Ride Post $index'),
                    subtitle: const Text('Route: Kigali - Musanze'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {}, // Placeholder for remove action
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentVerificationSection() {
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
                Icon(Icons.verified, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Payment Verification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3, // Placeholder for payment count
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.payment),
                    title: Text('Payment #$index'),
                    subtitle: const Text('User: user@email.com'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {}, // Approve
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {}, // Reject
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
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
                Icon(Icons.analytics, color: Colors.red.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnalyticsStat('Bookings', '1,234'),
                _buildAnalyticsStat('Active Users', '567'),
                _buildAnalyticsStat('Popular Route', 'Kigali-Musanze'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCreationSection() {
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
                Icon(Icons.drive_eta, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Driver Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateDriverDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Driver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Create new driver accounts with full access to driver features.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDriverDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final vehicleTypeController = TextEditingController();
    final vehicleNumberController = TextEditingController();
    final licenseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Driver Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter driver\'s full name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email address',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password (min 6 characters)',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: vehicleTypeController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  hintText: 'e.g., Car, Minibus, Motorcycle',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  hintText: 'Enter vehicle registration number',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: licenseController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  hintText: 'Enter driver\'s license number',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  phoneController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await AuthService().registerWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  userType: UserType.driver,
                  vehicleType: vehicleTypeController.text.trim(),
                  vehicleNumber: vehicleNumberController.text.trim(),
                  licenseNumber: licenseController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '✅ Driver account created successfully!\nEmail: ${emailController.text.trim()}\nPassword: ${passwordController.text.trim()}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Failed to create driver account: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create Driver'),
          ),
        ],
      ),
    );
  }
}
