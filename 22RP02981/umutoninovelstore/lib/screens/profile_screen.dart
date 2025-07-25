import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    setState(() { _isSaving = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _nameController.text.trim().isNotEmpty) {
      await user.updateDisplayName(_nameController.text.trim());
      await user.reload();
      setState(() {}); // Refresh UI
    }
    setState(() { _isSaving = false; });
  }

  Future<void> _changeProfilePicture() async {
    setState(() { _isUploading = true; });
    try {
      print('Starting profile picture change...');
      XFile? pickedFile;
      if (kIsWeb) {
        print('Running on web, using file_picker...');
        final result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result == null || result.files.isEmpty) {
          print('No file selected.');
          if (mounted) setState(() { _isUploading = false; });
          return;
        }
        final fileBytes = result.files.first.bytes;
        final fileName = result.files.first.name;
        print('File selected: $fileName');
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && fileBytes != null) {
          final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}_$fileName');
          print('Uploading to Firebase Storage...');
          await storageRef.putData(fileBytes);
          print('Upload complete. Getting download URL...');
          final downloadUrl = await storageRef.getDownloadURL();
          print('Download URL: $downloadUrl');
          await user.updatePhotoURL(downloadUrl);
          print('PhotoURL updated in Firebase Auth. Reloading user...');
          await user.reload();
          print('User reloaded.');
          setState(() {}); // Refresh UI
        }
      } else {
        print('Running on mobile/desktop, using image_picker...');
        final picker = ImagePicker();
        pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
        if (pickedFile == null) {
          print('No file selected.');
          if (mounted) setState(() { _isUploading = false; });
          return;
        }
        print('File selected: ${pickedFile.path}');
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}.jpg');
          print('Uploading to Firebase Storage...');
          await storageRef.putFile(File(pickedFile.path));
          print('Upload complete. Getting download URL...');
          final downloadUrl = await storageRef.getDownloadURL();
          print('Download URL: $downloadUrl');
          await user.updatePhotoURL(downloadUrl);
          print('PhotoURL updated in Firebase Auth. Reloading user...');
          await user.reload();
          print('User reloaded.');
          setState(() {}); // Refresh UI
        }
      }
    } catch (e) {
      print('Error in _changeProfilePicture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isUploading = false; });
      }
      print('Profile picture change process finished.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email';
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName ?? '';
    final firstLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8), // Soft green background
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          firstLetter,
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                  backgroundColor: Colors.red,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _isUploading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.blue),
                          onPressed: _changeProfilePicture,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Name:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Enter your name'),
                  ),
                ),
                const SizedBox(width: 8),
                _isSaving
                  ? const CircularProgressIndicator()
                  : IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveDisplayName,
                    ),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Email:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(email, style: const TextStyle(fontSize: 18)),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 