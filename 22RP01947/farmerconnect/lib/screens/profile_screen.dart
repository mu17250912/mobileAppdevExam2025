import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'splash_screen.dart';
import 'auth_screen.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  String? _userType;
  double? _rating;
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isFetching = true;
    });
    try {
      if (AppUser.userId == null) {
        // Not logged in, redirect to login
        if (mounted) context.go('/login');
        return;
      }
      final doc = await FirestoreService.getUser(AppUser.userId!);
      final data = doc.data();
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? (data['emailOrPhone'] ?? '');
        _emailController.text = data['email'] ?? (data['emailOrPhone'] ?? '');
        _locationController.text = data['location'] ?? '';
        _userType = data['userType'] ?? '';
        _rating = (data['rating'] is num) ? (data['rating'] as num).toDouble() : null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'location': _locationController.text,
        'userType': _userType ?? 'Farmer',
        'rating': _rating ?? 4.8,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await FirestoreService.updateUser(AppUser.userId!, userData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
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

  void _logout() {
    AppUser.userType = null;
    AppUser.userId = null;
    AppUser.name = null;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E8B57),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('👨‍🌾', style: TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(_nameController.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(_userType ?? ''),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(_rating != null ? '${_rating!.toStringAsFixed(1)}/5' : ''),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update Profile'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C757D)),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}