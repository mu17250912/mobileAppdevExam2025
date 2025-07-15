import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/job_application_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyApplicationsScreen extends StatefulWidget {
  final AppUser user;

  MyApplicationsScreen({required this.user});

  @override
  _MyApplicationsScreenState createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> applications = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userApplications = await JobApplicationService.getUserApplications(widget.user.id);
      setState(() {
        applications = userApplications;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading applications: $e');
      setState(() {
        isLoading = false;
      });
    }
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

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Congratulations! Your application has been accepted. The company will contact you soon. 📧 Check your email for detailed response.';
      case 'rejected':
        return 'Thank you for your interest. Unfortunately, your application was not selected for this position. 📧 Check your email for detailed response.';
      case 'reviewed':
        return 'Your application is currently under review. We will notify you of the decision soon. 📧 Check your email for detailed response.';
      case 'pending':
      default:
        return 'Your application has been submitted and is awaiting review. 📧 Check your email for detailed response.';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'reviewed':
        return Icons.hourglass_empty;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Applications'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Applications', icon: Icon(Icons.work)),
            Tab(text: 'Answers', icon: Icon(Icons.question_answer)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Email warning banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.email, color: Colors.blue[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📧 Please check your email carefully for detailed responses from employers.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                // Applications Tab
                applications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No applications yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            SizedBox(height: 8),
                            Text('Start applying to jobs to see them here', style: TextStyle(color: Colors.grey)),
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
                            final updatedAt = application['updatedAt'] as Timestamp?;
                            final date = appliedAt?.toDate();
                            final updateDate = updatedAt?.toDate();
                            // ... (existing card code here) ...
                            // (Use the improved card layout from previous step)
                            return Card(
                              margin: EdgeInsets.only(bottom: 20),
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Job info and status badge
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                application['jobTitle'] ?? 'Unknown Job',
                                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                application['company'] ?? 'Unknown Company',
                                                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Chip(
                                          label: Text(_getStatusText(status)),
                                          backgroundColor: Color(int.parse(_getStatusColor(status).replaceAll('#', '0xFF'))).withOpacity(0.15),
                                          labelStyle: TextStyle(
                                            color: Color(int.parse(_getStatusColor(status).replaceAll('#', '0xFF'))),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          avatar: Icon(
                                            _getStatusIcon(status),
                                            color: Color(int.parse(_getStatusColor(status).replaceAll('#', '0xFF'))),
                                            size: 18,
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                      ],
                                    ),
                                    Divider(height: 28),
                                    // Application details
                                    Row(
                                      children: [
                                        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                                        SizedBox(width: 4),
                                        Text(
                                          'Applied: ${date?.toLocal().toString().split(' ')[0] ?? 'Unknown'}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        if (updateDate != null) ...[
                                          SizedBox(width: 16),
                                          Icon(Icons.update, size: 16, color: Colors.grey[600]),
                                          SizedBox(width: 4),
                                          Text(
                                            'Updated: ${updateDate.toLocal().toString().split(' ')[0]}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (application['coverLetter'] != null && application['coverLetter'].toString().isNotEmpty) ...[
                                      SizedBox(height: 14),
                                      Text('Your Cover Letter:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      SizedBox(height: 4),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Text(
                                          application['coverLetter'],
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                    // Admin Response Section
                                    if (application['adminNotes'] != null && application['adminNotes'].toString().isNotEmpty) ...[
                                      SizedBox(height: 18),
                                      // Email warning for admin response
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(10),
                                        margin: EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue[200]!),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.email, color: Colors.blue[700], size: 16),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '📧 Check your email for detailed response from the employer.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange[200]!),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.admin_panel_settings, color: Colors.orange[700], size: 22),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Admin Response:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700], fontSize: 15)),
                                                  SizedBox(height: 6),
                                                  Text(
                                                    application['adminNotes'],
                                                    style: TextStyle(fontSize: 14, color: Colors.orange[800]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 18),
                                    // Status description
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(_getStatusColor(status).replaceAll('#', '0xFF'))).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Color(int.parse(_getStatusColor(status).replaceAll('#', '0xFF'))).withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Color(int.parse(_getStatusColor(status).replaceAll('#', '0xFF'))),
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _getStatusDescription(status),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(int.parse(_getStatusColor(status).replaceAll('#', '0xFF'))),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: Icon(Icons.work),
                                            label: Text('View Job Details'),
                                            onPressed: () {
                                              // Navigate to job details
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Job details feature coming soon')),
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        if (status == 'accepted')
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: Icon(Icons.email),
                                              label: Text('Contact Company'),
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Contact feature coming soon')),
                                                );
                                              },
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
                // Answers Tab
                applications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.question_answer, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No answers yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            SizedBox(height: 8),
                            Text('Admin responses will appear here.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadApplications,
                        child: ListView.separated(
                          padding: EdgeInsets.all(16),
                          itemCount: applications.length,
                          separatorBuilder: (_, __) => SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final application = applications[index];
                            final status = application['status'] ?? 'pending';
                            final adminNotes = application['adminNotes'] ?? '';
                            if (adminNotes.isEmpty) {
                              return SizedBox.shrink();
                            }
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.work, color: Colors.blueGrey),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            application['jobTitle'] ?? 'Unknown Job',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        Chip(
                                          label: Text(_getStatusText(status)),
                                          backgroundColor: Color(int.parse(_getStatusColor(status).replaceAll('#', '0xFF'))).withOpacity(0.15),
                                          labelStyle: TextStyle(
                                            color: Color(int.parse(_getStatusColor(status).replaceAll('#', '0xFF'))),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    // Email warning for answers tab
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(8),
                                      margin: EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.blue[200]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.email, color: Colors.blue[700], size: 14),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '📧 Check your email for detailed response from the employer.',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.blue[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.admin_panel_settings, color: Colors.orange[700]),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            adminNotes,
                                            style: TextStyle(fontSize: 15, color: Colors.orange[800]),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
} 