import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard/dashboard_screen.dart';
import '../jobs/job_list_screen.dart';
import '../messaging/messaging_screen.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _loading = true;
  String _selectedLanguage = 'English';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadAppVersion();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'English';
      _loading = false;
    });
  }

  Future<void> _setNotificationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> _setLanguagePref(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
  }

  void _openPrivacyPolicy() async {
    const url = 'https://your-privacy-policy-url.com';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Privacy Policy.', style: GoogleFonts.poppins())),
      );
    }
  }

  void _openTerms() async {
    const url = 'https://your-terms-url.com';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Terms of Service.', style: GoogleFonts.poppins())),
      );
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Out', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.poppins())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Log Out', style: GoogleFonts.poppins())),
        ],
      ),
    );
    if (confirm == true) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setRole(null);
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    }
  }

  void _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to clear all app data? This cannot be undone.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.poppins())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Clear', style: GoogleFonts.poppins())),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).clearAppliedJobs();
        Provider.of<UserProvider>(context, listen: false).clearSavedJobs();
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = info.version;
      });
    } catch (_) {
      setState(() {
        _appVersion = 'Unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.settings, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Settings',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Account', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.person, color: colorScheme.primary),
                    ),
                    title: Text('User Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    subtitle: Text(userProvider.role ?? 'Not logged in', style: GoogleFonts.poppins()),
                    trailing: Icon(Icons.edit, color: colorScheme.primary),
                    onTap: () {}, // Could open edit profile
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Preferences', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: SwitchListTile(
                    secondary: Icon(Icons.notifications, color: colorScheme.primary),
                    title: Text('Enable Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _setNotificationPref(value);
                    },
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.language, color: colorScheme.primary),
                    title: Text('Language', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      items: [
                        DropdownMenuItem(value: 'English', child: Text('English', style: GoogleFonts.poppins())),
                        DropdownMenuItem(value: 'Swahili', child: Text('Swahili', style: GoogleFonts.poppins())),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedLanguage = value!);
                        _setLanguagePref(value!);
                      },
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.color_lens, color: colorScheme.primary),
                    title: Text('Theme', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      themeProvider.themeMode == ThemeMode.system
                          ? 'System'
                          : themeProvider.themeMode == ThemeMode.dark
                              ? 'Dark'
                              : 'Light',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      items: [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('System', style: GoogleFonts.poppins())),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light', style: GoogleFonts.poppins())),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark', style: GoogleFonts.poppins())),
                      ],
                      onChanged: (mode) {
                        if (mode != null) themeProvider.setDarkMode(mode == ThemeMode.dark);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Legal', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.privacy_tip, color: colorScheme.primary),
                    title: Text('Privacy Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.primary),
                    onTap: _openPrivacyPolicy,
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.description, color: colorScheme.primary),
                    title: Text('Terms of Service', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.primary),
                    onTap: _openTerms,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: Text('Log Out', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _logout,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: Text('Clear All Data', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _clearAllData,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text('App Version: $_appVersion', style: GoogleFonts.poppins(color: colorScheme.onSurface.withOpacity(0.5))),
                ),
                const SizedBox(height: 24),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const JobListScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessagingScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.work), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        height: 68,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: const Color(0xFF1976D2),
      ),
    );
  }
} 