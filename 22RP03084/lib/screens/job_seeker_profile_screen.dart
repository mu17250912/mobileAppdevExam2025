import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../swipe_screen.dart';
import '../../main.dart'; // for kGoldenBrown

class JobSeekerProfileScreen extends StatefulWidget {
  final String userId; // Use email as userId for now
  const JobSeekerProfileScreen({Key? key, required this.userId}) : super(key: key);
  @override
  State<JobSeekerProfileScreen> createState() => _JobSeekerProfileScreenState();
}

class _JobSeekerProfileScreenState extends State<JobSeekerProfileScreen> {
  final _nameController = TextEditingController();
  final _skillsController = TextEditingController();
  final _salaryController = TextEditingController();
  String? _jobType;
  String? _profileImageUrl;
  File? _pickedImage;
  bool _loading = false;
  String? _error;
  String? _success;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() { _loading = true; });
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _skillsController.text = (data['skills'] as List?)?.join(', ') ?? '';
      _salaryController.text = data['salary'] ?? '';
      _jobType = data['jobType'];
      _profileImageUrl = data['profileImageUrl'];
    }
    setState(() { _loading = false; });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() { _loading = true; _error = null; });
    _pickedImage = File(picked.path);
    final bytes = await picked.readAsBytes();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/dr4w30aom/image/upload'),
    );
    request.fields['upload_preset'] = 'tinderjob_preset';
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'profile.jpg'));
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      setState(() {
        _profileImageUrl = data['secure_url'];
        _loading = false;
      });
    } else {
      setState(() {
        _error = 'Failed to upload image.';
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() { _loading = true; _error = null; _success = null; });
    final name = _nameController.text.trim();
    final skills = _skillsController.text.trim().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final salary = _salaryController.text.trim();
    if (name.isEmpty || skills.isEmpty || _jobType == null || salary.isEmpty || _profileImageUrl == null) {
      setState(() {
        _loading = false;
        _error = 'All fields are required, including name and profile picture.';
      });
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
        'name': name,
        'skills': skills,
        'jobType': _jobType,
        'salary': salary,
        'profileImageUrl': _profileImageUrl,
      }, SetOptions(merge: true));
      setState(() {
        _loading = false;
        _success = 'Profile updated!';
        _isEditMode = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to save profile: \\${e.toString()}';
      });
    }
  }

  Widget _buildProfileView() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
      builder: (context, snapshot) {
        String subscriptionStatus = 'Free';
        int messagesSentToday = 0;
        String name = _nameController.text;
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          subscriptionStatus = (data['subscriptionStatus'] ?? '') == 'active' ? 'Subscribed' : 'Free';
          messagesSentToday = data['messagesSentToday'] ?? 0;
          name = data['name'] ?? name;
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
              child: _profileImageUrl == null ? const Icon(Icons.camera_alt, size: 48, color: kGoldenBrown) : null,
            ),
            const SizedBox(height: 16),
            Text('Name: ' + name, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Skills: ${_skillsController.text}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Job Type: ${_jobType ?? ''}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Salary Expectation: ${_salaryController.text}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Divider(),
            Text('Subscription Status: $subscriptionStatus', style: TextStyle(fontSize: 16, color: subscriptionStatus == 'Subscribed' ? Colors.green : Colors.red)),
            Text('Messages Sent Today: $messagesSentToday', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown, foregroundColor: Colors.white),
              onPressed: () => setState(() => _isEditMode = true),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileEdit() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _loading ? null : _pickAndUploadImage,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : _pickedImage != null
                        ? FileImage(_pickedImage!) as ImageProvider
                        : null,
                child: _profileImageUrl == null && _pickedImage == null
                    ? const Icon(Icons.camera_alt, size: 48, color: kGoldenBrown)
                    : null,
              ),
            ),
            if ((_profileImageUrl != null || _pickedImage != null) && !_loading)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _profileImageUrl = null;
                    _pickedImage = null;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person, color: kGoldenBrown),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _skillsController,
          decoration: const InputDecoration(
            labelText: 'Skills (comma separated)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label, color: kGoldenBrown),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _jobType,
          items: const [
            DropdownMenuItem(value: 'Full-time', child: Text('Full-time')),
            DropdownMenuItem(value: 'Freelance', child: Text('Freelance')),
            DropdownMenuItem(value: 'Part-time', child: Text('Part-time')),
          ],
          onChanged: (value) => setState(() => _jobType = value),
          decoration: const InputDecoration(
            labelText: 'Desired Job Type',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work, color: kGoldenBrown),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _salaryController,
          decoration: const InputDecoration(
            labelText: 'Salary Expectation',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money, color: kGoldenBrown),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown, foregroundColor: Colors.white),
              onPressed: _loading ? null : _saveProfile,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: _loading ? null : () => setState(() => _isEditMode = false),
              child: const Text('Cancel', style: TextStyle(color: kGoldenBrown)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skillsController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: kGoldenBrown,
        actions: [
          if (_profileImageUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(_profileImageUrl!),
              ),
            ),
          ],
        ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _isEditMode ? _buildProfileEdit() : _buildProfileView(),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: kGoldenBrown),
              ),
            ),
        ],
      ),
    );
  }
} 