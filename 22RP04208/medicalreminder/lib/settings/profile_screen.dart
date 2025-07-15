import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../app/analytics_service.dart';
import 'upgrade_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onShowAchievements;
  const ProfileScreen({super.key, this.onShowAchievements});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isPremium = false;
  int _totalMeds = 0;
  int _activeMeds = 0;
  bool _notificationsEnabled = true;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logProfileOpened();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    _nameController.text = data['name'] ?? '';
    _emailController.text = user.email ?? '';
    _ageController.text = data['age']?.toString() ?? '';
    _conditionController.text = data['medicalCondition'] ?? '';
    _isPremium = data['isPremium'] ?? false;
    _profileImageUrl = data['profileImageUrl'];
    // Fetch medication stats
    final meds = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('medications').get();
    _totalMeds = meds.docs.length;
    _activeMeds = meds.docs.where((d) => d['isActive'] == true).length;
    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'medicalCondition': _conditionController.text.trim(),
        'isPremium': _isPremium,
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');
      await storageRef.putData(await pickedFile.readAsBytes());
      final downloadUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profileImageUrl': downloadUrl});
      setState(() {
        _profileImageUrl = downloadUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: ${e.toString()}')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadProfileImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                            ? const Icon(Icons.account_circle, size: 60)
                            : null,
                      ),
                    ),
                    TextButton(
                      onPressed: _pickAndUploadProfileImage,
                      child: const Text('Change Profile Picture'),
                    ),
                    const SizedBox(height: 16),
                    Text('Total Medications: $_totalMeds'),
                    Text('Active Medications: $_activeMeds'),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('Enable Notifications'),
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'GDPR: Your data is securely stored and never shared. You can request deletion at any time.',
                        style: TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Name'),
                            validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ageController,
                            decoration: const InputDecoration(labelText: 'Age (optional)'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _conditionController,
                            decoration: const InputDecoration(labelText: 'Medical Condition'),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Premium (Unlimited Medications)'),
                            value: _isPremium,
                            onChanged: (val) {
                              setState(() => _isPremium = val);
                            },
                          ),
                          const SizedBox(height: 24),
                          if (_error != null) ...[
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                          ],
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) _saveProfile();
                            },
                            child: const Text('Save'),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _logout,
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    ),
                    if (!_isPremium) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                          );
                        },
                        icon: const Icon(Icons.star),
                        label: const Text('Upgrade to Premium'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.onShowAchievements != null)
                      ElevatedButton.icon(
                        onPressed: widget.onShowAchievements,
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('View Achievements'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
} 