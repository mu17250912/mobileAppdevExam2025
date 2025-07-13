import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _universityController;
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _universityController = TextEditingController(text: user?.university ?? '');
    _profileImageUrl = user?.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    Uint8List? imageBytes;
    String? fileName;
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (result != null && result.files.single.bytes != null) {
        imageBytes = result.files.single.bytes;
        fileName = result.files.single.name;
      }
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        imageBytes = await pickedFile.readAsBytes();
        fileName = pickedFile.name;
      }
    }
    if (imageBytes != null && fileName != null) {
      setState(() {
        _profileImageBytes = imageBytes;
      });
      await _uploadProfileImage(imageBytes, fileName);
    }
  }

  Future<void> _uploadProfileImage(Uint8List imageBytes, String fileName) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) return;
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.id}_${DateTime.now().millisecondsSinceEpoch}_$fileName');
      final uploadTask = storageRef.putData(imageBytes);
      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / (event.totalBytes > 0 ? event.totalBytes : 1);
        });
      });
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        _profileImageUrl = downloadUrl;
        _isUploading = false;
      });
    } catch (e) {
      setState(() { _isUploading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Mock update logic
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.updateProfile(
        name: _nameController.text.trim(),
        university: _universityController.text.trim(),
        profileImage: _profileImageUrl, // In real app, upload and use the URL
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.amber[200],
                      backgroundImage: _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!)
                          : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : null,
                      child: _profileImageBytes == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                          ? const Icon(Icons.camera_alt, size: 36, color: Colors.white70)
                          : null,
                    ),
                   if (_isUploading)
                     Positioned.fill(
                       child: Container(
                         color: Colors.black26,
                         child: Center(
                           child: CircularProgressIndicator(value: _uploadProgress),
                         ),
                       ),
                     ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value == null || value.isEmpty ? 'Enter your email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _universityController,
                decoration: const InputDecoration(labelText: 'University'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 