import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/internship.dart';
import '../models/application.dart';
import '../services/application_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ApplyInternshipPage extends StatefulWidget {
  final Internship internship;

  const ApplyInternshipPage({
    Key? key,
    required this.internship,
  }) : super(key: key);

  @override
  State<ApplyInternshipPage> createState() => _ApplyInternshipPageState();
}

class _ApplyInternshipPageState extends State<ApplyInternshipPage> {
  final _formKey = GlobalKey<FormState>();
  final ApplicationService _applicationService = ApplicationService();
  final NotificationService _notificationService = NotificationService();
  
  final TextEditingController _coverLetterController = TextEditingController();
  final TextEditingController _cvGoogleDocsLinkController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _coverLetterController.dispose();
    _cvGoogleDocsLinkController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get student data
      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!studentDoc.exists) throw Exception('Student data not found');
      
      final studentData = studentDoc.data()!;
      final studentName = (studentData['name'] ?? ((studentData['firstName'] ?? '') + ' ' + (studentData['lastName'] ?? ''))).trim().isEmpty
        ? 'Unknown Student'
        : (studentData['name'] ?? ((studentData['firstName'] ?? '') + ' ' + (studentData['lastName'] ?? ''))).trim();
      final studentEmail = studentData['email'] ?? '';
      final studentPhone = studentData['phone'] ?? '';

      final application = Application(
        id: '',
        internshipId: widget.internship.id,
        studentId: user.uid,
        studentName: studentName,
        studentEmail: studentEmail,
        studentPhone: studentPhone,
        cvGoogleDocsLink: _cvGoogleDocsLinkController.text.trim(),
        coverLetter: _coverLetterController.text.trim(),
        appliedDate: DateTime.now(),
        status: 'pending',
        companyId: widget.internship.companyId,
      );

      await _applicationService.submitApplication(application);

      // Notify company about the application
      await _notificationService.notifyCompanyOfApplication(
        widget.internship.companyId,
        widget.internship.title,
        studentName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit application: $e'),
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
        title: const Text('Apply for Internship'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Internship Summary Card
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
                      Text(
                        widget.internship.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.internship.companyName,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.internship.location} • ${widget.internship.type}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stipend: ${widget.internship.stipend}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // CV Google Docs Link Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CV Google Docs Link',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cvGoogleDocsLinkController,
                        decoration: const InputDecoration(
                          hintText: 'Paste your Google Docs CV link here',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide your Google Docs CV link';
                          }
                          final urlPattern = r'^(https?:\/\/)?(docs\.google\.com\/document\/d\/)[^\s]+';
                          final regExp = RegExp(urlPattern);
                          if (!regExp.hasMatch(value.trim())) {
                            return 'Please enter a valid Google Docs link';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Cover Letter Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cover Letter',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tell us why you\'re interested in this internship and why you\'d be a great fit.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _coverLetterController,
                        decoration: const InputDecoration(
                          hintText: 'Write your cover letter here...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 8,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please write a cover letter';
                          }
                          if (value.trim().length < 100) {
                            return 'Cover letter should be at least 100 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Application Tips
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Application Tips',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Make sure your CV is up-to-date and relevant to the position\n'
                        '• Write a compelling cover letter that shows your enthusiasm\n'
                        '• Highlight relevant skills and experiences\n'
                        '• Proofread your application before submitting',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text(
                        'Submit Application',
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