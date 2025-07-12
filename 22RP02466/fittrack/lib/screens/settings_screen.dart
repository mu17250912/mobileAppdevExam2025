import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/bmi_firebase_service.dart';
import '../services/profile_service.dart';
import '../services/fitness_tracker_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';
import 'dashboard_screen.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'recommendations_screen.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _bmiRemindersEnabled = true;
  bool _healthTipsEnabled = true;
  bool _healthAlertsEnabled = true;
  bool _isExporting = false;
  bool _fitnessTrackerConnected = false;
  String _connectedDevice = '';

  final FitnessTrackerService _fitnessService = FitnessTrackerService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _loadFitnessTrackerStatus();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }



  Future<void> _loadNotificationSettings() async {
    // Load saved notification preferences
    // For now, we'll use default values
    setState(() {
      _bmiRemindersEnabled = true;
      _healthTipsEnabled = true;
      _healthAlertsEnabled = true;
    });
  }

  Future<void> _loadFitnessTrackerStatus() async {
    setState(() {
      _fitnessTrackerConnected = _fitnessService.isConnected;
      _connectedDevice = _fitnessService.connectedDevice;
    });
  }



  Future<void> _toggleBMIReminders(bool value) async {
    setState(() {
      _bmiRemindersEnabled = value;
    });

    if (value) {
      await NotificationService.scheduleBMIReminder();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BMI reminders enabled'), backgroundColor: Colors.green),
      );
    } else {
      await NotificationService.cancelNotification(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BMI reminders disabled'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _toggleHealthTips(bool value) async {
    setState(() {
      _healthTipsEnabled = value;
    });

    if (value) {
      await NotificationService.scheduleHealthTip();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health tips enabled'), backgroundColor: Colors.green),
      );
    } else {
      await NotificationService.cancelNotification(2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health tips disabled'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _toggleHealthAlerts(bool value) async {
    setState(() {
      _healthAlertsEnabled = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Health alerts enabled' : 'Health alerts disabled'),
        backgroundColor: value ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _testNotification() async {
    await NotificationService.showTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notification sent!'), backgroundColor: Colors.blue),
    );
  }

  Future<void> _connectFitnessTracker() async {
    final devices = await _fitnessService.getAvailableDevices();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Fitness Tracker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: devices.map((device) => ListTile(
            title: Text(device),
            trailing: const Icon(Icons.bluetooth),
            onTap: () async {
              Navigator.of(context).pop();
              final success = await _fitnessService.connectToDevice(device);
              if (success) {
                setState(() {
                  _fitnessTrackerConnected = true;
                  _connectedDevice = device;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Connected to $device'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to connect'), backgroundColor: Colors.red),
                );
              }
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectFitnessTracker() async {
    await _fitnessService.disconnect();
    setState(() {
      _fitnessTrackerConnected = false;
      _connectedDevice = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitness tracker disconnected'), backgroundColor: Colors.orange),
    );
  }

  Future<void> _logout() async {
    // Clear user data
    LoginScreen.loggedInEmail = null;
    LoginScreen.loggedInUserId = null;
    
    // Cancel all notifications
    await NotificationService.cancelAllNotifications();
    
    // Disconnect fitness tracker
    await _fitnessService.disconnect();
    
    // Navigate to login screen
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }





  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await _firestore.collection('feedback').add({
        'userId': LoginScreen.loggedInUserId,
        'userEmail': LoginScreen.loggedInEmail,
        'feedback': _feedbackController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0',
      });

      _feedbackController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Help us improve FitTrack! Share your thoughts, suggestions, or report issues.'),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                hintText: 'Your feedback...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submitFeedback,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting account...'),
            ],
          ),
        ),
      );

      final userId = LoginScreen.loggedInUserId;
      if (userId != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(userId).delete();
        await _firestore.collection('bmi_entries').doc(userId).delete();
        
        // Delete user authentication
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
        }
      }

      // Clear local data
      await _profileService.clearProfile();
      await _profileService.saveProfilePhotoPath(null);
      
      // Clear login state
      LoginScreen.loggedInEmail = null;
      LoginScreen.loggedInUserId = null;

      // Close loading dialog
      Navigator.pop(context);

      // Show success message and navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.indigo[400],
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [

          
                      Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔔 Notifications',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('BMI Check Reminders'),
                      subtitle: const Text('Daily reminders to check your BMI'),
                      value: _bmiRemindersEnabled,
                      onChanged: _toggleBMIReminders,
                      activeColor: Colors.indigo[400],
                    ),
                    SwitchListTile(
                      title: const Text('Daily Health Tips'),
                      subtitle: const Text('Receive daily health and wellness tips'),
                      value: _healthTipsEnabled,
                      onChanged: _toggleHealthTips,
                      activeColor: Colors.indigo[400],
                    ),
                    SwitchListTile(
                      title: const Text('Health Alerts'),
                      subtitle: const Text('Alerts for significant BMI changes'),
                      value: _healthAlertsEnabled,
                      onChanged: _toggleHealthAlerts,
                      activeColor: Colors.indigo[400],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _testNotification,
                      icon: const Icon(Icons.notifications),
                      label: const Text('Test Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[200],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Feedback & Support Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💬 Feedback & Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.feedback, color: Colors.indigo),
                    title: const Text('Send Feedback'),
                    subtitle: const Text('Help us improve FitTrack'),
                    onTap: _showFeedbackDialog,
                    trailing: const Icon(Icons.arrow_forward_ios),
                  ),
                  ListTile(
                    leading: const Icon(Icons.share, color: Colors.indigo),
                    title: const Text('Share App'),
                    subtitle: const Text('Share FitTrack with friends'),
                    onTap: () {
                      Share.share(
                        'Check out FitTrack BMI - Your personal health companion for BMI tracking and wellness guidance! Download now: https://play.google.com/store/apps/details?id=com.fittrack.bmi',
                        subject: 'FitTrack BMI - Health Tracking App',
                      );
                    },
                    trailing: const Icon(Icons.arrow_forward_ios),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data Management Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Data Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.security, color: Colors.blue),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('How we handle your data'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Privacy Policy'),
                          content: const SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Data Collection:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('• BMI data you enter\n• Profile information\n• App usage analytics'),
                                SizedBox(height: 16),
                                Text(
                                  'Data Usage:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('• Provide personalized health advice\n• Improve app functionality\n• Send notifications (with permission)'),
                                SizedBox(height: 16),
                                Text(
                                  'Data Protection:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('• All data is encrypted in transit\n• Stored securely in Firebase\n• You can export or delete your data anytime'),
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
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete Account'),
                    subtitle: const Text('Permanently delete all your data'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text(
                            'This action cannot be undone. All your data including BMI history, profile, and settings will be permanently deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () async {
                                Navigator.pop(context);
                                await _deleteAccount();
                              },
                              child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info, color: Colors.blue),
                    title: const Text('About FitTrack BMI'),
                    subtitle: const Text('Version 1.0.0'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'FitTrack BMI',
                        applicationVersion: '1.0.0',
                        applicationIcon: Icon(Icons.favorite, color: Colors.indigo[400], size: 50),
                        children: const [
                          Text('Your personal health companion for BMI tracking and wellness guidance.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Fitness Tracker Integration Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⌚ Fitness Tracker',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(
                      _fitnessTrackerConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      color: _fitnessTrackerConnected ? Colors.green : Colors.grey,
                    ),
                    title: Text(_fitnessTrackerConnected ? 'Connected' : 'Not Connected'),
                    subtitle: Text(_fitnessTrackerConnected ? _connectedDevice : 'Connect your fitness tracker'),
                    trailing: _fitnessTrackerConnected
                        ? IconButton(
                            icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
                            onPressed: _disconnectFitnessTracker,
                          )
                        : ElevatedButton(
                            onPressed: _connectFitnessTracker,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[200],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Connect'),
                          ),
                  ),
                  if (_fitnessTrackerConnected) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _fitnessService.syncData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data synced!'), backgroundColor: Colors.green),
                        );
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[200],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👤 Account',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout'),
                    subtitle: Text('Logged in as: ${LoginScreen.loggedInEmail ?? 'Unknown'}'),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 5, // Settings tab
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CalculatorScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RecommendationsScreen()),
            );
          }
        },
      ),
    );
  }
} 