import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _postNameController;
  String _role = 'Employee';
  File? _profileImage;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _postNameController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _postNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId = user.uid;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _currentUser = userData;
            _nameController.text = userData['name'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _postNameController.text = userData['postName'] ?? '';
            _role = userData['role'] ?? 'Employee';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/$_userId.jpg');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  ImageProvider? _getProfileImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_currentUser?['profileImage'] != null) {
      return NetworkImage(_currentUser!['profileImage']);
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _currentUser!['profileImage'];
      
      // Upload new image if selected
      if (_profileImage != null) {
        imageUrl = await _uploadProfileImage(_profileImage!);
        if (imageUrl == null) {
          throw Exception('Failed to upload profile image');
        }
      }

      // Update user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'postName': _postNameController.text.trim().isEmpty ? null : _postNameController.text.trim(),
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update current user reference
      _currentUser!['name'] = _nameController.text.trim();
      _currentUser!['email'] = _emailController.text.trim();
      _currentUser!['postName'] = _postNameController.text.trim().isEmpty ? null : _postNameController.text.trim();
      _currentUser!['profileImage'] = imageUrl;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile Saved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text &&
                  newPasswordController.text.length >= 6) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match or are too short'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Re-authenticate user before changing password
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPasswordController.text,
          );
          await user.reauthenticateWithCredential(credential);
          
          // Change password
          await user.updatePassword(newPasswordController.text);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password changed successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error changing password: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
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
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging out: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Profile Image
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _getProfileImage(),
                        child: _getProfileImage() == null
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // User Info
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    enabled: false, // Email cannot be changed
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _postNameController,
                    decoration: const InputDecoration(
                      labelText: 'Post Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Role Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Role',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_role),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Save Profile',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _changePassword,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Change Password',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 