import 'package:flutter/material.dart';
import '../../core/session_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String? _name;
  String? _contact;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      setState(() {
        _name = data?['name'] ?? user.displayName ?? user.email ?? '';
        _contact = data?['contact'] ?? user.email ?? '';
        _isLoading = false;
      });
    } else {
      setState(() { _isLoading = false; });
    }
  }

  void _editProfile() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: _name ?? '');
        final contactController = TextEditingController(text: _contact ?? '');
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: 'Phone or Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty || contactController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and contact cannot be empty.')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'name': nameController.text,
                  'contact': contactController.text,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        _name = result['name'] ?? _name;
        _contact = result['contact'] ?? _contact;
      });
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _name,
          'contact': _contact,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/44.jpg'),
                      ),
                      const SizedBox(height: 12),
                      Text(_name ?? user?.displayName ?? user?.email ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_contact ?? user?.email ?? '', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.green),
                  title: const Text('Edit Profile'),
                  onTap: _editProfile,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode, color: Colors.green),
                  title: const Text('Dark Mode'),
                  value: _darkMode,
                  onChanged: (val) => setState(() => _darkMode = val),
                ),
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.green),
                  title: const Text('About App'),
                  onTap: () {},
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    SessionManager.clear();
                    Navigator.pushNamedAndRemoveUntil(context, '/role_selection', (route) => false);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout / Switch Role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
    );
  }
} 