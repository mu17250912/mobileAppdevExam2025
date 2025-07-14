import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? profileImageUrl;

  const AppDrawer({super.key, required this.userName, required this.userEmail, this.profileImageUrl});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _profileImageUrl = userData['profileImage'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  ImageProvider? _getProfileImage() {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return const AssetImage('assets/default_avatar.png');
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(widget.userName),
            accountEmail: Text(widget.userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundImage: _getProfileImage(),
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('Error loading profile image: $exception');
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              // Refresh profile image after returning from profile screen
              _loadUserProfile();
            },
          ),
          ListTile(
            leading: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
            title: Text(_isLoading ? 'Logging out...' : 'Logout'),
            onTap: _isLoading ? null : _logout,
          ),
        ],
      ),
    );
  }
} 