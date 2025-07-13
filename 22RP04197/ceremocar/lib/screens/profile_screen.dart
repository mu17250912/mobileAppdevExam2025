import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../main.dart'; // Import AppColors from main.dart
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;
  String? email;
  String? profilePicUrl;
  File? _pickedImage;
  bool isEditing = false;
  ThemeMode? _themeMode;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadThemeMode();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    if (mounted) {
    setState(() { isLoading = true; });
    }
    try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (mounted) {
    setState(() {
      email = user!.email;
      phoneController.text = doc.data()?['phone'] ?? '';
      nameController.text = doc.data()?['name'] ?? '';
      profilePicUrl = doc.data()?['profilePicUrl'];
      isLoading = false;
    });
      }
    } catch (e) {
      if (mounted) {
        setState(() { isLoading = false; });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (user == null) return;
    if (mounted) {
    setState(() { isLoading = true; });
    }
    try {
    String? uploadedUrl = profilePicUrl;
    if (_pickedImage != null) {
      final ref = FirebaseStorage.instance.ref().child('profile_pics').child('${user!.uid}.jpg');
      await ref.putFile(_pickedImage!);
      uploadedUrl = await ref.getDownloadURL();
    }
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'phone': phoneController.text.trim(),
      'name': nameController.text.trim(),
      'profilePicUrl': uploadedUrl,
    });
      if (mounted) {
        setState(() { 
          isLoading = false; 
          profilePicUrl = uploadedUrl; 
        });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile.')));
      }
    }
  }

  Future<void> _updatePassword() async {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(hintText: 'New Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newPassword = passwordController.text;
              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password must be at least 6 characters.')));
                return;
              }
              try {
                await user!.updatePassword(newPassword);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password updated.')));
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update password.')));
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() { _pickedImage = File(picked.path); });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      if (mounted) {
      setState(() { _pickedImage = File(picked.path); isLoading = true; });
      }
      try {
        final ref = FirebaseStorage.instance.ref().child('profile_pics').child('${user?.uid}.jpg');
        await ref.putFile(_pickedImage!);
        final url = await ref.getDownloadURL();
        await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({'profilePicUrl': url});
        if (mounted) {
        setState(() { profilePicUrl = url; isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated!')),
        );
        }
      } catch (e) {
        if (mounted) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture.')),
        );
        }
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode') ?? 'system';
    setState(() {
      if (mode == 'light') _themeMode = ThemeMode.light;
      else if (mode == 'dark') _themeMode = ThemeMode.dark;
      else _themeMode = ThemeMode.system;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    try {
    final prefs = await SharedPreferences.getInstance();
      if (mounted) {
    setState(() { _themeMode = mode; });
      }
    await prefs.setString('themeMode', mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system');
    // Notify the app to update theme
      if (mounted) {
    MyAppTheme.of(context)?.updateThemeMode(mode);
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save theme preference.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Scaffold(
      appBar: canPop
          ? AppBar(
              leading: BackButton(),
              title: Text('Profile', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
            )
          : null,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Profile Card
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                      builder: (context, snapshot) {
                      final data = snapshot.data?.data() as Map<String, dynamic>?;
                      final isPremium = (data?['subscription'] != null && data?['subscription']['status'] == 'active');
                      final isAdmin = (data?['role'] ?? '') == 'admin';
                      final name = nameController.text.isNotEmpty ? nameController.text : 'User';
                      final emailStr = email ?? data?['email'] ?? '';
                      final phoneStr = data?['phone'] ?? '';
                      final profilePic = profilePicUrl ?? data?['profilePicUrl'];
                        return Card(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundImage: (profilePic != null && profilePic.toString().isNotEmpty)
                                    ? NetworkImage(profilePic)
                                    : null,
                                child: (profilePic == null || profilePic.toString().isEmpty)
                                    ? Text(
                                        name.isNotEmpty ? name[0] : '?',
                                        style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
                                      )
                                    : null,
                                backgroundColor: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                        if (isAdmin)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8.0),
                                            child: Chip(
                                              label: const Text('Admin', style: TextStyle(color: Colors.white)),
                                              avatar: const Icon(Icons.security, color: Colors.white),
                                              backgroundColor: Colors.blue,
                                            ),
                                          ),
                                        if (isPremium && !isAdmin)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8.0),
                                            child: Chip(
                                              label: const Text('Premium', style: TextStyle(color: Colors.white)),
                                              avatar: const Icon(Icons.star, color: Colors.white),
                                              backgroundColor: Colors.amber,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (emailStr.isNotEmpty)
                                      Text(emailStr, style: theme.textTheme.bodyMedium),
                                    if (phoneStr.isNotEmpty)
                                      Text(phoneStr, style: theme.textTheme.bodyMedium),
                                    const SizedBox(height: 6),
                                    if (!isAdmin)
                                      Text('No upcoming bookings.', style: theme.textTheme.bodyMedium),
                                    const SizedBox(height: 10),
                                    if (!isAdmin)
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isNarrow = constraints.maxWidth < 400;
                                          if (isNarrow) {
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () => Navigator.pushNamed(context, '/available_cars_screen'),
                                                  icon: const Icon(Icons.add),
                                                  label: const Text('Book a Car'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: theme.colorScheme.primary,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                if (!isPremium)
                                                  ElevatedButton.icon(
                                                    onPressed: () => Navigator.pushNamed(context, '/subscription'),
                                                    icon: const Icon(Icons.star),
                                                    label: const Text('Upgrade to Premium'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: theme.colorScheme.primary,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    ),
                                                  ),
                                                if (!isPremium)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Text(
                                                      'Unlock unlimited bookings and exclusive features.',
                                                      style: TextStyle(color: theme.colorScheme.secondary, fontSize: 13),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                              ],
                                            );
                                          } else {
                                            return Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => Navigator.pushNamed(context, '/available_cars_screen'),
                                                    icon: const Icon(Icons.add),
                                                    label: const Text('Book a Car'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: theme.colorScheme.primary,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                if (!isPremium)
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                                        ElevatedButton.icon(
                                                          onPressed: () => Navigator.pushNamed(context, '/subscription'),
                                                          icon: const Icon(Icons.star),
                                                          label: const Text('Upgrade to Premium'),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: theme.colorScheme.primary,
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                          ),
                                                        ),
                                    const SizedBox(height: 4),
                                                        Text(
                                                          'Unlock unlimited bookings and exclusive features.',
                                                          style: TextStyle(color: theme.colorScheme.secondary, fontSize: 13),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            );
                                          }
                                        },
                                      ),
                                    if (isAdmin)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text('You are logged in as an admin. Access admin features from the main menu.',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue),
                                        ),
                                      ),
                                  ],
                                ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 18),
                  // Theme Mode Toggle
                  Row(
                    children: [
                      Icon(Icons.brightness_6, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Theme Mode:', style: theme.textTheme.titleMedium),
                      const SizedBox(width: 16),
                      DropdownButton<ThemeMode>(
                        value: _themeMode,
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) _setThemeMode(mode);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Premium Thank You Banner (users only)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data() as Map<String, dynamic>?;
                      final isPremium = (data?['subscription'] != null && data?['subscription']['status'] == 'active');
                      final isAdmin = (data?['role'] ?? '') == 'admin';
                      if (!isPremium || isAdmin) return const SizedBox();
                      return Card(
                        color: Colors.amber.withOpacity(0.18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 18),
                        child: ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber, size: 32),
                          title: const Text('Thank you for being a Premium member!'),
                          subtitle: const Text('Enjoy unlimited bookings, exclusive cars, and VIP support.'),
                        ),
                      );
                    },
                  ),
                  // Referral Program Section (users only)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                      builder: (context, snapshot) {
                      final data = snapshot.data?.data() as Map<String, dynamic>?;
                      final isAdmin = (data?['role'] ?? '') == 'admin';
                      if (isAdmin) return const SizedBox();
                      final userId = user?.uid ?? '';
                        final referralCount = data?['referralCount'] ?? 0;
                      final loyaltyPoints = data?['loyaltyPoints'] ?? 0;
                      final referredBy = data?['referredBy'];
                        return Card(
                        margin: const EdgeInsets.only(top: 18),
                        color: theme.colorScheme.primary.withOpacity(0.07),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                          padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text('Referral Program', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('Your Referral Code: $userId'),
                                Row(
                                  children: [
                                  Text('Referrals: $referralCount'),
                                  const SizedBox(width: 16),
                                  Text('Loyalty Points: $loyaltyPoints'),
                                ],
                              ),
                              if (referredBy != null && referredBy.toString().isNotEmpty)
                                Text('You were referred by: $referredBy'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: Icon(Icons.copy),
                                label: Text('Copy Referral Code'),
                                      onPressed: () {
                                  Clipboard.setData(ClipboardData(text: userId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Referral code copied!')),
                                  );
                                },
                              ),
                              if (loyaltyPoints > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Card(
                                    color: Colors.amber.withOpacity(0.18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      leading: Icon(Icons.card_giftcard, color: Colors.amber),
                                      title: Text('You have earned $loyaltyPoints loyalty points!'),
                                      subtitle: Text('Refer more friends to earn more rewards.'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  // Booking History Section (users only)
                  if (user != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        final isAdmin = (data?['role'] ?? '') == 'admin';
                        if (isAdmin) return const SizedBox();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text('Booking History', style: theme.textTheme.headlineSmall),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('bookings')
                                  .where('userId', isEqualTo: user?.uid)
                                  .orderBy('date', descending: true)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  // Try fallback query without orderBy if error is about missing index/field
                                  return FutureBuilder<QuerySnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('bookings')
                                        .where('userId', isEqualTo: user?.uid)
                                        .get(),
                                    builder: (context, fallbackSnap) {
                                      if (fallbackSnap.hasError) {
                                        return Text('Failed to load booking history.');
                                      }
                                      if (!fallbackSnap.hasData) {
                                        return Center(child: CircularProgressIndicator());
                                      }
                                      final bookings = fallbackSnap.data!.docs;
                                      if (bookings.isEmpty) {
                                        return Text('No bookings found.');
                                      }
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: bookings.length,
                                        itemBuilder: (context, index) {
                                          final booking = bookings[index].data() as Map<String, dynamic>;
                                          return ListTile(
                                            leading: Icon(Icons.directions_car, color: theme.colorScheme.primary),
                                            title: Text(booking['carName'] ?? 'Car'),
                                            subtitle: Text('Date: ${booking['date'] ?? ''}'),
                                          );
                                        },
                                      );
                                    },
                                  );
                                }
                                if (!snapshot.hasData) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                final bookings = snapshot.data!.docs;
                                if (bookings.isEmpty) {
                                  return Text('No bookings found.');
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: bookings.length,
                                  itemBuilder: (context, index) {
                                    final booking = bookings[index].data() as Map<String, dynamic>;
                                    return ListTile(
                                      leading: Icon(Icons.directions_car, color: theme.colorScheme.primary),
                                      title: Text(booking['carName'] ?? 'Car'),
                                      subtitle: Text('Date: ${booking['date'] ?? ''}'),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  // Account Actions
                            Row(
                              children: [
                      Icon(Icons.lock, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Account', style: theme.textTheme.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                            Row(
                              children: [
                      ElevatedButton.icon(
                        onPressed: _updatePassword,
                        icon: const Icon(Icons.password),
                        label: const Text('Change Password'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ],
                            ),
                  const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPersonalizedDashboard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                Icon(Icons.person, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Text(nameController.text.isNotEmpty ? nameController.text : 'User',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final isPremium = (data?['subscription'] != null && data?['subscription']['status'] == 'active');
                    return Chip(
                      label: Text(isPremium ? 'Premium' : 'Standard'),
                      backgroundColor: isPremium ? Colors.amber : theme.colorScheme.secondary.withOpacity(0.2),
                      avatar: Icon(Icons.star, color: isPremium ? Colors.white : Colors.amber),
                    );
                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
            // Upcoming Bookings
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: user?.uid)
                  .where('status', isNotEqualTo: 'COMPLETED')
                  .orderBy('status')
                  .orderBy('date')
                  .limit(1)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('No upcoming bookings.', style: theme.textTheme.bodyMedium);
                }
                final booking = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.directions_car, color: theme.colorScheme.primary),
                  title: Text('Upcoming: ${booking['carName'] ?? ''}'),
                  subtitle: Text('On: ${booking['date'] ?? ''} at ${booking['time'] ?? ''}'),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/available_cars_screen'),
                  icon: const Icon(Icons.add),
                  label: const Text('Book a Car'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/subscription'),
                  icon: const Icon(Icons.star),
                  label: const Text('Upgrade'),
                ),
              ],
                            ),
                          ],
                        ),
                      ),
    );
  }

  Widget _buildPremiumUpsellBanner(ThemeData theme) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final isPremium = (data?['subscription'] != null && data?['subscription']['status'] == 'active');
        if (isPremium) return const SizedBox();
                              return Card(
          color: Colors.amber.withOpacity(0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
            leading: const Icon(Icons.star, color: Colors.amber, size: 32),
            title: const Text('Unlock Premium Features!'),
            subtitle: const Text('Get unlimited bookings, exclusive cars, and VIP support.'),
            trailing: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/subscription'),
              child: const Text('Go Premium'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
                                  ),
                                ),
                              );
                            },
                          );
  }

  Widget _buildBookingHistory(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Booking History', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: user?.uid)
              .orderBy('date', descending: true)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final bookings = snapshot.data!.docs;
            if (bookings.isEmpty) return const Text('No bookings yet.');
            return Column(
              children: bookings.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final hasFeedback = (data['feedback'] ?? '').toString().isNotEmpty;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text(data['carName'] ?? ''),
                    subtitle: Text('On: ${data['date'] ?? ''} at ${data['time'] ?? ''}\nStatus: ${data['status'] ?? ''}'),
                    trailing: hasFeedback
                        ? const Icon(Icons.check, color: Colors.green)
                        : ElevatedButton(
                            onPressed: () => _showFeedbackDialog(doc.id),
                            child: const Text('Feedback'),
                          ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showFeedbackDialog(String bookingId) {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Feedback'),
        content: TextField(
          controller: feedbackController,
          decoration: const InputDecoration(labelText: 'Your feedback'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
                'feedback': feedbackController.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text('Submit'),
                            ),
                          ],
                        ),
    );
  }

  Widget _buildSupportButton(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Support'),
              content: const Text('For help, contact support@ceremocar.com or visit our FAQ.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                    ),
                  ],
                ),
          );
        },
        icon: const Icon(Icons.help_outline),
        label: const Text('Support / FAQ'),
            ),
    );
  }
} 