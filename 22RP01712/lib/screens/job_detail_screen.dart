import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../screens/applicants_screen.dart';
import '../services/job_application_service.dart';

class JobDetailScreen extends StatefulWidget {
  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Job job;
  bool isLoggedIn = false;
  AppUser? user;
  bool hasApplied = false;
  bool isAdmin = false;
  bool isLoadingApplicationStatus = true;
  late DateTime deadlineDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    job = args != null ? args['job'] as Job : throw Exception('No job provided');
    isLoggedIn = args != null && args['isLoggedIn'] == true;
    user = args != null ? args['user'] as AppUser? : null;
    isAdmin = args != null && args['isAdmin'] == true;
    deadlineDate = DateTime.parse(job.deadline);
    
    // Check application status from Firestore
    if (user != null && !isAdmin) {
      _checkApplicationStatus();
    } else {
      setState(() {
        isLoadingApplicationStatus = false;
      });
    }
  }

  // Check if user has already applied to this job
  Future<void> _checkApplicationStatus() async {
    try {
      final hasUserApplied = await JobApplicationService.hasUserApplied(job.id, user!.id);
      if (hasUserApplied) {
        // Get the full application details to show status and admin notes
        final applications = await JobApplicationService.getUserApplications(user!.id);
        final userApplication = applications.firstWhere(
          (app) => app['jobId'] == job.id,
          orElse: () => {},
        );
        
        setState(() {
          hasApplied = true;
          isLoadingApplicationStatus = false;
          // Store application details for display
          _applicationDetails = userApplication;
        });
      } else {
        setState(() {
          hasApplied = false;
          isLoadingApplicationStatus = false;
        });
      }
    } catch (e) {
      print('Error checking application status: $e');
      setState(() {
        isLoadingApplicationStatus = false;
      });
    }
  }

  // Add this variable to store application details
  Map<String, dynamic>? _applicationDetails;

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return '#4CAF50'; // Green
      case 'rejected':
        return '#F44336'; // Red
      case 'reviewed':
        return '#FF9800'; // Orange
      case 'pending':
      default:
        return '#2196F3'; // Blue
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'reviewed':
        return 'Under Review';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Congratulations! Your application has been accepted. The company will contact you soon.';
      case 'rejected':
        return 'Thank you for your interest. Unfortunately, your application was not selected for this position.';
      case 'reviewed':
        return 'Your application is currently under review. We will notify you of the decision soon.';
      case 'pending':
      default:
        return 'Your application has been submitted and is awaiting review.';
    }
  }

  // Helper: Check if user meets all job requirements
  bool userMeetsRequirements() {
    if (user == null) return false;
    // Simple logic: check if each requirement is in user's degrees, certificates, or experience descriptions
    for (final req in job.requirements) {
      final reqLower = req.toLowerCase();
      final hasDegree = user!.degrees.any((d) => d.toLowerCase().contains(reqLower));
      final hasCert = user!.certificates.any((c) => c.toLowerCase().contains(reqLower));
      final hasExp = user!.experiences.any((e) => e.description.toLowerCase().contains(reqLower));
      if (!(hasDegree || hasCert || hasExp)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _showApplicationDialog() async {
    // Double-check application status before showing dialog
    if (hasApplied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already applied for this job.')),
      );
      return;
    }

    // Show warning dialog about 5% monthly salary commission
    bool? agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Important Notice'),
        content: Text('If you get this job, you agree to pay 5% of your monthly salary to our company as a service fee.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('I Agree & Continue'),
          ),
        ],
      ),
    );
    if (agreed != true) return;

    String coverLetter = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Apply for ${job.title}'),
          content: TextField(
            decoration: InputDecoration(labelText: 'Cover Letter'),
            maxLines: 3,
            onChanged: (val) => coverLetter = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, {
                  'coverLetter': coverLetter,
                });
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    ).then((applicationData) async {
      if (applicationData != null && user != null) {
        try {
          final success = await JobApplicationService.submitApplication(
            jobId: job.id,
            user: user!,
            coverLetter: applicationData['coverLetter'],
            jobTitle: job.title,
            company: job.company,
          );

          if (success) {
            // Log analytics event
            await FirebaseAnalytics.instance.logEvent(
              name: 'application_submitted',
              parameters: {'jobId': job.id, 'userId': user!.id},
            );

            setState(() {
              hasApplied = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Application submitted successfully!'),
                    SizedBox(height: 4),
                    Text(
                      '📧 Please check your email carefully for responses from employers.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                duration: Duration(seconds: 6),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You have already applied for this job.')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting application. Please try again.')),
          );
          print('Error submitting application: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool deadlinePassed = DateTime.now().isAfter(deadlineDate);
    return Scaffold(
      appBar: AppBar(title: Text(job.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.company, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(job.location, style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text('Deadline: ${deadlineDate.toLocal().toString().split(' ')[0]}', style: TextStyle(fontSize: 16, color: Colors.red)),
              Text('Salary: ${job.salary}', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text('Type: ${job.jobType}', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text('Experience: ${job.experienceLevel}', style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(job.description),
              SizedBox(height: 16),
              Text('Requirements', style: TextStyle(fontWeight: FontWeight.bold)),
              ...job.requirements.map((req) => Text('- $req')).toList(),
              SizedBox(height: 24),
              Center(
                child: isLoggedIn && user != null && !isAdmin
                    ? deadlinePassed
                        ? Text('The application deadline has passed.', style: TextStyle(color: Colors.red))
                        : isLoadingApplicationStatus
                            ? CircularProgressIndicator()
                            : hasApplied
                                ? Column(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                                      SizedBox(height: 8),
                                      Text('You have already applied for this job.', 
                                           style: TextStyle(color: Colors.green, fontSize: 16)),
                                      SizedBox(height: 8),
                                      Text('Application submitted successfully', 
                                           style: TextStyle(color: Colors.grey)),
                                      
                                      // Show application status and admin response if available
                                      if (_applicationDetails != null) ...[
                                        SizedBox(height: 16),
                                        Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Application Status',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Color(int.parse(_getStatusColor(_applicationDetails!['status'] ?? 'pending').replaceAll('#', '0xFF'))),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _getStatusText(_applicationDetails!['status'] ?? 'pending'),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                _getStatusDescription(_applicationDetails!['status'] ?? 'pending'),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.blue[800],
                                                ),
                                              ),
                                              
                                              // Show admin notes if available
                                              if (_applicationDetails!['adminNotes'] != null && 
                                                  _applicationDetails!['adminNotes'].toString().isNotEmpty) ...[
                                                SizedBox(height: 12),
                                                Container(
                                                  padding: EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[50],
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.orange[200]!),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(Icons.admin_panel_settings, color: Colors.orange[700], size: 20),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'Admin Response:',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 14,
                                                              color: Colors.orange[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        _applicationDetails!['adminNotes'],
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.orange[800],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              
                                              // Show application date
                                              SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Applied on: ${_applicationDetails!['appliedAt'] != null ? (_applicationDetails!['appliedAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : 'Unknown'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      
                                      SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.list),
                                        label: Text('View All My Applications'),
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/my-applications');
                                        },
                                      ),
                                    ],
                                  )
                                : ElevatedButton(
                                    onPressed: _showApplicationDialog,
                                    child: Text('Apply'),
                                  )
                    : isAdmin
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Admins cannot apply to jobs.', style: TextStyle(color: Colors.grey)),
                              SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: Icon(Icons.people),
                                label: Text('View Applicants'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ApplicantsScreen(),
                                      settings: RouteSettings(arguments: job),
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        : Text('Please log in to apply for this job.', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 