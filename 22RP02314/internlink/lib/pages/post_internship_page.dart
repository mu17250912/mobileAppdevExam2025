import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/internship.dart';
import '../services/internship_service.dart';

class PostInternshipPage extends StatefulWidget {
  const PostInternshipPage({Key? key}) : super(key: key);

  @override
  State<PostInternshipPage> createState() => _PostInternshipPageState();
}

class _PostInternshipPageState extends State<PostInternshipPage> {
  final _formKey = GlobalKey<FormState>();
  final InternshipService _internshipService = InternshipService();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _stipendController = TextEditingController();
  final TextEditingController _maxApplicationsController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  
  String _selectedType = 'Full-time';
  DateTime? _deadline;
  bool _isLoading = false;

  final List<String> _internshipTypes = [
    'Full-time',
    'Part-time',
    'Remote',
    'Hybrid',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _stipendController.dispose();
    _maxApplicationsController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _postInternship() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deadline')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get company data
      final companyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!companyDoc.exists) throw Exception('Company data not found');
      
      final companyData = companyDoc.data()!;
      final companyName = companyData['companyName'] ?? 'Unknown Company';

      // Parse skills
      final skills = _skillsController.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList();

      final internship = Internship(
        id: '',
        companyId: user.uid,
        companyName: companyName,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        requirements: _requirementsController.text.trim(),
        location: _locationController.text.trim(),
        duration: _durationController.text.trim(),
        stipend: _stipendController.text.trim(),
        type: _selectedType,
        skills: skills,
        deadline: _deadline!,
        postedDate: DateTime.now(),
        status: 'active',
        maxApplications: int.tryParse(_maxApplicationsController.text) ?? 50,
        currentApplications: 0,
      );

      await _internshipService.postInternship(internship);

      // Notify all students of new position
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      final batch = FirebaseFirestore.instance.batch();
      final now = Timestamp.now();
      for (var doc in usersSnapshot.docs) {
        final userId = doc.id;
        final notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': userId,
          'title': 'New Internship Posted',
          'message': 'A new position "${_titleController.text.trim()}" is now available. Check it out!',
          'timestamp': now,
        });
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internship posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post internship: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Internship'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Internship Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Internship Title *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter internship title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _requirementsController,
                        decoration: const InputDecoration(
                          labelText: 'Requirements *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter requirements';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Position Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Internship Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: _internshipTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration *',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 3 months, 6 months',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter duration';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _stipendController,
                        decoration: const InputDecoration(
                          labelText: 'Stipend *',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., \$1000/month, Unpaid',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter stipend';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _skillsController,
                        decoration: const InputDecoration(
                          labelText: 'Required Skills',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Python, React, Communication',
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _maxApplicationsController,
                        decoration: const InputDecoration(
                          labelText: 'Max Applications',
                          border: OutlineInputBorder(),
                          hintText: '50',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      
                      InkWell(
                        onTap: _selectDeadline,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Application Deadline *',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _deadline == null
                                    ? 'Select deadline'
                                    : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _postInternship,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Post Internship',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 