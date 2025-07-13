import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNotificationSettings extends StatefulWidget {
  const AdminNotificationSettings({super.key});

  @override
  State<AdminNotificationSettings> createState() => _AdminNotificationSettingsState();
}

class _AdminNotificationSettingsState extends State<AdminNotificationSettings> {
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;
  bool _betNotificationsEnabled = true;
  bool _depositNotificationsEnabled = true;
  bool _withdrawalNotificationsEnabled = true;
  bool _profileNotificationsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('admin_notification_settings')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _pushNotificationsEnabled = data['pushNotifications'] ?? true;
            _emailNotificationsEnabled = data['emailNotifications'] ?? false;
            _betNotificationsEnabled = data['betNotifications'] ?? true;
            _depositNotificationsEnabled = data['depositNotifications'] ?? true;
            _withdrawalNotificationsEnabled = data['withdrawalNotifications'] ?? true;
            _profileNotificationsEnabled = data['profileNotifications'] ?? false;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('admin_notification_settings')
            .doc(user.uid)
            .set({
          'pushNotifications': _pushNotificationsEnabled,
          'emailNotifications': _emailNotificationsEnabled,
          'betNotifications': _betNotificationsEnabled,
          'depositNotifications': _depositNotificationsEnabled,
          'withdrawalNotifications': _withdrawalNotificationsEnabled,
          'profileNotifications': _profileNotificationsEnabled,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'General Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive push notifications on your device'),
                      value: _pushNotificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _pushNotificationsEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Email Notifications'),
                      subtitle: const Text('Receive notifications via email'),
                      value: _emailNotificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _emailNotificationsEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Types',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Bet Notifications'),
                      subtitle: const Text('When users place bets or bet status changes'),
                      value: _betNotificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _betNotificationsEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Deposit Notifications'),
                      subtitle: const Text('When users make deposits'),
                      value: _depositNotificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _depositNotificationsEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Withdrawal Notifications'),
                      subtitle: const Text('When users request withdrawals'),
                      value: _withdrawalNotificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _withdrawalNotificationsEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Profile Notifications'),
                      subtitle: const Text('When users update their profiles'),
                      value: _profileNotificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _profileNotificationsEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.mark_email_read),
                      title: const Text('Mark All Notifications as Read'),
                      onTap: () async {
                        try {
                          final notifications = await FirebaseFirestore.instance
                              .collection('admin_notifications')
                              .where('read', isEqualTo: false)
                              .get();
                          
                          final batch = FirebaseFirestore.instance.batch();
                          for (var doc in notifications.docs) {
                            batch.update(doc.reference, {'read': true});
                          }
                          await batch.commit();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All notifications marked as read')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.clear_all, color: Colors.red),
                      title: const Text('Clear All Notifications'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear All Notifications'),
                            content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    final notifications = await FirebaseFirestore.instance
                                        .collection('admin_notifications')
                                        .get();
                                    
                                    final batch = FirebaseFirestore.instance.batch();
                                    for (var doc in notifications.docs) {
                                      batch.delete(doc.reference);
                                    }
                                    await batch.commit();
                                    
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('All notifications cleared')),
                                    );
                                  } catch (e) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                                child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 