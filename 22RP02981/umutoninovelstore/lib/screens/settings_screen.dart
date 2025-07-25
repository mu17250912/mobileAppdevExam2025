import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/firebase_service.dart';
import '../services/data_export_service.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final DataExportService _dataExportService = DataExportService();
  bool isPremiumUser = false;
  bool notificationsEnabled = true;
  String selectedLanguage = 'English';
  bool autoPlayEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPremiumUser = prefs.getBool('isPremiumUser') ?? false;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
      autoPlayEnabled = prefs.getBool('autoPlayEnabled') ?? false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _togglePremium() async {
    setState(() {
      isPremiumUser = !isPremiumUser;
    });
    await _saveSetting('isPremiumUser', isPremiumUser);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPremiumUser ? 'Premium activated!' : 'Premium deactivated'),
        backgroundColor: isPremiumUser ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _toggleNotifications() async {
    setState(() {
      notificationsEnabled = !notificationsEnabled;
    });
    await _saveSetting('notificationsEnabled', notificationsEnabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notificationsEnabled ? 'Notifications enabled' : 'Notifications disabled'),
      ),
    );
  }

  Future<void> _toggleDarkMode() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.toggleTheme();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(themeProvider.isDarkMode ? 'Dark mode enabled' : 'Dark mode disabled'),
      ),
    );
  }

  Future<void> _toggleAutoPlay() async {
    setState(() {
      autoPlayEnabled = !autoPlayEnabled;
    });
    await _saveSetting('autoPlayEnabled', autoPlayEnabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(autoPlayEnabled ? 'Auto-play enabled' : 'Auto-play disabled'),
      ),
    );
  }

  Future<void> _changeLanguage(String language) async {
    setState(() {
      selectedLanguage = language;
    });
    await _saveSetting('selectedLanguage', language);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language changed to $language')),
    );
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the app cache? This will free up storage space.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Simulate cache clearing
              await Future.delayed(const Duration(seconds: 1));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exporting your data...')),
      );
      
      final filePath = await _dataExportService.exportUserData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported successfully to: ${filePath.split('/').last}'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _showExportPreview(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showExportPreview() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final preview = await _dataExportService.getExportPreview(user.uid);
      final data = jsonDecode(preview);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Preview'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Profile: ${data['profile']?['displayName'] ?? 'N/A'}'),
                  Text('Email: ${data['profile']?['email'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Favorites: ${data['summary']['favoritesCount']}'),
                  Text('Notifications: ${data['summary']['notificationsCount']}'),
                  Text('Orders: ${data['summary']['ordersCount']}'),
                  const SizedBox(height: 8),
                  Text('Export Date: ${data['exportDate']}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to show preview: $e')),
      );
    }
  }

  Future<void> _showAboutDialog() async {
    showAboutDialog(
      context: context,
      applicationName: 'UMUTONI NOVELS STORE',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.book, size: 50),
      children: [
        const Text('A Flutter app for the UMUTONI NOVELS STORE assessment project.'),
        const SizedBox(height: 16),
        const Text('Developer: umutoni claudine'),
        const Text('Contact: umutonicocose@gmail.com'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8), // Soft green background
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingTile(
            icon: Icons.person,
            title: 'Premium Status',
            subtitle: isPremiumUser ? 'Active' : 'Inactive',
            trailing: Switch(
              value: isPremiumUser,
              onChanged: (value) => _togglePremium(),
            ),
            color: isPremiumUser ? Colors.amber : Colors.grey,
          ),
          
          const SizedBox(height: 16),
          
          // Preferences Section
          _buildSectionHeader('Preferences'),
          _buildSettingTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: notificationsEnabled ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (value) => _toggleNotifications(),
            ),
            color: Colors.blue,
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildSettingTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => _toggleDarkMode(),
                ),
                color: Colors.purple,
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: selectedLanguage,
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showLanguageDialog(),
            color: Colors.green,
          ),
          _buildSettingTile(
            icon: Icons.play_circle,
            title: 'Auto-play',
            subtitle: autoPlayEnabled ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: autoPlayEnabled,
              onChanged: (value) => _toggleAutoPlay(),
            ),
            color: Colors.orange,
          ),
          
          const SizedBox(height: 16),
          
          // Data & Storage Section
          _buildSectionHeader('Data & Storage'),
          _buildSettingTile(
            icon: Icons.cleaning_services,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _clearCache,
            color: Colors.red,
          ),
          _buildSettingTile(
            icon: Icons.download,
            title: 'Export Data',
            subtitle: 'Download your data',
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _exportData,
            color: Colors.teal,
          ),
          
          const SizedBox(height: 16),
          
          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help with the app',
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon!')),
              );
            },
            color: Colors.blue,
          ),
          _buildSettingTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App information',
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _showAboutDialog,
            color: Colors.grey,
          ),
          
          const SizedBox(height: 16),
          
          // Logout Section
          _buildSectionHeader('Account'),
          _buildSettingTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showLogoutDialog(),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color ?? Colors.grey,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'English',
            'French',
            'Spanish',
            'German',
            'Chinese',
          ].map((language) => ListTile(
            title: Text(language),
            trailing: selectedLanguage == language ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(context);
              _changeLanguage(language);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
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
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 