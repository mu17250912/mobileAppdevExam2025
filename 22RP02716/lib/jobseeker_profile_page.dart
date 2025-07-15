import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Uncomment when implementing file upload
import 'jobseeker_dashboard.dart';

class JobseekerProfilePage extends StatefulWidget {
  const JobseekerProfilePage({Key? key}) : super(key: key);

  @override
  State<JobseekerProfilePage> createState() => _JobseekerProfilePageState();
}

class _JobseekerProfilePageState extends State<JobseekerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _gender;
  final TextEditingController _locationController = TextEditingController();
  String? _domain; // Add domain field
  final TextEditingController _otherDomainController = TextEditingController(); // Add other domain controller
  List<Map<String, dynamic>> _education = [];
  List<Map<String, dynamic>> _experience = [];
  List<String> _skills = [];
  List<Map<String, String>> _languages = [];
  final TextEditingController _aboutController = TextEditingController();
  String? _preferredJobType;
  final TextEditingController _portfolioController = TextEditingController();
  String? _profilePicUrl;
  String? _cvUrl;
  bool _publicProfile = true;
  bool _loading = false;
  String? _error;
  final TextEditingController _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() { _loading = true; });
    
    try {
      _emailController.text = user.email ?? '';
      
      // Autofill full name from users collection if available
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData != null && (userData['name'] ?? '').toString().isNotEmpty) {
        _fullNameController.text = userData['name'];
      }
      
      // Load profile data from jobseeker_profiles collection
      final doc = await FirebaseFirestore.instance.collection('jobseeker_profiles').doc(user.uid).get();
      final data = doc.data();
      
      if (data != null) {
        print('Loading profile data: $data'); // Debug print
        
        if ((data['fullName'] ?? '').toString().isNotEmpty) {
          _fullNameController.text = data['fullName'];
        }
        _phoneController.text = data['phone'] ?? '';
        _dobController.text = data['dob'] ?? '';
        _gender = data['gender'];
        _locationController.text = data['location'] ?? '';
        _domain = data['domain']; // Load domain
        _otherDomainController.text = data['otherDomain'] ?? ''; // Load other domain
        
        // Load multiple entry fields with proper error handling
        if (data['education'] != null) {
          try {
            _education = List<Map<String, dynamic>>.from(data['education']);
            print('Loaded education: $_education'); // Debug print
          } catch (e) {
            print('Error loading education: $e');
            _education = [];
          }
        } else {
          _education = [];
        }
        
        if (data['experience'] != null) {
          try {
            _experience = List<Map<String, dynamic>>.from(data['experience']);
            print('Loaded experience: $_experience'); // Debug print
          } catch (e) {
            print('Error loading experience: $e');
            _experience = [];
          }
        } else {
          _experience = [];
        }
        
        if (data['skills'] != null) {
          try {
            _skills = List<String>.from(data['skills']);
            print('Loaded skills: $_skills'); // Debug print
          } catch (e) {
            print('Error loading skills: $e');
            _skills = [];
          }
        } else {
          _skills = [];
        }
        
        if (data['languages'] != null) {
          try {
            // Handle the LinkedMap<String, dynamic> from Firestore
            final languagesData = data['languages'] as List;
            _languages = languagesData.map((lang) {
              if (lang is Map) {
                return {
                  'name': lang['name']?.toString() ?? '',
                  'level': lang['level']?.toString() ?? '',
                };
              }
              return {'name': '', 'level': ''};
            }).toList();
            print('Loaded languages: $_languages'); // Debug print
          } catch (e) {
            print('Error loading languages: $e');
            _languages = [];
          }
        } else {
          _languages = [];
        }
        
        _aboutController.text = data['about'] ?? '';
        _preferredJobType = data['preferredJobType'];
        _portfolioController.text = data['portfolio'] ?? '';
        _profilePicUrl = data['profilePicUrl'];
        _cvUrl = data['cvUrl'];
        _publicProfile = data['publicProfile'] ?? true;
        _imageUrlController.text = data['imageUrl'] ?? '';
      } else {
        print('No profile data found for user: ${user.uid}');
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() { _error = 'Failed to load profile data. Please try again.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('jobseeker_profiles').doc(user.uid).set({
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _gender,
        'location': _locationController.text.trim(),
        'domain': _domain, // Save domain
        'otherDomain': _otherDomainController.text.trim(), // Save other domain
        'education': _education,
        'experience': _experience,
        'skills': _skills,
        'languages': _languages,
        'about': _aboutController.text.trim(),
        'preferredJobType': _preferredJobType,
        'portfolio': _portfolioController.text.trim(),
        'profilePicUrl': _profilePicUrl,
        'cvUrl': _cvUrl,
        'publicProfile': _publicProfile,
        'imageUrl': _imageUrlController.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _error = 'Failed to save profile. Please try again.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  // Helper: Add Education Dialog
  Future<void> _showAddEducationDialog() async {
    final degreeController = TextEditingController();
    final institutionController = TextEditingController();
    final startYearController = TextEditingController();
    final endYearController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Education'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: degreeController,
                decoration: const InputDecoration(labelText: 'Degree'),
                validator: (v) => v == null || v.isEmpty ? 'Enter degree' : null,
              ),
              TextFormField(
                controller: institutionController,
                decoration: const InputDecoration(labelText: 'Institution'),
                validator: (v) => v == null || v.isEmpty ? 'Enter institution' : null,
              ),
              TextFormField(
                controller: startYearController,
                decoration: const InputDecoration(labelText: 'Start Year'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter start year' : null,
              ),
              TextFormField(
                controller: endYearController,
                decoration: const InputDecoration(labelText: 'End Year'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter end year' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'degree': degreeController.text.trim(),
                  'institution': institutionController.text.trim(),
                  'start_year': startYearController.text.trim(),
                  'end_year': endYearController.text.trim(),
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _education.add(result));
    }
  }

  // Helper: Add Experience Dialog
  Future<void> _showAddExperienceDialog() async {
    final positionController = TextEditingController();
    final companyController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Experience'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: positionController,
                decoration: const InputDecoration(labelText: 'Position'),
                validator: (v) => v == null || v.isEmpty ? 'Enter position' : null,
              ),
              TextFormField(
                controller: companyController,
                decoration: const InputDecoration(labelText: 'Company'),
                validator: (v) => v == null || v.isEmpty ? 'Enter company' : null,
              ),
              TextFormField(
                controller: startDateController,
                decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM)'),
                validator: (v) => v == null || v.isEmpty ? 'Enter start date' : null,
              ),
              TextFormField(
                controller: endDateController,
                decoration: const InputDecoration(labelText: 'End Date (YYYY-MM or Present)'),
                validator: (v) => v == null || v.isEmpty ? 'Enter end date' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'position': positionController.text.trim(),
                  'company': companyController.text.trim(),
                  'start_date': startDateController.text.trim(),
                  'end_date': endDateController.text.trim(),
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _experience.add(result));
    }
  }

  // Helper: Add Skill Dialog
  Future<void> _showAddSkillDialog() async {
    final skillController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Skill'),
        content: TextField(
          controller: skillController,
          decoration: const InputDecoration(labelText: 'Skill'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (skillController.text.trim().isNotEmpty) {
                Navigator.pop(context, skillController.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null && !_skills.contains(result)) {
      setState(() => _skills.add(result));
    }
  }

  // Helper: Add Language Dialog
  Future<void> _showAddLanguageDialog() async {
    final nameController = TextEditingController();
    String? level;
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Language'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Language'),
                validator: (v) => v == null || v.isEmpty ? 'Enter language' : null,
              ),
              DropdownButtonFormField<String>(
                value: level,
                decoration: const InputDecoration(labelText: 'Proficiency'),
                items: const [
                  DropdownMenuItem(value: 'Basic', child: Text('Basic')),
                  DropdownMenuItem(value: 'Conversational', child: Text('Conversational')),
                  DropdownMenuItem(value: 'Fluent', child: Text('Fluent')),
                  DropdownMenuItem(value: 'Native', child: Text('Native')),
                ],
                onChanged: (v) => level = v,
                validator: (v) => v == null ? 'Select proficiency' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'level': level ?? '',
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _languages.add(result));
    }
  }

  // Helper: Edit Education Dialog
  Future<void> _showEditEducationDialog(Map<String, dynamic> education, int index) async {
    final degreeController = TextEditingController(text: education['degree']);
    final institutionController = TextEditingController(text: education['institution']);
    final startYearController = TextEditingController(text: education['start_year']);
    final endYearController = TextEditingController(text: education['end_year']);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Education'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: degreeController,
                decoration: const InputDecoration(labelText: 'Degree'),
                validator: (v) => v == null || v.isEmpty ? 'Enter degree' : null,
              ),
              TextFormField(
                controller: institutionController,
                decoration: const InputDecoration(labelText: 'Institution'),
                validator: (v) => v == null || v.isEmpty ? 'Enter institution' : null,
              ),
              TextFormField(
                controller: startYearController,
                decoration: const InputDecoration(labelText: 'Start Year'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter start year' : null,
              ),
              TextFormField(
                controller: endYearController,
                decoration: const InputDecoration(labelText: 'End Year'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter end year' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'degree': degreeController.text.trim(),
                  'institution': institutionController.text.trim(),
                  'start_year': startYearController.text.trim(),
                  'end_year': endYearController.text.trim(),
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _education[index] = result);
    }
  }

  // Helper: Edit Experience Dialog
  Future<void> _showEditExperienceDialog(Map<String, dynamic> experience, int index) async {
    final positionController = TextEditingController(text: experience['position']);
    final companyController = TextEditingController(text: experience['company']);
    final startDateController = TextEditingController(text: experience['start_date']);
    final endDateController = TextEditingController(text: experience['end_date']);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Experience'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: positionController,
                decoration: const InputDecoration(labelText: 'Position'),
                validator: (v) => v == null || v.isEmpty ? 'Enter position' : null,
              ),
              TextFormField(
                controller: companyController,
                decoration: const InputDecoration(labelText: 'Company'),
                validator: (v) => v == null || v.isEmpty ? 'Enter company' : null,
              ),
              TextFormField(
                controller: startDateController,
                decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM)'),
                validator: (v) => v == null || v.isEmpty ? 'Enter start date' : null,
              ),
              TextFormField(
                controller: endDateController,
                decoration: const InputDecoration(labelText: 'End Date (YYYY-MM or Present)'),
                validator: (v) => v == null || v.isEmpty ? 'Enter end date' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'position': positionController.text.trim(),
                  'company': companyController.text.trim(),
                  'start_date': startDateController.text.trim(),
                  'end_date': endDateController.text.trim(),
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _experience[index] = result);
    }
  }

  // Helper: Edit Skill Dialog
  Future<void> _showEditSkillDialog(String skill, int index) async {
    final skillController = TextEditingController(text: skill);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Skill'),
        content: TextField(
          controller: skillController,
          decoration: const InputDecoration(labelText: 'Skill'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (skillController.text.trim().isNotEmpty) {
                Navigator.pop(context, skillController.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _skills[index] = result);
    }
  }

  // Helper: Edit Language Dialog
  Future<void> _showEditLanguageDialog(Map<String, String> language, int index) async {
    final nameController = TextEditingController(text: language['name']);
    String? level = language['level'];
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Language'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Language'),
                validator: (v) => v == null || v.isEmpty ? 'Enter language' : null,
              ),
              DropdownButtonFormField<String>(
                value: level,
                decoration: const InputDecoration(labelText: 'Proficiency'),
                items: const [
                  DropdownMenuItem(value: 'Basic', child: Text('Basic')),
                  DropdownMenuItem(value: 'Conversational', child: Text('Conversational')),
                  DropdownMenuItem(value: 'Fluent', child: Text('Fluent')),
                  DropdownMenuItem(value: 'Native', child: Text('Native')),
                ],
                onChanged: (v) => level = v,
                validator: (v) => v == null ? 'Select proficiency' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'level': level ?? '',
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _languages[index] = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: (_imageUrlController.text.isNotEmpty)
                        ? NetworkImage(_imageUrlController.text)
                        : (_profilePicUrl != null ? NetworkImage(_profilePicUrl!) : null),
                      child: (_imageUrlController.text.isEmpty && _profilePicUrl == null)
                        ? const Icon(Icons.person, size: 48) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.blue),
                        onPressed: () {
                          // TODO: Implement profile picture upload
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  prefixIcon: Icon(Icons.image, color: Colors.blue),
                  filled: true,
                  fillColor: Color(0xFFF6F8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person, color: Colors.blue),
                  filled: true,
                  fillColor: Color(0xFFF6F8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email, color: Colors.blue),
                  filled: true,
                  fillColor: Color(0xFFF6F8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (optional)',
                  prefixIcon: Icon(Icons.phone, color: Colors.blue),
                  filled: true,
                  fillColor: Color(0xFFF6F8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (optional)',
                  prefixIcon: Icon(Icons.cake, color: Colors.blue),
                  filled: true,
                  fillColor: Color(0xFFF6F8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                ),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    _dobController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}' ;
                  }
                },
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc, color: Colors.blue),
                  filled: true,
                  fillColor: Color(0xFFF6F8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                ],
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (City/District/Sector)',
                  prefixIcon: Icon(Icons.location_on, color: Colors.blue),
                  filled: true,
                  fillColor: Color(0xFFF6F8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Domain/Industry/Field
              DropdownButtonFormField<String>(
                value: _domain,
                decoration: const InputDecoration(
                  labelText: 'Domain/Industry/Field',
                  prefixIcon: Icon(Icons.business, color: Colors.blue),
                  filled: true,
                  fillColor: Color(0xFFF6F8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
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
                onChanged: (value) {
                  setState(() {
                    _domain = value;
                    _otherDomainController.clear(); // Clear other domain field if "Others" is selected
                  });
                },
                validator: (value) => value == null ? 'Select your domain/industry/field' : null,
              ),
              if (_domain == 'Other')
                TextFormField(
                  controller: _otherDomainController,
                  decoration: const InputDecoration(
                    labelText: 'Specify your domain',
                    prefixIcon: Icon(Icons.business, color: Colors.blue),
                    filled: true,
                    fillColor: Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter your domain' : null,
                ),
              const SizedBox(height: 18),
              // Education Background
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Education Background', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: _showAddEducationDialog,
                  ),
                ],
              ),
              if (_education.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.school, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No education entries yet. Click + to add your education.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                ..._education.asMap().entries.map((entry) {
                  final index = entry.key;
                  final edu = entry.value;
                  return ListTile(
                    title: Text('${edu['degree']} at ${edu['institution']}'),
                    subtitle: Text('${edu['start_year']} - ${edu['end_year']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditEducationDialog(edu, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() { _education.removeAt(index); });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 18),
              // Work Experience
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Work Experience', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: _showAddExperienceDialog,
                  ),
                ],
              ),
              if (_experience.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.work, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No work experience yet. Click + to add your experience.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                ..._experience.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exp = entry.value;
                  return ListTile(
                    title: Text('${exp['position']} at ${exp['company']}'),
                    subtitle: Text('${exp['start_date']} - ${exp['end_date']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditExperienceDialog(exp, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() { _experience.removeAt(index); });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 18),
              // Skills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: _showAddSkillDialog,
                  ),
                ],
              ),
              if (_skills.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No skills yet. Click + to add your skills.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  children: _skills.asMap().entries.map((entry) {
                    final index = entry.key;
                    final skill = entry.value;
                    return Chip(
                      label: Text(skill),
                      onDeleted: () {
                        setState(() { _skills.removeAt(index); });
                      },
                      deleteIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _showEditSkillDialog(skill, index),
                            child: const Icon(Icons.edit, size: 16, color: Colors.blue),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.close, size: 16),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 18),
              // Languages
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Languages', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: _showAddLanguageDialog,
                  ),
                ],
              ),
              if (_languages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.language, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No languages yet. Click + to add your languages.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                ..._languages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lang = entry.value;
                  return ListTile(
                    title: Text(lang['name'] ?? ''),
                    subtitle: Text(lang['level'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditLanguageDialog(lang, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() { _languages.removeAt(index); });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 18),
              TextFormField(
                controller: _aboutController,
                decoration: const InputDecoration(
                  labelText: 'Personal Summary / About Me',
                  prefixIcon: Icon(Icons.info_outline, color: Colors.blue),
                  filled: true,
                  fillColor: Color(0xFFF6F8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: _preferredJobType,
                decoration: const InputDecoration(
                  labelText: 'Preferred Job Type',
                  prefixIcon: Icon(Icons.work_outline, color: Colors.blue),
                  filled: true,
                  fillColor: Color(0xFFF6F8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Full-Time', child: Text('Full-Time')),
                  DropdownMenuItem(value: 'Part-Time', child: Text('Part-Time')),
                  DropdownMenuItem(value: 'Internship', child: Text('Internship')),
                  DropdownMenuItem(value: 'Freelance', child: Text('Freelance')),
                ],
                onChanged: (value) => setState(() => _preferredJobType = value),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _portfolioController,
                decoration: const InputDecoration(
                  labelText: 'Portfolio / Website Link (optional)',
                  prefixIcon: Icon(Icons.link, color: Colors.blue),
                  filled: true,
                  fillColor: Color(0xFFF6F8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // CV Upload
              Row(
                children: [
                  const Icon(Icons.upload_file, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Upload CV (PDF):'),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Implement CV upload
                    },
                    child: const Text('Choose File'),
                  ),
                ],
              ),
              if (_cvUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Uploaded: $_cvUrl', style: const TextStyle(fontSize: 12)),
                ),
              const SizedBox(height: 18),
              // Visibility
              SwitchListTile(
                value: _publicProfile,
                onChanged: (val) => setState(() => _publicProfile = val),
                title: const Text('Make profile public to employers'),
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
      bottomNavigationBar: JobseekerBottomNavBar(currentIndex: 4, context: context),
    );
  }
} 