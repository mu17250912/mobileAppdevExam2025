import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'booking_history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:async'; // Added for StreamSubscription
import 'notifications_screen.dart';

class TalentDashboardScreen extends StatefulWidget {
  final String name;
  const TalentDashboardScreen({Key? key, required this.name}) : super(key: key);

  @override
  State<TalentDashboardScreen> createState() => _TalentDashboardScreenState();
}

class _TalentDashboardScreenState extends State<TalentDashboardScreen> {
  int _selectedIndex = 0;
  StreamSubscription<QuerySnapshot>? _notifSub; // Added for notifications
  int _unreadCount = 0; // For badge
  bool _hasPoppedUnread = false; // To avoid repeat popups

  @override
  void initState() {
    super.initState();
    _listenForNotifications(); // Added for notifications
  }

  @override
  void dispose() {
    _notifSub?.cancel(); // Added for notifications
    super.dispose();
  }

  void _listenForNotifications() {
    // Added for notifications
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _notifSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        //.orderBy('timestamp', descending: true) // Removed to avoid index
        .snapshots()
        .listen((snapshot) async {
          final unread = snapshot.docs
              .where((doc) => doc['read'] == false)
              .toList();
          setState(() {
            _unreadCount = unread.length;
          });
          if (unread.isNotEmpty && !_hasPoppedUnread) {
            // Sort unread by timestamp descending in Dart if timestamp exists
            unread.sort((a, b) {
              final aTime = a['timestamp'];
              final bTime = b['timestamp'];
              if (aTime is Timestamp && bTime is Timestamp) {
                return bTime.compareTo(aTime);
              }
              return 0;
            });
            final notif = unread.first.data();
            _hasPoppedUnread = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  notif['title'] + ': ' + notif['body'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.deepPurple,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Mark as read',
                  textColor: Colors.white,
                  onPressed: () async {
                    await unread.first.reference.update({'read': true});
                    setState(() {
                      _hasPoppedUnread = false;
                    });
                  },
                ),
              ),
            );
            // Do NOT mark as read automatically here
          }
          if (unread.isEmpty)
            setState(() {
              _hasPoppedUnread = false;
            });
        });
  }

  void _logout() async {
    // Added for logout
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final List<Widget> _tabs = [
      // Dashboard Tab
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.mic_rounded, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 18),
              Text(
                'Welcome, ${widget.name}!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (user != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('talentId', isEqualTo: user.uid)
                      .where('status', isEqualTo: 'completed')
                      .snapshots(),
                  builder: (context, snapshot) {
                    double totalCommission = 0;
                    double totalIncome = 0;
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        totalCommission += (data['commission'] ?? 0).toDouble();
                        totalIncome += (data['payout'] ?? 0).toDouble();
                      }
                    }
                    return Card(
                      color: Colors.deepPurple.withOpacity(0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Commission Paid to Platform',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${totalCommission.toStringAsFixed(0)} RWF',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your Income (Profit)',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${totalIncome.toStringAsFixed(0)} RWF',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      // Transactions Tab
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
        child: user == null
            ? const Center(child: Text('Not logged in.'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('talentId', isEqualTo: user.uid)
                    .where('status', isEqualTo: 'completed')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final bookings = snapshot.data!.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .toList();
                  // Sort by createdAt descending (newest first)
                  bookings.sort((a, b) {
                    final aTimestamp = a['createdAt'];
                    final bTimestamp = b['createdAt'];
                    if (aTimestamp is Timestamp && bTimestamp is Timestamp) {
                      return bTimestamp.compareTo(aTimestamp);
                    }
                    return 0;
                  });
                  if (bookings.isEmpty) {
                    return const Center(child: Text('No transactions yet.'));
                  }
                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, i) {
                      final b = bookings[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            Icons.event_note,
                            color: Colors.deepPurple,
                          ),
                          title: Text(
                            '${b['date'] ?? ''} • ${b['time'] ?? ''}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Event: ${b['eventDetails'] ?? ''}'),
                              Text('Client: ${b['clientEmail'] ?? ''}'),
                              Row(
                                children: [
                                  Text(
                                    'Income: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${b['payout'] ?? 0} RWF',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Commission: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${b['commission'] ?? 0} RWF',
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${b['price'] ?? ''} RWF',
                            style: GoogleFonts.poppins(
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
      // Profile Tab
      TalentProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        title: Text(
          _selectedIndex == 0
              ? 'Talent Dashboard'
              : _selectedIndex == 1
              ? 'Transactions'
              : 'Edit Profile',
          style: GoogleFonts.poppins(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.deepPurple),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(),
                    ),
                  );
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.deepPurple),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class TalentProfileScreen extends StatefulWidget {
  @override
  State<TalentProfileScreen> createState() => _TalentProfileScreenState();
}

class _TalentProfileScreenState extends State<TalentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _talentTypeController = TextEditingController();
  final _contactController = TextEditingController();
  final _priceController = TextEditingController();
  final _moreInfoController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _photoUrl;
  File? _pickedImage;
  Uint8List? _pickedImageBytes; // For web
  bool _showChangePassword = false; // For collapsible password section

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _talentTypeController.text = data['talentType'] ?? '';
      _contactController.text = data['contact'] ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _photoUrl = data['photoUrl'] ?? null;
      _moreInfoController.text = data['moreInfo'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    if (kIsWeb) {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
        });
        await _uploadImageToCloudinaryWeb(bytes);
      }
    } else {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() {
          _pickedImage = File(picked.path);
        });
        await _uploadImageToCloudinary(_pickedImage!);
      }
    }
  }

  Future<void> _uploadImageToCloudinaryWeb(Uint8List bytes) async {
    setState(() => _isLoading = true);
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/dwavfe9yo/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'easyrent_unsigned'
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'profile.jpg'),
      );
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final urlMatch = RegExp(r'"secure_url":"(.*?)"').firstMatch(respStr);
      if (urlMatch != null) {
        final imageUrl = urlMatch.group(1)?.replaceAll(r'\/', '/');
        setState(() => _photoUrl = imageUrl);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && imageUrl != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'photoUrl': imageUrl});
        }
      }
    } else {
      setState(() => _errorMessage = 'Image upload failed.');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _uploadImageToCloudinary(File image) async {
    setState(() => _isLoading = true);
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/dwavfe9yo/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'easyrent_unsigned'
      ..files.add(await http.MultipartFile.fromPath('file', image.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final urlMatch = RegExp(r'"secure_url":"(.*?)"').firstMatch(respStr);
      if (urlMatch != null) {
        final imageUrl = urlMatch.group(1)?.replaceAll(r'\/', '/');
        setState(() => _photoUrl = imageUrl);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && imageUrl != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'photoUrl': imageUrl});
        }
      }
    } else {
      setState(() => _errorMessage = 'Image upload failed.');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Fill all password fields.');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'New passwords do not match.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception('User not found');
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text);
      setState(() => _errorMessage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Password change failed.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'name': _nameController.text.trim(),
            'talentType': _talentTypeController.text.trim(),
            'contact': _contactController.text.trim(),
            'price': _priceController.text.trim(),
            'moreInfo': _moreInfoController.text.trim(),
          });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Image
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: kIsWeb
                            ? (_pickedImageBytes != null
                                  ? MemoryImage(_pickedImageBytes!)
                                  : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                  ? NetworkImage(_photoUrl!) as ImageProvider
                                  : const AssetImage(
                                      'assets/default_avatar.jpg',
                                    ))
                            : _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (_photoUrl != null && _photoUrl!.isNotEmpty)
                            ? NetworkImage(_photoUrl!) as ImageProvider
                            : const AssetImage('assets/default_avatar.jpg'),
                        backgroundColor: Colors.grey[200],
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.deepPurple,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Change Password Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        _showChangePassword
                            ? Icons.expand_less
                            : Icons.lock_outline,
                        color: Colors.deepPurple,
                      ),
                      label: Text(
                        _showChangePassword
                            ? 'Hide Change Password'
                            : 'Change Password',
                      ),
                      onPressed: () {
                        setState(() {
                          _showChangePassword = !_showChangePassword;
                        });
                      },
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    child: _showChangePassword
                        ? Column(
                            children: [
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Change Password',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _currentPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Current Password',
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _newPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'New Password',
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm New Password',
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _changePassword,
                                  child: const Text('Change Password'),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  // Profile fields below
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _talentTypeController,
                    decoration: const InputDecoration(labelText: 'Talent Type'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter talent type' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(labelText: 'Contact'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter contact' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Service Price (RWF)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter price' : null,
                  ),
                  const SizedBox(height: 18),
                  // More Information Section
                  Card(
                    color: Colors.deepPurple.withOpacity(0.04),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.deepPurple.withOpacity(0.15),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'More Information',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _moreInfoController,
                            maxLines: 5,
                            minLines: 3,
                            decoration: InputDecoration(
                              hintText:
                                  'Describe your experience, skills, portfolio, or anything that makes you stand out...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.deepPurple.withOpacity(0.15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
