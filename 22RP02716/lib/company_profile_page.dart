import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'applications_page.dart'; // For ApplicationsPage
import 'job_posts_page.dart'; // For JobPostsPage
import 'employer_dashboard.dart'; // For DashboardPage

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({Key? key}) : super(key: key);

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _yearFoundedController = TextEditingController();
  String? _companySize;
  String? _companyType;
  String? _industry;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _officialEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  List<Map<String, dynamic>> _uploadedDocs = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('profile').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['companyName'] ?? '';
      _taglineController.text = data['tagline'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _yearFoundedController.text = data['yearFounded'] ?? '';
      _companySize = data['companySize'];
      _companyType = data['companyType'];
      _industry = data['industry'];
      _addressController.text = data['address'] ?? '';
      _websiteController.text = data['website'] ?? '';
      _officialEmailController.text = data['officialEmail'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _facebookController.text = data['facebook'] ?? '';
      _linkedinController.text = data['linkedin'] ?? '';
      _twitterController.text = data['twitter'] ?? '';
      _instagramController.text = data['instagram'] ?? '';
      _uploadedDocs = List<Map<String, dynamic>>.from(data['documents'] ?? []);
    }
    setState(() {});
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('profile').doc(user.uid).set({
        'companyName': _nameController.text.trim(),
        'tagline': _taglineController.text.trim(),
        'description': _descriptionController.text.trim(),
        'yearFounded': _yearFoundedController.text.trim(),
        'companySize': _companySize,
        'companyType': _companyType,
        'industry': _industry,
        'address': _addressController.text.trim(),
        'website': _websiteController.text.trim(),
        'officialEmail': _officialEmailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'twitter': _twitterController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'documents': _uploadedDocs,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _error = 'Failed to save profile. Please try again.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Company Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Company Name',
                    prefixIcon: const Icon(Icons.business, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter company name' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _taglineController,
                  decoration: InputDecoration(
                    labelText: 'Company Tagline or Motto (optional)',
                    prefixIcon: const Icon(Icons.emoji_objects, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'About the Company / Description',
                    prefixIcon: const Icon(Icons.info_outline, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 4,
                  validator: (value) => value == null || value.isEmpty ? 'Enter company description' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _yearFoundedController,
                  decoration: InputDecoration(
                    labelText: 'Year Founded',
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Enter year founded' : null,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _companySize,
                  decoration: InputDecoration(
                    labelText: 'Company Size',
                    prefixIcon: const Icon(Icons.people, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: '1-10', child: Text('1–10 employees')),
                    DropdownMenuItem(value: '11-50', child: Text('11–50 employees')),
                    DropdownMenuItem(value: '51-200', child: Text('51–200 employees')),
                    DropdownMenuItem(value: '201-500', child: Text('201–500 employees')),
                    DropdownMenuItem(value: '500+', child: Text('500+ employees')),
                  ],
                  onChanged: (value) => setState(() => _companySize = value),
                  validator: (value) => value == null ? 'Select company size' : null,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _companyType,
                  decoration: InputDecoration(
                    labelText: 'Type of Company',
                    prefixIcon: const Icon(Icons.apartment, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Government', child: Text('Government')),
                    DropdownMenuItem(value: 'NGO', child: Text('NGO')),
                    DropdownMenuItem(value: 'Startup', child: Text('Startup')),
                    DropdownMenuItem(value: 'Private Company', child: Text('Private Company')),
                    DropdownMenuItem(value: 'Public Company', child: Text('Public Company')),
                  ],
                  onChanged: (value) => setState(() => _companyType = value),
                  validator: (value) => value == null ? 'Select company type' : null,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _industry,
                  decoration: InputDecoration(
                    labelText: 'Industry/Field',
                    prefixIcon: const Icon(Icons.work, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ICT', child: Text('ICT')),
                    DropdownMenuItem(value: 'Healthcare', child: Text('Healthcare')),
                    DropdownMenuItem(value: 'Education', child: Text('Education')),
                    DropdownMenuItem(value: 'Finance', child: Text('Finance')),
                    DropdownMenuItem(value: 'Agriculture', child: Text('Agriculture')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _industry = value),
                  validator: (value) => value == null ? 'Select industry' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Office/Company Address',
                    prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter address' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _websiteController,
                  decoration: InputDecoration(
                    labelText: 'Company Website',
                    prefixIcon: const Icon(Icons.link, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter website' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _officialEmailController,
                  decoration: InputDecoration(
                    labelText: 'Official Email',
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter official email' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number / WhatsApp (optional)',
                    prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Social Media Links
                TextFormField(
                  controller: _facebookController,
                  decoration: InputDecoration(
                    labelText: 'Facebook (optional)',
                    prefixIcon: const Icon(Icons.facebook, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linkedinController,
                  decoration: InputDecoration(
                    labelText: 'LinkedIn (optional)',
                    prefixIcon: const Icon(Icons.linked_camera, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _twitterController,
                  decoration: InputDecoration(
                    labelText: 'Twitter (optional)',
                    prefixIcon: const Icon(Icons.alternate_email, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instagramController,
                  decoration: InputDecoration(
                    labelText: 'Instagram (optional)',
                    prefixIcon: const Icon(Icons.camera_alt, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Document upload placeholder (UI only, no upload logic)
                Row(
                  children: [
                    const Icon(Icons.upload_file, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Upload Documents (optional):'),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {
                        // TODO: Implement file picker and upload logic
                      },
                      child: const Text('Choose File'),
                    ),
                  ],
                ),
                if (_uploadedDocs.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _uploadedDocs.map((doc) => Text(doc['name'] ?? '', style: const TextStyle(fontSize: 12))).toList(),
                  ),
                const SizedBox(height: 28),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _loading ? null : _saveProfile,
                        child: _loading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Job Posts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ApplicationsPage()),
            );
          } else if (index == 2) {
            // Already on Profile
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const JobPostsPage()),
            );
          } else if (index == 4) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings page coming soon!')),
            );
          }
        },
      ),
    );
  }
} 