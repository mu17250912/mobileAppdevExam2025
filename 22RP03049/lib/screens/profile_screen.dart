import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  Future<void> _pickAndUploadImage(User user) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    setState(() => _uploading = true);
    final file = File(picked.path);
    final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
    await storageRef.putFile(file);
    final url = await storageRef.getDownloadURL();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profileImage': url});
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your profile.'));
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final plan = data?['plan'] ?? 'basic';
        final imageUrl = data?['profileImage'] as String?;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                        child: imageUrl == null ? const Icon(Icons.account_circle, size: 64) : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _uploading ? null : () => _pickAndUploadImage(user),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.amber,
                            child: _uploading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.edit, size: 18, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(user.email ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Plan:  [31m${plan == 'premium' ? 'Premium' : 'Basic'} [0m', style: TextStyle(fontSize: 18, color: plan == 'premium' ? Colors.amber[800] : Colors.black)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }
} 