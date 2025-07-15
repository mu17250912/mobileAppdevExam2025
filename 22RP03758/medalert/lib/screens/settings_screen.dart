import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final ThemeService _themeService = ThemeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
              Color(0xFF90CAF9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.settings,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Settings & Preferences',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customize your MedAlert experience',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildSettingsContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          _buildProfileSection(),
          
          const SizedBox(height: 20),
          
          // General Settings
          _buildGeneralSettings(),
          
          const SizedBox(height: 20),
          
          // Notification Settings
          _buildNotificationSettings(),
          
          const SizedBox(height: 20),
          
          // Role-based Settings
          if (_settingsService.userRole == 'caregiver')
            _buildCaregiverSettings(),
          
          const SizedBox(height: 20),
          
          // Accessibility Settings
          _buildAccessibilitySettings(),
          
          const SizedBox(height: 20),
          
          // Data & Privacy
          _buildDataPrivacySettings(),
          
          const SizedBox(height: 20),
          
          // About & Support
          _buildAboutSupportSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _editProfile(),
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue,
                child: Text(
                  _settingsService.displayName.isNotEmpty 
                      ? _settingsService.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _settingsService.displayName.isNotEmpty 
                          ? _settingsService.displayName
                          : 'User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _settingsService.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _settingsService.userRole == 'caregiver' 
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _settingsService.userRole == 'caregiver' ? 'Caregiver' : 'Patient',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _settingsService.userRole == 'caregiver' 
                              ? Colors.orange
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'General',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Language Setting
          _buildSettingTile(
            'Language',
            _getLanguageName(_settingsService.language),
            Icons.language,
            () => _showLanguageDialog(),
          ),
          
          const Divider(),
          
          // Theme Setting
          _buildSettingTile(
            'Theme',
            _getThemeName(_settingsService.theme),
            Icons.palette,
            () => _showThemeDialog(),
          ),
          
          const Divider(),
          
          // Reminder Advance
          _buildSettingTile(
            'Reminder Advance',
            '${_settingsService.reminderAdvanceMinutes} minutes',
            Icons.schedule,
            () => _showReminderAdvanceDialog(),
          ),
          
          const Divider(),
          
          // Auto Sync
          _buildSwitchTile(
            'Auto Sync',
            'Automatically sync data when online',
            Icons.sync,
            _settingsService.autoSyncEnabled,
            (value) => _settingsService.setAutoSyncEnabled(value),
          ),
          
          const Divider(),
          
          // Offline Mode
          _buildSwitchTile(
            'Offline Mode',
            'Work without internet connection',
            Icons.offline_bolt,
            _settingsService.offlineModeEnabled,
            (value) => _settingsService.setOfflineModeEnabled(value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Notifications Enabled
          _buildSwitchTile(
            'Enable Notifications',
            'Receive medication reminders',
            Icons.notifications_active,
            _settingsService.notificationsEnabled,
            (value) => _settingsService.setNotificationsEnabled(value),
          ),
          
          const Divider(),
          
          // Voice Reminders
          _buildSwitchTile(
            'Voice Reminders',
            'Speak medication instructions',
            Icons.record_voice_over,
            _settingsService.voiceRemindersEnabled,
            (value) => _settingsService.setVoiceRemindersEnabled(value),
          ),
          
          const Divider(),
          
          // Sound
          _buildSwitchTile(
            'Sound',
            'Play notification sounds',
            Icons.volume_up,
            _settingsService.soundEnabled,
            (value) => _settingsService.setSoundEnabled(value),
          ),
          
          const Divider(),
          
          // Vibration
          _buildSwitchTile(
            'Vibration',
            'Vibrate on notifications',
            Icons.vibration,
            _settingsService.vibrationEnabled,
            (value) => _settingsService.setVibrationEnabled(value),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services, color: Colors.orange),
              const SizedBox(width: 12),
              const Text(
                'Caregiver Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Patient Alerts
          _buildSwitchTile(
            'Patient Alerts',
            'Receive alerts for missed medications',
            Icons.warning,
            _settingsService.patientAlertsEnabled,
            (value) => _settingsService.setPatientAlertsEnabled(value),
          ),
          
          const Divider(),
          
          // Emergency Contact Notifications
          _buildSwitchTile(
            'Emergency Notifications',
            'Get notified of emergency contacts',
            Icons.emergency,
            _settingsService.emergencyContactNotifications,
            (value) => _settingsService.setEmergencyContactNotifications(value),
          ),
          
          const Divider(),
          
          // Weekly Reports
          _buildSwitchTile(
            'Weekly Reports',
            'Receive weekly adherence reports',
            Icons.assessment,
            _settingsService.weeklyReportsEnabled,
            (value) => _settingsService.setWeeklyReportsEnabled(value),
          ),
          
          const Divider(),
          
          // Monthly Reports
          _buildSwitchTile(
            'Monthly Reports',
            'Receive monthly adherence reports',
            Icons.calendar_month,
            _settingsService.monthlyReportsEnabled,
            (value) => _settingsService.setMonthlyReportsEnabled(value),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.accessibility, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Accessibility',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Dark Mode
          _buildSettingTile(
            'Dark Mode',
            _themeService.isDarkMode ? 'Enabled' : 'Disabled',
            Icons.dark_mode,
            () => _toggleDarkMode(),
          ),
          
          const Divider(),
          
          // High Contrast
          _buildSettingTile(
            'High Contrast',
            _themeService.isHighContrast ? 'Enabled' : 'Disabled',
            Icons.contrast,
            () => _toggleHighContrast(),
          ),
          
          const Divider(),
          
          // Large Text
          _buildSettingTile(
            'Large Text',
            _themeService.isLargeText ? 'Enabled' : 'Disabled',
            Icons.text_fields,
            () => _toggleLargeText(),
          ),
          
          const Divider(),
          
          // Voice Enabled
          _buildSwitchTile(
            'Voice Enabled',
            'Enable voice assistance',
            Icons.record_voice_over,
            _themeService.isVoiceEnabled,
            (value) => _themeService.setVoiceEnabled(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPrivacySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Data & Privacy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Export Data
          _buildSettingTile(
            'Export Data',
            'Download your data',
            Icons.download,
            () => _exportData(),
          ),
          
          const Divider(),
          
          // Reset Settings
          _buildSettingTile(
            'Reset Settings',
            'Restore default settings',
            Icons.restore,
            () => _resetSettings(),
          ),
          
          const Divider(),
          
          // Privacy Policy
          _buildSettingTile(
            'Privacy Policy',
            'View privacy information',
            Icons.privacy_tip,
            () => _viewPrivacyPolicy(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSupportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'About & Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // App Version
          _buildSettingTile(
            'App Version',
            '1.0.0',
            Icons.info_outline,
            null,
          ),
          
          const Divider(),
          
          // Help & Support
          _buildSettingTile(
            'Help & Support',
            'Get help and contact support',
            Icons.help,
            () => _showHelpSupport(),
          ),
          
          const Divider(),
          
          // Rate App
          _buildSettingTile(
            'Rate App',
            'Rate us on the app store',
            Icons.star,
            () => _rateApp(),
          ),
          
          const Divider(),
          
          // Logout
          _buildSettingTile(
            'Logout',
            'Sign out of your account',
            Icons.logout,
            () => _logout(),
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, VoidCallback? onTap, {Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey.shade600),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textColor?.withValues(alpha: 0.7) ?? Colors.grey.shade600,
        ),
      ),
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  String _getLanguageName(String code) {
    final languages = _settingsService.getAvailableLanguages();
    final language = languages.firstWhere((lang) => lang['code'] == code);
    return language['name'] ?? 'English';
  }

  String _getThemeName(String code) {
    final themes = _settingsService.getAvailableThemes();
    final theme = themes.firstWhere((theme) => theme['code'] == code);
    return theme['name'] ?? 'System Default';
  }

  // Dialog methods
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _settingsService.getAvailableLanguages().map((language) {
            return ListTile(
              title: Text(language['name']!),
              trailing: _settingsService.language == language['code']
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                _settingsService.setLanguage(language['code']!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _settingsService.getAvailableThemes().map((theme) {
            return ListTile(
              title: Text(theme['name']!),
              trailing: _settingsService.theme == theme['code']
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                _settingsService.setTheme(theme['code']!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showReminderAdvanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder Advance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _settingsService.getReminderAdvanceOptions().map((option) {
            return ListTile(
              title: Text(option['label']),
              trailing: _settingsService.reminderAdvanceMinutes == option['minutes']
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                _settingsService.setReminderAdvanceMinutes(option['minutes']);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // Action methods
  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileEditScreen(),
      ),
    );
  }

  void _toggleDarkMode() {
    _themeService.toggleDarkMode();
  }

  void _toggleHighContrast() {
    _themeService.toggleHighContrast();
  }

  void _toggleLargeText() {
    _themeService.toggleLargeText();
  }

  void _exportData() {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export feature coming soon!')),
    );
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _settingsService.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _viewPrivacyPolicy() {
    // TODO: Implement privacy policy view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy feature coming soon!')),
    );
  }

  void _showHelpSupport() {
    // TODO: Implement help and support
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help and support feature coming soon!')),
    );
  }

  void _rateApp() {
    // TODO: Implement app rating
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App rating feature coming soon!')),
    );
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
} 