import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification Preferences'),
            subtitle: const Text('Manage push and email notifications'),
            onTap: () {
              // TODO: Notification preferences
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Support'),
            subtitle: const Text('Contact support or get help'),
            onTap: () {
              // TODO: Support
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('App version, terms, privacy'),
            onTap: () {
              // TODO: About
            },
          ),
        ],
      ),
    );
  }
} 