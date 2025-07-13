import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'login_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class UserProfilePage extends StatefulWidget {
  final User user;
  const UserProfilePage({super.key, required this.user});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  File? _profileImage;
  String? _profileImagePath;
  Uint8List? _profileImageBytes; // For web
  bool _loading = false;
  final bool _darkTheme = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'French', 'Kinyarwanda'];
  String? _username;
  String? _email;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _fetchUserInfo();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _profileImagePath = path;
        _profileImage = File(path);
      });
    }
  }

  Future<void> _pickImage() async {
    setState(() { _loading = true; });
    try {
      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result == null || result.files.single.bytes == null) {
          setState(() { _loading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected.')),
          );
          return;
        }
        setState(() {
          _profileImageBytes = result.files.single.bytes;
          _profileImagePath = null;
          _profileImage = null;
          _loading = false;
        });
        // Optionally, persist bytes using local storage or backend for web
      } else {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile == null) {
          setState(() { _loading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected.')),
          );
          return;
        }
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', savedImage.path);
        setState(() {
          _profileImage = savedImage;
          _profileImagePath = savedImage.path;
          _profileImageBytes = null;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _fetchUserInfo() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _username = doc.data()?['username'] ?? user.displayName ?? user.email ?? '';
        _email = doc.data()?['email'] ?? user.email ?? '';
      });
    }
  }

  Future<void> _editPersonalInfo() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    final usernameController = TextEditingController(text: _username ?? '');
    final emailController = TextEditingController(text: _email ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = usernameController.text.trim();
              final newEmail = emailController.text.trim();
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                  'username': newUsername,
                  'email': newEmail,
                });
                setState(() {
                  _username = newUsername;
                  _email = newEmail;
                });
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Personal information updated.')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F5BD5), Color(0xFF6A82FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _loading ? null : _pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.deepPurple[100],
                            backgroundImage: kIsWeb && _profileImageBytes != null
                                ? MemoryImage(_profileImageBytes!)
                                : _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : null,
                            child: _profileImage == null && _profileImageBytes == null
                                ? const Icon(Icons.camera_alt, size: 48, color: Colors.deepPurple)
                                : null,
                          ),
                          if (_loading)
                            const CircularProgressIndicator(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.user.username,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Profile Info Section
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                  tooltip: 'Edit',
                                  onPressed: _editPersonalInfo,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Username: ${_username ?? ''}', style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Email: ${_email ?? ''}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    // Change Password
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            String oldPass = '';
                            String newPass = '';
                            return AlertDialog(
                              title: const Text('Change Password'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    obscureText: true,
                                    decoration: const InputDecoration(labelText: 'Old Password'),
                                    onChanged: (val) => oldPass = val,
                                  ),
                                  TextField(
                                    obscureText: true,
                                    decoration: const InputDecoration(labelText: 'New Password'),
                                    onChanged: (val) => newPass = val,
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
                                    // Here you would add real password change logic
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password changed (demo only)')),
                                    );
                                  },
                                  child: const Text('Change'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.lock),
                      label: const Text('Change Password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App Preferences Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text('App Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F5BD5))),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Dark Theme'),
                      value: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark,
                      onChanged: (val) {
                        Provider.of<ThemeProvider>(context, listen: false).setTheme(val ? ThemeMode.dark : ThemeMode.light);
                      },
                      activeColor: Colors.deepPurple,
                    ),
                    SwitchListTile(
                      title: const Text('Enable Notifications'),
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() { _notificationsEnabled = val; });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                    // Remove language dropdown
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => LoginPage()),
                          (route) => false,
                        );
                        // Reload theme for logged-out state
                        Future.delayed(Duration.zero, () {
                          if (mounted) {
                            final provider = Provider.of<ThemeProvider>(context, listen: false);
                            provider.reloadTheme();
                          }
                        });
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 