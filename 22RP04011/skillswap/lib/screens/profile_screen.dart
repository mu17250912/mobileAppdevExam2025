import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import './add_skill_screen.dart';
import '../services/app_service.dart';
import '../models/skill_model.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();

  User? _user;
  Map<String, dynamic>? _userData;
  List<Skill> _userSkills = [];
  Set<String> _selectedSkillIds = {};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _error;
  File? _imageFile;
  XFile? _pickedImage;
  bool _isUploadingPhoto = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSubscription();
    _user = _auth.currentUser;
    _loadUserData();
    _checkPermissions();
  }

  Future<void> _checkSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    final subscriptionStatus = data?['subscriptionStatus'] as String?;
    final subscriptionExpiry = data?['subscriptionExpiry'] as Timestamp?;
    bool hasActiveSubscription = false;
    if (subscriptionStatus == 'active' && subscriptionExpiry != null) {
      final expiryDate = subscriptionExpiry.toDate();
      hasActiveSubscription = expiryDate.isAfter(DateTime.now());
    }
    if (!hasActiveSubscription && mounted) {
      Navigator.pushReplacementNamed(context, '/subscription');
    }
  }

  List<dynamic> get _badges => _userData?['badges'] ?? [];

  Future<void> _checkPermissions() async {
    if (_user == null) return;

    try {
      final hasPermissions = await AppService.checkSkillPermissions(_user!.uid);
      if (!hasPermissions && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission issue detected. Please check Firebase security rules deployment.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          _nameController.text = _userData?['fullName'] ?? '';
          _phoneController.text = _userData?['phone'] ?? '';
          _locationController.text = _userData?['location'] ?? '';
        });
        await _loadUserSkills();
      }
    } catch (e) {
      setState(() => _error =
          'Failed to load profile. Please check your connection or permissions.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserSkills() async {
    if (_user == null) return;
    try {
      final skills = await AppService.getUserSkills(_user!.uid);
      if (!mounted) return;
      setState(() {
        _userSkills = skills;
        _selectedSkillIds.clear(); // Clear selections when reloading
      });
    } catch (e) {
      debugPrint('Error loading user skills: $e');
      if (!mounted) return;
      setState(() {
        _userSkills = [];
        _selectedSkillIds.clear();
      });
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load skills: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleSkillSelection(String skillId) {
    setState(() {
      if (_selectedSkillIds.contains(skillId)) {
        _selectedSkillIds.remove(skillId);
      } else {
        _selectedSkillIds.add(skillId);
      }
    });
  }

  void _selectAllSkills() {
    setState(() {
      if (_selectedSkillIds.length == _userSkills.length) {
        _selectedSkillIds.clear();
      } else {
        _selectedSkillIds = _userSkills.map((skill) => skill.id).toSet();
      }
    });
  }

  Future<void> _toggleSkillActivation(Skill skill) async {
    try {
      final updatedSkill = skill.copyWith(
        isActive: !skill.isActive,
        updatedAt: DateTime.now(),
      );

      final success = await AppService.updateSkill(updatedSkill);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Skill "${skill.name}" ${skill.isActive ? 'deactivated' : 'activated'} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserSkills();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to update skill. Please check your permissions and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error toggling skill activation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating skill: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSelectedSkills() async {
    if (_selectedSkillIds.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Skills'),
        content: Text(
          'Are you sure you want to delete ${_selectedSkillIds.length} skill${_selectedSkillIds.length == 1 ? '' : 's'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() => _isLoading = true);

      try {
        bool allDeleted = true;
        for (final skillId in _selectedSkillIds) {
          final success = await AppService.deleteSkill(skillId);
          if (!success) {
            allDeleted = false;
            break;
          }
        }

        if (allDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully deleted ${_selectedSkillIds.length} skill${_selectedSkillIds.length == 1 ? '' : 's'}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _selectedSkillIds.clear();
          await _loadUserSkills();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Failed to delete some skills. Please check your permissions and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _imageFile = null;
      if (_userData != null) _userData!['photoUrl'] = null;
    });
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update({'photoUrl': null});
    } catch (e) {
      setState(() =>
          _error = 'Failed to remove image. Please check your permissions.');
    }
  }

  Future<String?> _uploadImage(File file) async {
    setState(() => _isUploadingImage = true);
    try {
      final ref = _storage.ref().child('profile_pics/${_user!.uid}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      setState(() => _isUploadingImage = false);
      return url;
    } catch (e) {
      setState(() {
        _error =
            'Failed to upload image. Please check your connection or permissions.';
        _isUploadingImage = false;
      });
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    String? photoUrl = _userData?['photoUrl'];
    if (_imageFile != null) {
      final url = await _uploadImage(_imageFile!);
      if (url != null) photoUrl = url;
    }
    try {
      // Read current user data from Firestore
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      final current = doc.exists ? UserDetails.fromFirestore(doc) : null;
      if (current == null) throw Exception('User not found');
      final updated = current.copyWith(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(_user!.uid).set(
            updated.toFirestore(),
            SetOptions(merge: true),
          );
      setState(() {
        _userData?['fullName'] = _nameController.text.trim();
        _userData?['phone'] = _phoneController.text.trim();
        _userData?['location'] = _locationController.text.trim();
        _userData?['photoUrl'] = photoUrl;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated!')));
    } catch (e) {
      setState(() => _error =
          'Failed to save profile. Please check your connection or permissions.');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _isUploadingPhoto = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final storageRef =
          FirebaseStorage.instance.ref().child('profile_pics/${user.uid}.jpg');
      await storageRef.putData(await picked.readAsBytes());
      final url = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': url});
      setState(() {
        _pickedImage = picked;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')));
      _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update photo: $e')));
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.grey[50],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue[800]),
                    const SizedBox(width: 8),
                    Text('Edit Profile',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800])),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(thickness: 1, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter phone' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter location' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () async {
                              await _saveProfile();
                              if (mounted) Navigator.pop(context);
                            },
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text('You are not logged in.'));
    }

    final photoUrl =
        _imageFile != null ? null : (_userData?['photoUrl'] as String?);
    final String name = _userData?['fullName'] ?? 'User';
    final String title = _userData?['title'] ?? 'SkillSwap User';
    final String location = _userData?['location'] ?? 'Unknown';
    final int sessions = _userData?['sessions'] ?? 0;
    final double ratings = (_userData?['ratings'] ?? 0).toDouble();

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Profile'),
      //   backgroundColor: Colors.blue[800],
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      // ),
      // Removed FloatingActionButton.extended (Add Skill button)
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Card
                    _buildUserInfoCard(
                        name, title, location, sessions, ratings),
                    const SizedBox(height: 24),

                    // My Skills Section
                    _buildSkillsSection(),
                    const SizedBox(height: 24),

                    // Achievement Badges Section
                    _buildBadgesSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    ); // closes Scaffold
  }

  Widget _buildUserInfoCard(String name, String title, String location,
      int sessions, double ratings) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: _pickedImage != null
                        ? FileImage(File(_pickedImage!.path))
                        : (_userData?['photoUrl'] != null &&
                                (_userData?['photoUrl'] as String).isNotEmpty)
                            ? NetworkImage(_userData?['photoUrl'])
                                as ImageProvider<Object>
                            : null,
                    child: (_pickedImage == null &&
                            (_userData?['photoUrl'] == null ||
                                (_userData?['photoUrl'] as String).isEmpty))
                        ? const Icon(Icons.person,
                            size: 36, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _pickAndUploadImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[800],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white)))
                            : const Icon(Icons.camera_alt,
                                color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 18),
                const SizedBox(width: 4),
                Text(location, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoStat('$sessions', 'Sessions', Colors.red),
                _infoStat(ratings.toStringAsFixed(1), 'Ratings', Colors.blue),
                _infoStat('${_badges.length}', 'Badges', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Skills',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (_userSkills.isNotEmpty) ...[
              Row(
                children: [
                  if (_selectedSkillIds.isNotEmpty)
                    TextButton.icon(
                      onPressed: _deleteSelectedSkills,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: Text(
                        'Delete (${_selectedSkillIds.length})',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: _selectAllSkills,
                    icon: Icon(
                      _selectedSkillIds.length == _userSkills.length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                    label: Text(
                      _selectedSkillIds.length == _userSkills.length
                          ? 'Deselect All'
                          : 'Select All',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (_userSkills.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'No skills added yet. Add skills from the main menu to get started!',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddSkillScreen()),
                    );
                    if (result == true) {
                      _loadUserData();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your First Skill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          ..._userSkills.map((skill) => _buildSkillCard(skill)),
      ],
    );
  }

  Widget _buildBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievement Badges',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        StreamBuilder<DocumentSnapshot>(
          stream: _user != null
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user!.uid)
                  .snapshots()
              : const Stream.empty(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final badges = data?['badges'] ?? [];
            if (badges.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No badges yet. Complete sessions and activities to earn badges!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: badges.map<Widget>((badge) {
                final String name = badge['name'] ?? '';
                final String desc = badge['description'] ?? '';
                final String icon = badge['icon'] ?? 'star';
                final IconData iconData = _getBadgeIcon(icon);
                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(name),
                        content: Text(desc.isNotEmpty
                            ? desc
                            : 'No description available.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconData, size: 32, color: Colors.amber[700]),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (desc.isNotEmpty)
                          Text(
                            desc,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
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

  Widget _infoStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildSkillCard(Skill skill) {
    final isSelected = _selectedSkillIds.contains(skill.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedSkillIds.isNotEmpty)
              Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleSkillSelection(skill.id),
                activeColor: Colors.blue[600],
              ),
            CircleAvatar(
              backgroundColor: skill.difficultyColor.withOpacity(0.1),
              child: Icon(skill.categoryIcon, color: skill.difficultyColor),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                skill.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  decoration:
                      skill.isActive ? null : TextDecoration.lineThrough,
                  color: skill.isActive ? null : Colors.grey[600],
                ),
              ),
            ),
            if (!skill.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(skill.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: skill.difficultyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    skill.difficulty,
                    style: TextStyle(
                      color: skill.difficultyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (skill.hourlyRate > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      skill.formattedHourlyRate,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          onSelected: (value) async {
            if (value == 'edit') {
              // Navigate to edit skill screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddSkillScreen(skillToEdit: skill),
                ),
              );
              if (result == true) {
                _loadUserData();
              }
            } else if (value == 'toggle') {
              // Toggle skill activation
              await _toggleSkillActivation(skill);
            } else if (value == 'delete') {
              // Show delete confirmation dialog
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Skill'),
                  content: Text(
                      'Are you sure you want to delete "${skill.name}"? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (shouldDelete == true) {
                // Delete the skill
                final success = await AppService.deleteSkill(skill.id);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Skill "${skill.name}" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadUserData(); // Reload skills
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Failed to delete skill. Please check your permissions and try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    skill.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: skill.isActive ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    skill.isActive ? 'Deactivate' : 'Activate',
                    style: TextStyle(
                      color: skill.isActive ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBadgeIcon(String icon) {
    switch (icon) {
      case 'star':
        return Icons.star;
      case 'medal':
        return Icons.emoji_events;
      case 'fire':
        return Icons.local_fire_department;
      case 'rocket':
        return Icons.rocket_launch;
      default:
        return Icons.emoji_events;
    }
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: _oldPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text.trim());
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Failed to change password.');
    } catch (e) {
      setState(() => _error = 'Failed to change password.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter current password' : null,
            ),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Min 6 characters' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _changePassword,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Change'),
        ),
      ],
    );
  }
}
