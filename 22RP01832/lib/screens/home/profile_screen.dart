import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/book.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isChangingPassword = false;
  bool _showBooksListed = true;
  bool _showBooksBought = true;
  String? _profileImageUrl;
  List<Book> _booksListed = [];
  List<Book> _booksBought = [];
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  String? _editingName;
  bool _isUpdatingName = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userInfo = doc.data();
    final booksListed = await _fetchBooks(uid: user.uid, bought: false);
    final booksBought = await _fetchBooks(uid: user.uid, bought: true);
    // Sort both lists by createdAt descending
    booksListed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    booksBought.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _userInfo = userInfo;
      _profileImageUrl = userInfo?['profileImageUrl'];
      _booksListed = booksListed;
      _booksBought = booksBought;
      _isLoading = false;
    });
  }

  Future<List<Book>> _fetchBooks({
    required String uid,
    required bool bought,
  }) async {
    final query = bought
        ? FirebaseFirestore.instance
              .collection('books')
              .where('buyerId', isEqualTo: uid)
        : FirebaseFirestore.instance
              .collection('books')
              .where('sellerId', isEqualTo: uid);
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Book.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> _pickAndUploadProfileImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null) return;
    setState(() {
      _isUploadingImage = true;
    });
    final url = await _uploadToCloudinary(picked);
    if (url != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileImageUrl': url});
        setState(() {
          _profileImageUrl = url;
        });
        Fluttertoast.showToast(msg: 'Profile picture updated!');
      }
    } else {
      Fluttertoast.showToast(msg: 'Failed to upload image.');
    }
    setState(() {
      _isUploadingImage = false;
    });
  }

  Future<String?> _uploadToCloudinary(XFile image) async {
    const cloudName = 'dwavfe9yo';
    const uploadPreset = 'easyrent_unsigned';
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final bytes = await image.readAsBytes();
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: image.name),
      );
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      return data['secure_url'];
    } else {
      return null;
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text.trim());
      Fluttertoast.showToast(msg: 'Password updated successfully!');
      setState(() {
        _isChangingPassword = false;
      });
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to change password: $e');
    }
  }

  Future<void> _updateName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _isUpdatingName = true;
    });
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'name': newName},
      );
      setState(() {
        _userInfo!['name'] = newName;
        _editingName = null;
      });
      Fluttertoast.showToast(msg: 'Name updated!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update name: $e');
    }
    setState(() {
      _isUpdatingName = false;
    });
  }

  @override
  void dispose() {
    _expandController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: SpinKitWave(color: Color(0xFF9CE800), size: 32)),
      );
    }
    if (user == null || _userInfo == null) {
      return const Scaffold(
        body: Center(child: Text('You must be logged in.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null
                        ? Text(
                            (_userInfo!['name'] ??
                                    _userInfo!['email'] ??
                                    'U')[0]
                                .toUpperCase(),
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingImage
                          ? null
                          : _pickAndUploadProfileImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _userInfo!['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _editingName = _userInfo!['name'] ?? '';
                    });
                    showDialog(
                      context: context,
                      builder: (context) {
                        final controller = TextEditingController(
                          text: _editingName,
                        );
                        return AlertDialog(
                          title: const Text('Edit Name'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: _isUpdatingName
                                  ? null
                                  : () async {
                                      final newName = controller.text.trim();
                                      if (newName.isEmpty) return;
                                      Navigator.of(context).pop();
                                      await _updateName(newName);
                                    },
                              child: _isUpdatingName
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Icon(Icons.edit, size: 20, color: Colors.orange),
                ),
              ],
            ),
            Text(
              _userInfo!['email'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(
                _isChangingPassword ? Icons.expand_less : Icons.lock_outline,
              ),
              label: Text(
                _isChangingPassword
                    ? 'Hide Change Password'
                    : 'Change Password',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  _isChangingPassword = !_isChangingPassword;
                  if (_isChangingPassword) {
                    _expandController.forward();
                  } else {
                    _expandController.reverse();
                  }
                });
              },
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Current Password',
                            ),
                            obscureText: true,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter current password'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'New Password',
                            ),
                            obscureText: true,
                            validator: (v) => v == null || v.length < 6
                                ? 'Password must be at least 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Confirm New Password',
                            ),
                            obscureText: true,
                            validator: (v) => v != _newPasswordController.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                'Update Password',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                initiallyExpanded: _showBooksListed,
                onExpansionChanged: (v) => setState(() => _showBooksListed = v),
                title: const Text(
                  'Books Listed',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  _booksListed.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No books listed.'),
                        )
                      : Column(
                          children: _booksListed
                              .map(
                                (book) => ListTile(
                                  leading: book.imageUrl.isNotEmpty
                                      ? Image.network(
                                          book.imageUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        )
                                      : const CircleAvatar(
                                          child: Icon(Icons.book),
                                        ),
                                  title: Text(book.title),
                                  subtitle: Text(
                                    'Price: ${book.price.toStringAsFixed(2)}',
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                initiallyExpanded: _showBooksBought,
                onExpansionChanged: (v) => setState(() => _showBooksBought = v),
                title: const Text(
                  'Books Bought',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  _booksBought.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No books bought.'),
                        )
                      : Column(
                          children: _booksBought
                              .map(
                                (book) => ListTile(
                                  leading: book.imageUrl.isNotEmpty
                                      ? Image.network(
                                          book.imageUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        )
                                      : const CircleAvatar(
                                          child: Icon(Icons.book),
                                        ),
                                  title: Text(book.title),
                                  subtitle: Text(
                                    'Price: ${book.price.toStringAsFixed(2)}',
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout', style: TextStyle(fontSize: 18)),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
 