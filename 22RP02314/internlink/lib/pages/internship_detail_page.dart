import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/internship.dart';
import '../models/application.dart';
import '../services/application_service.dart';
import '../services/notification_service.dart';
import 'apply_internship_page.dart';

class InternshipDetailPage extends StatefulWidget {
  final Internship internship;

  const InternshipDetailPage({
    Key? key,
    required this.internship,
  }) : super(key: key);

  @override
  State<InternshipDetailPage> createState() => _InternshipDetailPageState();
}

class _InternshipDetailPageState extends State<InternshipDetailPage> {
  final ApplicationService _applicationService = ApplicationService();
  final NotificationService _notificationService = NotificationService();
  bool _hasApplied = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final hasApplied = await _applicationService.hasStudentApplied(
          user.uid,
          widget.internship.id,
        );
        setState(() {
          _hasApplied = hasApplied;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'green';
      case 'closed':
        return 'red';
      case 'draft':
        return 'orange';
      default:
        return 'grey';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internship Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.internship.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.internship.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.internship.companyName,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          widget.internship.location,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.work, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          widget.internship.type,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          widget.internship.stipend,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Details Card
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
                    
                    _buildDetailRow('Duration', widget.internship.duration),
                    _buildDetailRow('Deadline', 
                      '${widget.internship.deadline.day}/${widget.internship.deadline.month}/${widget.internship.deadline.year}'),
                    _buildDetailRow('Applications', 
                      '${widget.internship.currentApplications}/${widget.internship.maxApplications}'),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.internship.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Requirements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.internship.requirements,
                      style: const TextStyle(fontSize: 16),
                    ),
                    
                    if (widget.internship.skills.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Required Skills',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.internship.skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Company Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About the Company',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.internship.companyName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Posted on ${widget.internship.postedDate.day}/${widget.internship.postedDate.month}/${widget.internship.postedDate.year}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text(
            'Login to Apply',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    // Check if user is a student
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final userRole = userData?['role'] ?? '';

        if (userRole != 'student') {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Only students can apply for internships',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

        if (_hasApplied) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Already Applied',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        if (widget.internship.currentApplications >= widget.internship.maxApplications) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Applications Full',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        if (DateTime.now().isAfter(widget.internship.deadline)) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Application Deadline Passed',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApplyInternshipPage(
                    internship: widget.internship,
                  ),
                ),
              ).then((_) {
                _checkApplicationStatus();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'Apply Now',
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      },
    );
  }
} 