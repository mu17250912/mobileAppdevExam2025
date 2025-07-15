import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../payment/payment_tracker.dart';
import '../settings/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final PaymentTracker _paymentTracker = PaymentTracker();
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
  Map<String, dynamic>? _latestPayment;
  String _currentTemplate = 'Elegant Purple';

  @override
  void initState() {
    super.initState();
    _reloadUserAndLoadProfile();
    _delayedShowVerificationCard();
    _phoneForPayment = _telephoneController.text;
    _loadLatestPayment();
    _startPaymentListener();
    _loadTemplate();
  }

  Future<void> _delayedShowVerificationCard() async {
    setState(() => _showVerificationCard = false);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _showVerificationCard = true);
  }

  Future<void> _loadLatestPayment() async {
    try {
      final payment = await _paymentTracker.getLatestPayment();
      if (mounted) {
        setState(() {
          _latestPayment = payment;
        });
      }
    } catch (e) {
      print('[ProfileScreen] Error loading latest payment: $e');
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.error;
      case 'timeout':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'timeout':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Payment Completed';
      case 'processing':
        return 'Payment Processing';
      case 'failed':
        return 'Payment Failed';
      case 'timeout':
        return 'Payment Timeout';
      default:
        return 'Payment Pending';
    }
  }

  void _startPaymentListener() {
    _paymentTracker.getPaymentHistory().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final latestPayment =
            snapshot.docs.first.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _latestPayment = latestPayment;
          });

          // Auto-reload profile if payment is completed
          if (latestPayment['status'] == 'completed') {
            _loadProfile();
          }
        }
      }
    });
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

  Future<void> _loadTemplate() async {
    final template = await ThemeService.getCurrentTemplate();
    setState(() {
      _currentTemplate = template;
    });
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

  Future<Map<String, dynamic>> requestPaymentProxy(
    int amount,
    String phone, {
    required String apiKey,
    String network = 'mtn',
  }) async {
    final url = Uri.parse('https://www.lanari.rw/pay/lnpay/pay_proxy.php');
    final payload = {
      'amount': amount,
      'phone': phone,
      'network': network,
      'apiKey': apiKey,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }

      return {'status': response.statusCode, 'response': decoded};
    } catch (e) {
      return {'status': -1, 'response': 'Network error: $e'};
    }
  }

  void _showPhoneInputDialog() {
    final phoneController = TextEditingController(
      text: _telephoneController.text,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Phone Number'),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
              hintText: 'e.g. 07XXXXXXXX',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final phone = phoneController.text.trim();
                if (phone.isEmpty || phone.length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid phone number.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context); // Close dialog
                await _requestPremiumPayment(phone); // Pass phone to payment
              },
              child: const Text('Pay'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestPremiumPayment(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number in your profile.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      print('[ProfileScreen] Processing payment for phone: $phone');
      await _paymentTracker.processPayment(
        amount: 10000,
        phone: phone,
        network: 'mtn',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment request sent! We will automatically upgrade you to premium once payment is confirmed.',
          ),
        ),
      );

      // Reload profile to check for premium status
      await _loadProfile();
      await _loadLatestPayment();

      // Check if user is now premium
      if (_premium) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Congratulations! You are now a premium user!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment error: $e')));
      debugPrint('PAYMENT ERROR: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templateData = ThemeService.getTemplateData(_currentTemplate);
    final user = FirebaseAuth.instance.currentUser;
    print(
      '[ProfileScreen] user.emailVerified: ${user?.emailVerified}, auth email: ${user?.email}, profile email: ${_emailController.text}',
    );
    final emailsMatch = user != null && user.email == _emailController.text;
    final isVerified = user != null && user.emailVerified && emailsMatch;
    return Scaffold(
      backgroundColor: templateData['backgroundColor'],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: templateData['appBarColor'],
        foregroundColor: Colors.white,
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
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.lock_open),
                              label: const Text(
                                'Upgrade to Premium (10000 RWF)',
                              ),
                              onPressed: _showPhoneInputDialog,
                            ),
                            const SizedBox(height: 8),
                          ],
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
                    if (_latestPayment != null && !_premium) ...[
                      Card(
                        color: Colors.blue[50],
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getPaymentStatusIcon(
                                      _latestPayment!['status'],
                                    ),
                                    color: _getPaymentStatusColor(
                                      _latestPayment!['status'],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Payment Status: ${_getPaymentStatusText(_latestPayment!['status'])}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getPaymentStatusColor(
                                          _latestPayment!['status'],
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 18),
                                    onPressed: () async {
                                      await _loadLatestPayment();
                                      await _loadProfile();
                                    },
                                    tooltip: 'Refresh payment status',
                                  ),
                                ],
                              ),
                              if (_latestPayment!['status'] ==
                                  'processing') ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Please complete the payment to upgrade to premium.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                              if (_latestPayment!['status'] == 'failed' ||
                                  _latestPayment!['status'] == 'timeout') ...[
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => _showPhoneInputDialog(),
                                  child: const Text('Try Again'),
                                ),
                              ],
                              if (_latestPayment!['errorMessage'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Error: ${_latestPayment!['errorMessage']}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (isVerified &&
                        _referralCode != null &&
                        _referralCode!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Referral Code: $_referralCode',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy,
                                    size: 18,
                                    color: Colors.black,
                                  ),
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
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (isVerified) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.group, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Referrals: $_referralCount',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Address',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          enabled: _editing,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: const TextStyle(color: Colors.black54),
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.black,
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter email';
                            final emailRegex = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+ *',
                            );
                            if (!emailRegex.hasMatch(v)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Username',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: _usernameController,
                          enabled: _editing,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Enter your username',
                            hintStyle: const TextStyle(color: Colors.black54),
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Colors.black,
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter username';
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone Number',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: _telephoneController,
                          enabled: _editing,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Enter your phone number',
                            hintStyle: const TextStyle(color: Colors.black54),
                            prefixIcon: const Icon(
                              Icons.phone,
                              color: Colors.black,
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter phone number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'XP',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: _xpController,
                          enabled: _editing,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Enter your XP',
                            hintStyle: const TextStyle(color: Colors.black54),
                            prefixIcon: const Icon(
                              Icons.star,
                              color: Colors.black,
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter XP';
                            if (int.tryParse(v) == null) {
                              return 'XP must be a number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tracked Goals',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 6),
                        TextFormField(
                          enabled: _editing,
                          initialValue: _trackedGoals.join(', '),
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Enter tracked goals (comma separated)',
                            hintStyle: const TextStyle(color: Colors.black54),
                            prefixIcon: const Icon(
                              Icons.flag,
                              color: Colors.black,
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (v) {
                            _trackedGoals = v
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                          },
                        ),
                      ],
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
