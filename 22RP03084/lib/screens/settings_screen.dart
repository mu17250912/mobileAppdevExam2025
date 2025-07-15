import 'package:flutter/material.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: kGoldenBrown,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            color: Colors.amber[50],
            margin: const EdgeInsets.only(bottom: 18),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Settings Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 8),
                  Text('• Enable Notifications: Turn app notifications on or off.'),
                  Text('• Dark Mode: Switch between light and dark theme.'),
                  Text('• Account Management: Manage your account (coming soon).'),
                ],
              ),
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Enable Notifications'),
              value: _notifications,
              onChanged: (val) => setState(() => _notifications = val),
              secondary: const Icon(Icons.notifications),
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              value: _darkMode,
              onChanged: (val) => setState(() => _darkMode = val),
              secondary: const Icon(Icons.dark_mode),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Account Management'),
              subtitle: const Text('Coming soon...'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
} 