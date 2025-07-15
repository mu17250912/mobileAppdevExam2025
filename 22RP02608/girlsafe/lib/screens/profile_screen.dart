import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPremium = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await LocalStorageService.getUserData();
    final isPremium = await LocalStorageService.isPremium();
    setState(() {
      _userData = userData;
      _isPremium = isPremium;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Badges')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // User Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData?['username'] ?? 'User',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isPremium ? Colors.amber : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isPremium ? 'Premium Member' : 'Free Member',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Navigation Options
          ListTile(
            title: const Text('My Badges'),
            leading: const Icon(Icons.emoji_events_outlined),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBadgesScreen()),
            ),
          ),
          ListTile(
            title: const Text('Settings'),
            leading: const Icon(Icons.settings_outlined),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          
          // Premium Toggle
          Card(
            child: ListTile(
              title: const Text('Premium Membership'),
              subtitle: Text(_isPremium ? 'Active' : 'Upgrade to unlock premium features'),
              leading: Icon(
                _isPremium ? Icons.star : Icons.star_border,
                color: _isPremium ? Colors.amber : Colors.grey,
              ),
              trailing: Switch(
                value: _isPremium,
                onChanged: (value) async {
                  await LocalStorageService.setPremiumStatus(value);
                  setState(() {
                    _isPremium = value;
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await LocalStorageService.logout();
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class MyBadgesScreen extends StatelessWidget {
  const MyBadgesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Badges')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No badges yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Complete activities to earn badges',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification preferences'),
            leading: const Icon(Icons.notifications),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Privacy'),
            subtitle: const Text('Privacy and security settings'),
            leading: const Icon(Icons.privacy_tip),
            onTap: () {},
          ),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('App version and information'),
            leading: const Icon(Icons.info),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact support'),
            leading: const Icon(Icons.help),
            onTap: () {},
          ),
        ],
      ),
    );
  }
} 