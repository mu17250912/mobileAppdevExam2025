import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      setState(() {
        _name = data?['name'] ?? '';
        _phone = data?['phone'] ?? '';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get current user data to check what changed
      final currentDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final currentData = currentDoc.data() as Map<String, dynamic>? ?? {};
      final currentName = currentData['name'] ?? '';
      final currentPhone = currentData['phone'] ?? '';
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _name,
        'phone': _phone,
      }, SetOptions(merge: true));
      
      // Send notification to all providers about profile update
      final updatedFields = <String>[];
      if (currentName != _name) updatedFields.add('name');
      if (currentPhone != _phone) updatedFields.add('phone');
      
      if (updatedFields.isNotEmpty) {
        await _sendProfileUpdateNotification(updatedFields);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
        // Schedule notification after 5 seconds
        Future.delayed(const Duration(seconds: 5), () async {
          await flutterLocalNotificationsPlugin.show(
            0,
            'Profile Updated',
            'Your profile was updated successfully!',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'profile_channel',
                'Profile Notifications',
                channelDescription: 'Notifications for profile updates',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        });
        Navigator.pop(context);
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _sendProfileUpdateNotification(List<String> updatedFields) async {
    try {
      // Get all providers
      final providersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .get();

      // Send notification to each provider
      for (final providerDoc in providersSnapshot.docs) {
        await NotificationService.sendProfileUpdateNotification(
          providerId: providerDoc.id,
          userId: FirebaseAuth.instance.currentUser!.uid,
          userName: _name,
          updatedFields: updatedFields,
        );
      }
    } catch (e) {
      print('Error sending profile update notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => _name = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (val) => _phone = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter your phone number' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 