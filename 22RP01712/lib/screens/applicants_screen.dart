import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/user.dart';
import '../services/job_application_service.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicantsScreen extends StatefulWidget {
  @override
  _ApplicantsScreenState createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  List<Map<String, dynamic>> applications = [];
  bool isLoading = true;
  Job? job;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobAndApplications();
    });
  }

  void _loadJobAndApplications() {
    final Job? jobArg = ModalRoute.of(context)?.settings.arguments as Job?;
    if (jobArg == null || jobArg.id.isEmpty) {
      print('ApplicantsScreen: job or job.id is null/empty!');
      return;
    }
    
    setState(() {
      job = jobArg;
    });
    
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    if (job == null) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      final jobApplications = await JobApplicationService.getJobApplications(job!.id);
      setState(() {
        applications = jobApplications;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading applications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateApplicationStatus(String userId, String status, {String? adminNotes}) async {
    if (job == null) return;
    
    try {
      final success = await JobApplicationService.updateApplicationStatus(
        jobId: job!.id,
        userId: userId,
        status: status,
        adminNotes: adminNotes,
      );
      
      if (success) {
        // Create notification for the user
        await NotificationService.createNotification(
          userId: userId,
          jobId: job!.id,
          jobTitle: job!.title,
          type: 'status_update',
          message: 'Your application status has been updated to $status',
          additionalData: {
            'status': status,
            'adminNotes': adminNotes,
            'jobId': job!.id,
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application status updated to $status')),
        );
        _loadApplications(); // Reload to show updated status
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update application status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating application status: $e')),
      );
    }
  }

  Future<void> _showStatusUpdateDialog(String userId, String currentStatus) async {
    String newStatus = currentStatus;
    String adminNotes = '';
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Application Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: newStatus,
                items: [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'reviewed', child: Text('Under Review')),
                  DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (value) => newStatus = value ?? 'pending',
                decoration: InputDecoration(labelText: 'Status'),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Admin Notes (Optional)',
                  hintText: 'Add notes about this application...',
                ),
                maxLines: 3,
                onChanged: (value) => adminNotes = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateApplicationStatus(userId, newStatus, adminNotes: adminNotes.isNotEmpty ? adminNotes : null);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

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

  Future<void> _showDeleteDialog(Map<String, dynamic> application) async {
    final applicantName = application['userName'] ?? 'Unknown Applicant';
    final jobTitle = job?.title ?? 'Unknown Job';
    
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Application'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this application?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Applicant: $applicantName',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Job: $jobTitle',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '⚠️ This action cannot be undone. The applicant will be removed from this job\'s application list.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete Application'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteApplication(application);
    }
  }

  Future<void> _deleteApplication(Map<String, dynamic> application) async {
    if (job == null) return;
    
    try {
      final success = await JobApplicationService.deleteApplication(
        job!.id,
        application['userId'],
      );
      
      if (success) {
        // Create notification for the user about deletion
        await NotificationService.createNotification(
          userId: application['userId'],
          jobId: job!.id,
          jobTitle: job!.title,
          type: 'application_deleted',
          message: 'Your application for "${job!.title}" has been removed by admin.',
          additionalData: {
            'jobId': job!.id,
            'jobTitle': job!.title,
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadApplications(); // Reload to show updated list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Applications')),
        body: Center(child: Text('Error: No job selected or job ID is missing.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Applications for ${job!.title}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : applications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No applications yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Applications will appear here when users apply',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApplications,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      final application = applications[index];
                      final status = application['status'] ?? 'pending';
                      final appliedAt = application['appliedAt'] as Timestamp?;
                      final date = appliedAt?.toDate();

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          application['userName'] ?? 'Unknown Applicant',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          application['userEmail'] ?? 'No email',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(_getStatusColor(status).replaceAll('#', '0xFF'))),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(status),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              if (date != null)
                                Text(
                                  'Applied on: ${date.toLocal().toString().split(' ')[0]}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              SizedBox(height: 12),
                              if (application['coverLetter'] != null && application['coverLetter'].toString().isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cover Letter:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      application['coverLetter'],
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              if (application['adminNotes'] != null && application['adminNotes'].toString().isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8),
                                    Text(
                                      'Admin Notes:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      application['adminNotes'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ],
                                ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.person),
                                      label: Text('View Profile'),
                                      onPressed: () async {
                                        // Fetch and show user profile
                                        final userDoc = await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(application['userId'])
                                            .get();
                                        final userData = userDoc.data();
                                        
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Applicant Profile'),
                                            content: userData == null
                                                ? Text('No profile found.')
                                                : SingleChildScrollView(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text('Full Name: ${userData['fullName']}'),
                                                        Text('Email: ${userData['email']}'),
                                                        Text('Phone: ${userData['telephone']}'),
                                                        Text('ID Number: ${userData['idNumber']}'),
                                                        if (userData['cvUrl'] != null)
                                                          TextButton.icon(
                                                            icon: Icon(Icons.download),
                                                            label: Text('Download CV'),
                                                            onPressed: () async {
                                                              final url = userData['cvUrl'];
                                                              if (await canLaunchUrl(Uri.parse(url))) {
                                                                await launchUrl(Uri.parse(url));
                                                              }
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text('Close'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.edit),
                                      label: Text('Update Status'),
                                      onPressed: () => _showStatusUpdateDialog(
                                        application['userId'],
                                        status,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.delete),
                                      label: Text('Delete'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => _showDeleteDialog(application),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
} 