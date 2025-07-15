import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';
import 'dashboard_screen.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';
import 'recommendations_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = 'Male';
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadProfilePhoto();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.loadProfile();
      if (profile != null) {
        setState(() {
          _nameController.text = profile.name;
          _ageController.text = profile.age.toString();
          _selectedGender = profile.gender;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final photo = await _profileService.getProfilePhoto();
      print('Loading profile photo: ${photo?.path}');
      if (photo != null) {
        setState(() {
          _profileImage = photo;
        });
        print('Profile photo loaded successfully');
      } else {
        print('No profile photo found');
      }
    } catch (e) {
      print('Error loading profile photo: $e');
    }
  }

  Future<void> _saveProfile() async {
    try {
      final profile = Profile(
        name: _nameController.text.isEmpty ? 'User' : _nameController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _selectedGender,
        photoPath: _profileImage?.path,
      );
      await _profileService.saveProfile(profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (image != null) {
        print('Image selected: ${image.path}');
        final file = File(image.path);
        setState(() {
          _profileImage = file;
        });
        await _profileService.saveProfilePhotoPath(image.path);
        print('Profile photo path saved: $image.path');
        // Automatically save profile data when photo is selected
        await _autoSaveProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo saved!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _autoSaveProfile() async {
    try {
      final profile = Profile(
        name: _nameController.text.isEmpty ? 'User' : _nameController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _selectedGender,
        photoPath: _profileImage?.path,
      );
      await _profileService.saveProfile(profile);
    } catch (e) {
      print('Error auto-saving profile: $e');
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Profile Photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.indigo[400],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile Image
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.indigo[400],
                          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                          child: _profileImage == null
                              ? const Icon(Icons.person, size: 60, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _showImagePickerDialog,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 20, color: Colors.indigo),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person, color: Colors.indigo),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.cake, color: Colors.indigo),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.wc, color: Colors.indigo),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
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
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RecommendationsScreen()),
            );
          } else if (index == 5) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }
} 