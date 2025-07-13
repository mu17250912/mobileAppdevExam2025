import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  Future<void> _pickAndUploadPhoto(String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_photos/$uid.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'photoUrl': url});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _editProfileDialog(String uid, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final shopController = TextEditingController(text: data['shopName'] ?? '');
    final phoneController = TextEditingController(text: data['phone'] ?? '');
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                controller: shopController,
                decoration: const InputDecoration(labelText: 'Shop Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter shop name' : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) => v == null || v.isEmpty ? 'Enter phone' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': nameController.text.trim(),
        'shopName': shopController.text.trim(),
        'phone': phoneController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green[600],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No profile data found.'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['name'] ?? 'No Name';
          final String shopName = (data['shopName'] == null || (data['shopName'] as String).trim().isEmpty)
              ? 'Berwa Store'
              : data['shopName'];
          final String email = user?.email ?? 'No Email';
          final String phone = data['phone'] ?? 'No Phone';
          final String subscription = data['isPremium'] == true ? 'Premium' : 'Free';
          final String? photoUrl = data['photoUrl'];
          final String uid = user?.uid ?? '';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(Icons.person, size: 48) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _uploading ? null : () => _pickAndUploadPhoto(uid),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: _uploading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.camera_alt, size: 20, color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(shopName, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(email),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(phone),
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: Text('Subscription: $subscription'),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _editProfileDialog(uid, data),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 