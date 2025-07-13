import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'analytics_screen.dart';
import 'user_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    // Home (Dashboard)
    _DashboardHome(),
    // Analytics
    AnalyticsScreen(),
    // Users
    UserManagementScreen(),
    // Settings
    _AdminSettingsPlaceholder(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0
            ? 'Admin Dashboard'
            : _selectedIndex == 1
                ? 'Analytics'
                : _selectedIndex == 2
                    ? 'User Management'
                    : 'Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xFFBFD4F2),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.black,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.route),
          title: const Text('Manage Routes'),
          onTap: () {
            Navigator.pushNamed(context, '/admin/manage_routes');
          },
        ),
        ListTile(
          leading: const Icon(Icons.directions_bus),
          title: const Text('Manage Buses'),
          onTap: () {
            Navigator.pushNamed(context, '/admin/manage_buses');
          },
        ),
        ListTile(
          leading: const Icon(Icons.book_online),
          title: const Text('All Bookings'),
          onTap: () {
            Navigator.pushNamed(context, '/admin/all_bookings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.analytics),
          title: const Text('Analytics'),
          onTap: () {
            Navigator.pushNamed(context, '/admin/analytics');
          },
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('User Management'),
          onTap: () {
            Navigator.pushNamed(context, '/admin/user_management');
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          onTap: () {
            Navigator.pushNamed(context, '/admin/notifications');
          },
        ),
      ],
    );
  }
}

class _AdminSettingsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.lock_reset),
          title: Text('Change Password'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AdminPasswordResetScreen()),
            );
          },
        ),
      ],
    );
  }
}

class AdminPasswordResetScreen extends StatefulWidget {
  @override
  _AdminPasswordResetScreenState createState() => _AdminPasswordResetScreenState();
}

class _AdminPasswordResetScreenState extends State<AdminPasswordResetScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _message;
  bool _loading = false;

  Future<void> _changePassword() async {
    setState(() { _loading = true; _message = null; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _message = 'No user logged in.'; _loading = false; });
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() { _message = 'New passwords do not match.'; _loading = false; });
      return;
    }
    try {
      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);
      // Update password
      await user.updatePassword(_newPasswordController.text.trim());
      setState(() {
        _message = 'Password updated successfully!';
      });
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      setState(() { _message = 'Error: ${e.message}'; });
    } catch (e) {
      setState(() { _message = 'Error: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _currentPasswordController,
              decoration: InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            if (_loading) CircularProgressIndicator(),
            if (!_loading)
              ElevatedButton(
                onPressed: _changePassword,
                child: Text('Change Password'),
              ),
            if (_message != null) ...[
              SizedBox(height: 16),
              Text(_message!, style: TextStyle(color: _message!.startsWith('Error') ? Colors.red : Colors.green)),
            ]
          ],
        ),
      ),
    );
  }
} 