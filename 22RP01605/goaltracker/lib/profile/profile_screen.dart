import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../payment/lnpay_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _xpController = TextEditingController();
  final _usernameController = TextEditingController();
  final _telephoneController = TextEditingController();
  bool _loading = false;
  String? _error;
  List<String> _trackedGoals = [];
  bool _editing = false;
  bool _showVerificationCard = false;
  String? _referralCode;
  int _referralCount = 0;
  bool _premium = false;
  String? _phoneForPayment;

  @override
  void initState() {
    super.initState();
    _reloadUserAndLoadProfile();
    _delayedShowVerificationCard();
    _phoneForPayment = _telephoneController.text;
  }

  Future<void> _delayedShowVerificationCard() async {
    setState(() => _showVerificationCard = false);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _showVerificationCard = true);
  }

  Future<void> _reloadUserAndLoadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
    }
    await _loadProfile();
    setState(() {}); // Force rebuild to update verification status
    _delayedShowVerificationCard(); // Restart delay on refresh
  }

  Future<void> _loadProfile() async {
    print('[ProfileScreen] _loadProfile called');
    setState(() => _loading = true);
    final profile = await _profileService.getProfile();
    final user = FirebaseAuth.instance.currentUser;
    if (profile != null) {
      print('[ProfileScreen] Profile loaded: $profile');
      _emailController.text = profile['email'] ?? '';
      _xpController.text = (profile['xp'] ?? 0).toString();
      _usernameController.text = profile['username'] ?? '';
      _telephoneController.text = profile['telephone'] ?? '';
      _trackedGoals = List<String>.from(profile['trackedGoals'] ?? []);
      _referralCode = profile['referralCode'] ?? '';
      _referralCount = profile['referralCount'] ?? 0;
      _premium = profile['premium'] ?? false;
      // --- Sync Firestore email with FirebaseAuth email if different ---
      if (user != null &&
          user.email != null &&
          user.email != profile['email']) {
        print(
          '[ProfileScreen] Syncing Firestore email with FirebaseAuth email: \\${user.email}',
        );
        await _profileService.updateProfile(email: user.email);
        _emailController.text = user.email!;
      }
    } else {
      print('[ProfileScreen] No profile found, creating...');
      if (user != null) {
        await _profileService.createProfile(
          email: user.email ?? '',
          username: '',
          telephone: '',
        );
        final newProfile = await _profileService.getProfile();
        if (newProfile != null) {
          print('[ProfileScreen] Profile created and loaded: $newProfile');
          _emailController.text = newProfile['email'] ?? '';
          _xpController.text = (newProfile['xp'] ?? 0).toString();
          _usernameController.text = newProfile['username'] ?? '';
          _telephoneController.text = newProfile['telephone'] ?? '';
          _trackedGoals = List<String>.from(newProfile['trackedGoals'] ?? []);
        }
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    print('[ProfileScreen] _saveProfile called');
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _profileService.updateProfile(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        telephone: _telephoneController.text.trim(),
        xp: int.tryParse(_xpController.text),
        trackedGoals: _trackedGoals,
        reauthCallback: _reauthenticateAndUpdateEmail,
      );
      print('[ProfileScreen] Profile save requested');
      setState(() => _editing = false);
    } catch (e) {
      setState(() => _error = e.toString());
      print('[ProfileScreen] _saveProfile error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<bool> _reauthenticateAndUpdateEmail(String newEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final currentEmail = user.email ?? '';
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-authenticate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To change your email, please re-enter your password for $currentEmail',
            ),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (result != true) return false;
    final password = controller.text;
    try {
      final cred = EmailAuthProvider.credential(
        email: currentEmail,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      // Do NOT call updateEmail here; let the service handle it with verifyBeforeUpdateEmail
      print('[ProfileScreen] Re-authentication successful');
      return true;
    } catch (e) {
      print('[ProfileScreen] Re-authentication failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Re-authentication failed: $e')));
      return false;
    }
  }

  Future<void> _requestPremiumPayment() async {
    final phone = _telephoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number in your profile.'),
        ),
      );
      return;
    }
    final lnpay = LnPay(
      '6949156a26cafc9d148b0e36158bb005af91b67160f892ed9592cc595eaa818c',
    );
    try {
      final result = await lnpay.requestPayment(
        amount: 5000,
        phone: phone,
        network: 'mtn',
      );
      if (result['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment request sent! You will be upgraded to premium after payment.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${result['response']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print(
      '[ProfileScreen] user.emailVerified: ${user?.emailVerified}, auth email: ${user?.email}, profile email: ${_emailController.text}',
    );
    final emailsMatch = user != null && user.email == _emailController.text;
    final isVerified = user != null && user.emailVerified && emailsMatch;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Verification Status',
            onPressed: _reloadUserAndLoadProfile,
          ),
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!_premium) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Upgrade to Premium (5000 RWF)'),
                          onPressed: _requestPremiumPayment,
                        ),
                      ),
                    ],
                    if (_premium) ...[
                      Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Premium User',
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (isVerified &&
                        _referralCode != null &&
                        _referralCode!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.card_giftcard, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Referral Code: $_referralCode',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copy referral code',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _referralCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Referral code copied!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (isVerified) ...[
                      Row(
                        children: [
                          const Icon(Icons.group, color: Colors.green),
                          const SizedBox(width: 8),
                          Text('Referrals: $_referralCount'),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      enabled: _editing, // Email now editable
                      decoration: const InputDecoration(
                        labelText: 'Profile Email (Firestore)',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter email';
                        // Improved email validation regex
                        final emailRegex = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+ *',
                        );
                        if (!emailRegex.hasMatch(v))
                          return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      enabled: _editing,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter username';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telephoneController,
                      enabled: _editing,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telephone',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter telephone';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _xpController,
                      enabled: _editing,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'XP',
                        prefixIcon: Icon(Icons.star),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter XP';
                        if (int.tryParse(v) == null)
                          return 'XP must be a number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      enabled: _editing,
                      initialValue: _trackedGoals.join(', '),
                      decoration: const InputDecoration(
                        labelText: 'Tracked Goals (comma separated)',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      onChanged: (v) {
                        _trackedGoals = v
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    // --- Email Verification Notice ---
                    if (!isVerified && _showVerificationCard) ...[
                      Card(
                        color: Colors.orange[50],
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Colors.orange,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your email (${user?.email}) is not verified. Please verify your email by (${_emailController.text}) or check span to unlock all features.',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  const gmailUrl = 'https://mail.google.com';
                                  final uri = Uri.parse(gmailUrl);
                                  try {
                                    final launched = await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    if (!launched && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not open Gmail. Please open your email app manually.',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error opening Gmail: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open Gmail'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  if (user != null) {
                                    await user.sendEmailVerification();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Verification email resent!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.email),
                                label: const Text('Resend Verification Email'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_editing)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _loading ? null : _saveProfile,
                            child: const Text('Save'),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    setState(() => _editing = false);
                                    _loadProfile();
                                  },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
