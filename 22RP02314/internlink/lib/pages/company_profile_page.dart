import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/internship_service.dart';
import '../services/application_service.dart';
import '../company_home_page.dart';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({Key? key}) : super(key: key);

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();
  final TextEditingController _companyWebsiteController = TextEditingController();
  final TextEditingController _companyDescriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  int _postedCount = 0;
  int _applicationsCount = 0;
  int _interviewsCount = 0;
  final InternshipService _internshipService = InternshipService();
  final ApplicationService _applicationService = ApplicationService();

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
    _loadCompanyStats();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyWebsiteController.dispose();
    _companyDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _companyNameController.text = data['companyName'] ?? '';
          _companyAddressController.text = data['companyAddress'] ?? '';
          _companyWebsiteController.text = data['companyWebsite'] ?? '';
          _companyDescriptionController.text = data['companyDescription'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load company data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCompanyData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'companyName': _companyNameController.text.trim(),
        'companyAddress': _companyAddressController.text.trim(),
        'companyWebsite': _companyWebsiteController.text.trim(),
        'companyDescription': _companyDescriptionController.text.trim(),
      });

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCompanyStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Internships posted
    _internshipService.getCompanyInternships(user.uid).first.then((internships) {
      setState(() {
        _postedCount = internships.length;
      });
    });
    // Applications and interviews
    _applicationService.getCompanyApplications(user.uid).first.then((applications) {
      setState(() {
        _applicationsCount = applications.length;
        _interviewsCount = applications.where((a) => a.status == 'approved').length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CompanyHomePage()),
              (route) => false,
            );
          },
        ),
        title: const Text('Company Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Logo Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: const Icon(
                        Icons.business,
                        size: 50,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isEditing)
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement logo upload
                        },
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Logo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Company Information
              const Text(
                'Company Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name *',
                  border: OutlineInputBorder(),
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter company name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _companyAddressController,
                decoration: const InputDecoration(
                  labelText: 'Company Address',
                  border: OutlineInputBorder(),
                ),
                enabled: _isEditing,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _companyWebsiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
                  hintText: 'https://www.example.com',
                ),
                enabled: _isEditing,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _companyDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Company Description',
                  border: OutlineInputBorder(),
                  hintText: 'Tell us about your company...',
                ),
                enabled: _isEditing,
                maxLines: 4,
              ),
              
              const SizedBox(height: 32),
              
              // Statistics Card
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Company Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.work,
                            label: 'Posted',
                            value: _postedCount.toString(),
                          ),
                          _StatItem(
                            icon: Icons.people,
                            label: 'Applications',
                            value: _applicationsCount.toString(),
                          ),
                          _StatItem(
                            icon: Icons.check_circle,
                            label: 'Interviews',
                            value: _interviewsCount.toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                          });
                          _loadCompanyData(); // Reset to original values
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveCompanyData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
} 