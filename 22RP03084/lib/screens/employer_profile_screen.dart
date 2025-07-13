import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../employer_dashboard.dart';
import '../../main.dart'; // for kGoldenBrown

class EmployerProfileScreen extends StatefulWidget {
  final String userId; // Use email as userId for now
  const EmployerProfileScreen({Key? key, required this.userId}) : super(key: key);
  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  final _companyNameController = TextEditingController();
  final _companyDescController = TextEditingController();
  String? _companyLogoUrl;
  File? _pickedLogo;
  // File? _pickedDoc; // Unused
  bool _loading = false;
  // Removed unused _error and _success fields
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
      _companyNameController.text = data['companyName'] ?? '';
      _companyDescController.text = data['companyDescription'] ?? '';
      _companyLogoUrl = data['companyLogoUrl'];
    }
    setState(() { _loading = false; });
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
        setState(() { _loading = true; });
    _pickedLogo = File(picked.path);
    final bytes = await picked.readAsBytes();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/dr4w30aom/image/upload'),
    );
    request.fields['upload_preset'] = 'tinderjob_preset';
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'logo.jpg'));
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      setState(() {
        _companyLogoUrl = data['secure_url'];
        _loading = false;
      });
    } else {
          setState(() {
            // Error handling removed
        _loading = false;
      });
    }
  }

  // Removed unused _pickAndUploadDoc method

  Future<void> _saveProfile() async {
    setState(() { _loading = true; });
    final companyName = _companyNameController.text.trim();
    final companyDesc = _companyDescController.text.trim();
    if (companyName.isEmpty || companyDesc.isEmpty || _companyLogoUrl == null) {
      setState(() {
        _loading = false;
            // Error handling removed
      });
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
        'companyName': companyName,
        'companyDescription': companyDesc,
        'companyLogoUrl': _companyLogoUrl,
      }, SetOptions(merge: true));
      setState(() {
        _loading = false;
            // Success message removed
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => EmployerDashboard(userId: widget.userId)),
      );
    } catch (e) {
      setState(() {
        _loading = false;
            // Error handling removed
      });
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyDescController.dispose();
    super.dispose();
  }

  Widget _buildProfileView() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
      builder: (context, snapshot) {
        String subscriptionStatus = 'Free';
        int messagesSentToday = 0;
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          subscriptionStatus = (data['subscriptionStatus'] ?? '') == 'active' ? 'Subscribed' : 'Free';
          messagesSentToday = data['messagesSentToday'] ?? 0;
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: _companyLogoUrl != null ? NetworkImage(_companyLogoUrl!) : null,
              child: _companyLogoUrl == null ? const Icon(Icons.business, size: 48, color: kGoldenBrown) : null,
            ),
            const SizedBox(height: 16),
            Text('Company Name: ${_companyNameController.text}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Description: ${_companyDescController.text}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Divider(),
            Text('Subscription Status: $subscriptionStatus', style: TextStyle(fontSize: 16, color: subscriptionStatus == 'Subscribed' ? Colors.green : Colors.red)),
            Text('Messages Sent Today: $messagesSentToday', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGoldenBrown,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(color: Colors.white),
              ),
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
              onTap: _loading ? null : _pickAndUploadLogo,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _companyLogoUrl != null
                    ? NetworkImage(_companyLogoUrl!)
                    : _pickedLogo != null
                        ? FileImage(_pickedLogo!) as ImageProvider
                        : null,
                child: _companyLogoUrl == null && _pickedLogo == null
                    ? const Icon(Icons.business, size: 48, color: kGoldenBrown)
                    : null,
              ),
            ),
            if ((_companyLogoUrl != null || _pickedLogo != null) && !_loading)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _companyLogoUrl = null;
                    _pickedLogo = null;
                  });
                },
              ),
          ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _companyNameController,
          decoration: InputDecoration(
                labelText: 'Company Name',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.business, color: kGoldenBrown),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _companyDescController,
          decoration: InputDecoration(
                labelText: 'Company Description',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.description, color: kGoldenBrown),
              ),
              maxLines: 3,
            ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
              onPressed: _loading ? null : _saveProfile,
              child: const Text('Save'),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: _loading ? null : () => setState(() => _isEditMode = false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: kGoldenBrown,
        actions: [
          if (_companyLogoUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(_companyLogoUrl!),
              ),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _isEditMode ? _buildProfileEdit() : _buildProfileView(),
        ),
      ),
    );
  }
} 