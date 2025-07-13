import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();
  final _profilePicController = TextEditingController();
  User? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _displayNameController.text = _user?.displayName ?? '';
    // Load extra fields from Firestore
    if (_user != null) {
      FirebaseFirestore.instance.collection('users').doc(_user!.uid).get().then((doc) {
        final data = doc.data();
        if (data != null) {
          _fullNameController.text = data['fullName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _countryController.text = data['country'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _profilePicController.text = data['profilePic'] ?? '';
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    _profilePicController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_displayNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update Firebase Auth display name
      await _user?.updateDisplayName(_displayNameController.text.trim());
      
      // Update Firestore user document
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        'displayName': _displayNameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'country': _countryController.text.trim(),
        'bio': _bioController.text.trim(),
        'profilePic': _profilePicController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await _user?.reload(); // Reload user to get updated info
      _user = FirebaseAuth.instance.currentUser; // Get the reloaded user

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.of(context).pop(); // Go back to AccountScreen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edit Profile',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Full Name', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Display Name', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your display name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Phone Number', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Country / Location', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        hintText: 'Enter your country or location',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Bio / About Me', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tell us about yourself',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Profile Picture URL', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _profilePicController,
                      decoration: InputDecoration(
                        hintText: 'Paste a link to your profile picture (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: _isLoading
                          ? CircularProgressIndicator(color: theme.colorScheme.primary)
                          : ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                elevation: 2,
                              ),
                              child: const Text('Save Changes'),
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