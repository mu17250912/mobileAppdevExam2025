import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'income_entry_screen.dart';
import 'expense_entry_screen.dart';
import 'report_screen.dart';
import 'premium_screen.dart';
import 'advanced_reports_screen.dart';
import 'saving_goals_screen.dart';
import 'smart_reminders_screen.dart';
import 'ai_insights_screen.dart';
import 'test_payment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'main.dart';
import 'premium_features_summary.dart';
import 'premium_upgrade_dialog.dart';
import 'profile_photo_mobile.dart' if (dart.library.html) 'profile_photo_web.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Transactions', style: TextStyle(fontSize: 24)));
  }
}

class SettingsScreen extends StatefulWidget {
  final void Function(int)? onRequirePremium;
  const SettingsScreen({super.key, this.onRequirePremium});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _isPremium = false;
  bool _isLoading = false;
  final PremiumFeaturesManager _premiumManager = PremiumFeaturesManager();

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await _premiumManager.isPremium();
      setState(() {
        _isPremium = isPremium;
      });
    } catch (e) {
      print('Error checking premium status: $e');
    }
  }

  Future<void> _handlePremiumFeatureTap(String featureName, VoidCallback onPremiumTap) async {
    final isPremium = await _premiumManager.isPremium();
    if (isPremium) {
      onPremiumTap();
    } else {
      if (widget.onRequirePremium != null) {
        widget.onRequirePremium!(1); // 1 is the Wallet tab index
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please pay 100 FRW in Wallet to unlock premium features!', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      } else {
        context.showPremiumUpgradeDialog(
          featureName: featureName,
          customMessage: 'This premium feature will help you better manage your finances.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        Text('Settings', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
        const SizedBox(height: 24),
        // --- Premium Section ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.08),
                Theme.of(context).colorScheme.secondary.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.workspace_premium, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    _isPremium ? 'You are Premium!' : 'Unlock Premium!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Enjoy all advanced features: analytics, unlimited categories, saving goals, reminders, AI insights, and more.',
                style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 12),
              if (!_isPremium)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: () async {
                      widget.onRequirePremium?.call(1);
                    },
                    child: const Text('Pay 100 FRW to Unlock Premium'),
                  ),
                ),
              if (_isPremium)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text('Premium active', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.secondary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Premium Features Section
        Text(
          'Premium Features',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.analytics, color: Colors.blue),
          title: Text('Advanced Reports', style: GoogleFonts.poppins(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
          subtitle: Text('Detailed analytics and insights', style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isPremium)
                Icon(Icons.lock, size: 16, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
          onTap: () => _handlePremiumFeatureTap(
            'Advanced Reports',
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdvancedReportsScreen()),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.savings, color: Colors.green),
          title: Text('Saving Goals', style: GoogleFonts.poppins(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
          subtitle: Text('Set and track financial goals', style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isPremium)
                Icon(Icons.lock, size: 16, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
          onTap: () => _handlePremiumFeatureTap(
            'Saving Goals',
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavingGoalsScreen()),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.notifications_active, color: Colors.orange),
          title: Text('Smart Reminders', style: GoogleFonts.poppins(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
          subtitle: Text('Never miss bills or deadlines', style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isPremium)
                Icon(Icons.lock, size: 16, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
          onTap: () => _handlePremiumFeatureTap(
            'Smart Reminders',
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SmartRemindersScreen()),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.psychology, color: Colors.purple),
          title: Text('AI Spending Insights', style: GoogleFonts.poppins(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
          subtitle: Text('Get personalized recommendations', style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isPremium)
                Icon(Icons.lock, size: 16, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
          onTap: () => _handlePremiumFeatureTap(
            'AI Spending Insights',
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AIInsightsScreen()),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // General Settings
        Text(
          'General Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text('Dark Mode', style: GoogleFonts.poppins(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
          value: _darkMode,
          onChanged: (val) {
            setState(() => _darkMode = val);
            ThemeNotifier.of(context)?.themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
          },
          secondary: Icon(Icons.dark_mode, color: Theme.of(context).iconTheme.color),
        ),
        SwitchListTile(
          title: Text('Notifications', style: GoogleFonts.poppins(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
          value: _notifications,
          onChanged: (val) {
            setState(() => _notifications = val);
            // TODO: Implement notification logic
          },
          secondary: Icon(Icons.notifications_active, color: Theme.of(context).iconTheme.color),
        ),
        const SizedBox(height: 24),
        
        // About Section
        Text(
          'About',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.info_outline, color: Theme.of(context).iconTheme.color),
          title: Text('About SmartBudget', style: GoogleFonts.poppins(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'SmartBudget',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2024 SmartBudget',
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.privacy_tip, color: Theme.of(context).iconTheme.color),
          title: Text('Privacy Policy', style: GoogleFonts.poppins(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
          onTap: () {
            // TODO: Show privacy policy
          },
        ),
        ListTile(
          leading: Icon(Icons.description, color: Theme.of(context).iconTheme.color),
          title: Text('Terms of Service', style: GoogleFonts.poppins(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
          onTap: () {
            // TODO: Show terms of service
          },
        ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isUploadingPhoto = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _pickAndUploadImage() async {
    // Only allow on mobile
    if (identical(0, 0.0)) { // This is always false, but will be replaced below
      setState(() => _isUploadingPhoto = true);
      try {
        final downloadURL = await pickAndUploadImageMobile();
        if (downloadURL != null) {
          final user = FirebaseAuth.instance.currentUser;
          await user?.updatePhotoURL(downloadURL);
          await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
            'photoURL': downloadURL,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          if (mounted) setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile photo updated!'), backgroundColor: Theme.of(context).colorScheme.secondary),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      } finally {
        if (mounted) setState(() => _isUploadingPhoto = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo upload is only available on mobile.'), backgroundColor: Theme.of(context).colorScheme.primary),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Remove photo URL from Firebase Auth
      await user.updatePhotoURL(null);
      
      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoURL': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile photo removed successfully!', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {}); // Refresh the UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove photo: ${e.toString()}', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the errors in the form', style: Theme.of(context).textTheme.bodyMedium),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final newName = _nameController.text.trim();
      final newEmail = _emailController.text.trim();
      
      // Validate inputs
      if (newName.isEmpty) {
        throw Exception('Name cannot be empty');
      }
      if (newEmail.isEmpty) {
        throw Exception('Email cannot be empty');
      }

      // Update Firestore first (more reliable)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': newName,
        'email': newEmail,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Then update Firebase Auth
      if (newName != user.displayName) {
        await user.updateDisplayName(newName);
      }
      
      if (newEmail != user.email) {
        await user.updateEmail(newEmail);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() => _isEditing = false);
        
        // Reload user data to reflect changes
        _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update profile';
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'This email is already in use by another account';
        } else if (e.toString().contains('requires-recent-login')) {
          errorMessage = 'Please log out and log in again to change your email';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Please enter a valid email address';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _isUploadingPhoto ? null : _pickAndUploadImage,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                            child: user?.photoURL == null
                                ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.onPrimaryContainer)
                                : _isUploadingPhoto
                                    ? CircularProgressIndicator(strokeWidth: 3, color: Theme.of(context).colorScheme.onPrimaryContainer)
                                    : null,
                          ),
                        ),
                        if (_isUploadingPhoto)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.secondary),
                          ),
                        if (!_isUploadingPhoto)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).shadowColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.camera_alt, size: 20, color: Theme.of(context).colorScheme.onSecondary),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Edit Profile Form or Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _isEditing ? _buildEditForm() : _buildActionButtons(),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: GoogleFonts.poppins(),
                      filled: true,
                      fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                      hintText: 'Enter your full name',
                    ),
                    style: GoogleFonts.poppins(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: GoogleFonts.poppins(),
                      filled: true,
                      fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
                      hintText: 'Enter your email address',
                    ),
                    style: GoogleFonts.poppins(fontSize: 16),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Theme.of(context).colorScheme.onError,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setState(() => _isEditing = false);
                            _loadUserData(); // Reset to original values
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          'Edit Profile',
          Icons.edit,
          Theme.of(context).colorScheme.primary,
          () {
            setState(() => _isEditing = true);
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Privacy Settings',
          Icons.privacy_tip,
          Theme.of(context).colorScheme.tertiary,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Privacy Settings coming soon!', style: Theme.of(context).textTheme.bodyMedium),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Help & Support',
          Icons.help_outline,
          Theme.of(context).colorScheme.secondary,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Help & Support coming soon!', style: Theme.of(context).textTheme.bodyMedium),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  )
                : const Icon(Icons.logout),
            label: Text(_isLoading ? 'Logging out...' : 'Logout'),
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}', style: Theme.of(context).textTheme.bodyMedium),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  setState(() => _isLoading = false);
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).textTheme.bodyMedium?.color,
          size: 16,
        ),
        onTap: onPressed,
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0; // Default to Dashboard/Home tab
  bool _isPremium = false;
  final PremiumFeaturesManager _premiumManager = PremiumFeaturesManager();

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await _premiumManager.isPremium();
      setState(() {
        _isPremium = isPremium;
      });
    } catch (e) {
      print('Error checking premium status: $e');
    }
  }

  Future<Map<String, num>> _fetchTotals() async {
    final incomeSnap = await FirebaseFirestore.instance.collection('income').get();
    final expenseSnap = await FirebaseFirestore.instance.collection('expenses').get();
    num totalIncome = 0;
    num totalExpense = 0;
    for (var doc in incomeSnap.docs) {
      final amt = num.tryParse(doc['amount'].toString()) ?? 0;
      totalIncome += amt;
    }
    for (var doc in expenseSnap.docs) {
      final amt = num.tryParse(doc['amount'].toString()) ?? 0;
      totalExpense += amt;
    }
    return {
      'income': totalIncome,
      'expense': totalExpense,
    };
  }

  Widget _getCurrentScreen() {
    void handleRequirePremium(int idx) {
      setState(() {
        _currentIndex = idx;
      });
    }
    // Allow all screens for everyone; premium features will check access themselves
    switch (_currentIndex) {
      case 0:
        return _buildChoiceButtons(context);
      case 1:
        return WalletScreen();
      case 2:
        return ProfileScreen();
      case 3:
        return ReportScreen(onRequirePremium: handleRequirePremium);
      case 4:
        return SettingsScreen(onRequirePremium: handleRequirePremium);
      default:
        return _buildChoiceButtons(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: null,
        title: Text(
          'SmartBudget',
          style: GoogleFonts.poppins(
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: Theme.of(context).colorScheme.surface,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          // Advanced tab removed
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildChoiceButtons(BuildContext context) {
    return FutureBuilder<Map<String, num>>(
      future: _fetchTotals(),
      builder: (context, snapshot) {
        num income = 0;
        num expense = 0;
        if (snapshot.hasData) {
          income = snapshot.data!['income'] ?? 0;
          expense = snapshot.data!['expense'] ?? 0;
        }
        final remaining = income - expense;
        final percent = (income > 0) ? ((remaining / income) * 100).clamp(0, 100) : 0;
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  if (income > 0)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: percent > 50 ? Theme.of(context).colorScheme.secondaryContainer : (percent > 20 ? Theme.of(context).colorScheme.tertiaryContainer : Theme.of(context).colorScheme.errorContainer),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications, color: percent > 50 ? Theme.of(context).colorScheme.secondary : (percent > 20 ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.error)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You have ${percent.toStringAsFixed(1)}% of your budget remaining (${remaining.toStringAsFixed(0)} FRW)',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      minimumSize: const Size(double.infinity, 70),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 32, color: Colors.green),
                    label: const Text('Income'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const IncomeEntryScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                      minimumSize: const Size(double.infinity, 70),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.remove_circle_outline, size: 32, color: Colors.red),
                    label: const Text('Expense'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ExpenseEntryScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ReportScreen()),
                      );
                    },
                    child: const Text('See Report'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isPremium = false;
  final PremiumFeaturesManager _premiumManager = PremiumFeaturesManager();

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await _premiumManager.isPremium();
      setState(() {
        _isPremium = isPremium;
      });
    } catch (e) {
      print('Error checking premium status: $e');
    }
  }

  // Function to downgrade user to non-premium for testing
  Future<void> _downgradeToNonPremium() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'isPremium': false,
          'subscriptionType': null,
          'premiumExpiryDate': null,
        });
        await _checkPremiumStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User downgraded to non-premium for testing'),
              backgroundColor: Colors.orange.shade600,
            ),
          );
        }
      }
    } catch (e) {
      print('Error downgrading user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // EMERGENCY PAYMENT BANNER FOR NON-PREMIUM USERS
              if (!_isPremium) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade600, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '🔒 SMARTBUDGET IS LOCKED',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You must pay 100 FRW to access any features!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              
              // SUPER PROMINENT PAYMENT BUTTON - IMPOSSIBLE TO MISS
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade400,
                      Colors.orange.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.payment,
                      color: Colors.white,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '💳 PAY HERE - 100 FRW 💳',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click to unlock SmartBudget!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PremiumScreen()),
                          );
                          await _checkPremiumStatus();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          '🔓 CLICK TO PAY NOW!',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // ADDITIONAL PAYMENT OPTIONS FOR NON-PREMIUM USERS
              if (!_isPremium) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.payment, size: 28),
                    label: const Text('💎 Upgrade to Premium - 100 FRW'),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PremiumScreen()),
                      );
                      await _checkPremiumStatus();
                    },
                  ),
                ),
                
                // Test Payment Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.science, size: 24),
                    label: const Text('🧪 Test Payment Options'),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TestPaymentScreen()),
                      );
                      await _checkPremiumStatus();
                    },
                  ),
                ),
                
                // Developer Test Button - Downgrade to Non-Premium
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.bug_report, size: 24),
                    label: const Text('🐛 Test Non-Premium State'),
                    onPressed: _downgradeToNonPremium,
                  ),
                ),
                
                // Premium Features Preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔒 Premium Features (Locked)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem('📊 Advanced Reports & Analytics'),
                      _buildFeatureItem('🎯 Saving Goals & Tracking'),
                      _buildFeatureItem('⏰ Smart Reminders'),
                      _buildFeatureItem('🤖 AI Spending Insights'),
                      _buildFeatureItem('📈 Unlimited Categories'),
                      _buildFeatureItem('🚫 Ad-Free Experience'),
                    ],
                  ),
                ),
              ],
              
              // PREMIUM USER CONTENT
              if (_isPremium) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.blue.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '🎉 You\'re Premium!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All features are unlocked!',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.lock, color: Colors.grey.shade500, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}