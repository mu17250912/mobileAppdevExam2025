import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../styles/app_styles.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _userService.getUserStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading statistics: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to Admin Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppStyles.primaryColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Manage users and monitor recruitment activities',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Statistics Cards
                  Text(
                    'User Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        'Total Users',
                        _statistics['totalUsers']?.toString() ?? '0',
                        Icons.people,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Users with CV',
                        _statistics['usersWithCV']?.toString() ?? '0',
                        Icons.description,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Users with Experience',
                        _statistics['usersWithExperience']?.toString() ?? '0',
                        Icons.work,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Users with Degrees',
                        _statistics['usersWithDegrees']?.toString() ?? '0',
                        Icons.school,
                        Colors.purple,
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Column(
                    children: [
                      _buildActionCard(
                        'View All Users',
                        'Browse and manage all user profiles',
                        Icons.people_outline,
                        Colors.blue,
                        () => Navigator.pushNamed(context, '/adminUsers'),
                      ),
                      SizedBox(height: 12),
                      _buildActionCard(
                        'Search Users',
                        'Find specific users by name or email',
                        Icons.search,
                        Colors.green,
                        () => _showSearchDialog(),
                      ),
                      SizedBox(height: 12),
                      _buildActionCard(
                        'User Analytics',
                        'View detailed user statistics and trends',
                        Icons.analytics,
                        Colors.orange,
                        () => _showAnalyticsDialog(),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // User Submissions Section
                  Text(
                    'User Submissions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('user_submissions').orderBy('submittedAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text('No user submissions yet.');
                      }
                      final submissions = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: submissions.length,
                        itemBuilder: (context, idx) {
                          final data = submissions[idx].data() as Map<String, dynamic>;
                          return Card(
                            margin: EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(
                                        data['fullName'] ?? 'Unknown',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Spacer(),
                                      Text(
                                        data['submittedAt'] != null
                                            ? (data['submittedAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0]
                                            : '',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text('Email: ${data['email'] ?? '-'}'),
                                  Text('Phone: ${data['telephone'] ?? '-'}'),
                                  if (data['cvUrl'] != null && data['cvUrl'].toString().isNotEmpty)
                                    Text('CV: Available'),
                                  if (data['degrees'] != null && (data['degrees'] as List).isNotEmpty)
                                    Text('Degrees: ${(data['degrees'] as List).length} uploaded'),
                                  if (data['certificates'] != null && (data['certificates'] as List).isNotEmpty)
                                    Text('Certificates: ${(data['certificates'] as List).length} uploaded'),
                                  if (data['experiences'] != null && (data['experiences'] as List).isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 8),
                                        Text('Experiences:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ...List.generate((data['experiences'] as List).length, (i) {
                                          final exp = (data['experiences'] as List)[i];
                                          return Text('- ${exp['description'] ?? ''}');
                                        }),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  Text(
                    'User Applications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('jobs').get(),
                    builder: (context, jobSnapshot) {
                      if (jobSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!jobSnapshot.hasData || jobSnapshot.data!.docs.isEmpty) {
                        return Text('No job posts found.');
                      }
                      final jobs = jobSnapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: jobs.length,
                        itemBuilder: (context, jobIdx) {
                          final job = jobs[jobIdx];
                          final jobData = job.data() as Map<String, dynamic>;
                          return FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('jobs')
                                .doc(job.id)
                                .collection('applications')
                                .get(),
                            builder: (context, appSnapshot) {
                              if (appSnapshot.connectionState == ConnectionState.waiting) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: LinearProgressIndicator(),
                                );
                              }
                              final apps = appSnapshot.data?.docs ?? [];
                              if (apps.isEmpty) return SizedBox.shrink();
                              return Card(
                                margin: EdgeInsets.only(bottom: 18),
                                elevation: 2,
                                child: Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        jobData['title'] ?? 'Unknown Job',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                      ),
                                      Text(
                                        jobData['company'] ?? '',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                      Divider(height: 22),
                                      ...apps.map((appDoc) {
                                        final app = appDoc.data() as Map<String, dynamic>;
                                        return Card(
                                          margin: EdgeInsets.symmetric(vertical: 4),
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.person, color: Colors.blue),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            app['userName'] ?? app['userId'] ?? 'Unknown',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          Text(
                                                            'Email: ${app['userEmail'] ?? '-'}',
                                                            style: TextStyle(color: Colors.grey[600]),
                                                          ),
                                                          Text(
                                                            'Status: ${app['status'] ?? 'pending'}',
                                                            style: TextStyle(
                                                              color: _getStatusColor(app['status'] ?? 'pending'),
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                          if ((app['adminNotes'] ?? '').toString().isNotEmpty)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4.0),
                                                              child: Text(
                                                                'Admin Response: ${app['adminNotes']}',
                                                                style: TextStyle(color: Colors.orange[800]),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (app['appliedAt'] != null)
                                                      Text(
                                                        (app['appliedAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0],
                                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                                      ),
                                                  ],
                                                ),
                                                SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        onPressed: () => _showResponseDialog(job.id, app['userId'], app['status'] ?? 'pending'),
                                                        icon: Icon(Icons.reply, size: 16),
                                                        label: Text('Respond'),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: Colors.blue,
                                                          side: BorderSide(color: Colors.blue),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        onPressed: () => _viewUserProfile(app['userId']),
                                                        icon: Icon(Icons.person_outline, size: 16),
                                                        label: Text('View Profile'),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: Colors.green,
                                                          side: BorderSide(color: Colors.green),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter name or email...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/adminUsers');
                // You can pass search parameters here
              },
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
              Navigator.pushNamed(context, '/adminUsers');
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Analytics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Users: ${_statistics['totalUsers'] ?? 0}'),
            SizedBox(height: 8),
            Text('Users with CV: ${_statistics['usersWithCV'] ?? 0}'),
            SizedBox(height: 8),
            Text('Users with Experience: ${_statistics['usersWithExperience'] ?? 0}'),
            SizedBox(height: 8),
            Text('Users with Degrees: ${_statistics['usersWithDegrees'] ?? 0}'),
            SizedBox(height: 8),
            Text('Users with Certificates: ${_statistics['usersWithCertificates'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'reviewed':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.blue;
    }
  }

  void _showResponseDialog(String jobId, String userId, String currentStatus) async {
    String newStatus = currentStatus;
    String adminNotes = '';
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Respond to Application'),
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
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Admin Response',
                  hintText: 'Add your response to the applicant...',
                  border: OutlineInputBorder(),
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
              onPressed: () async {
                Navigator.pop(context);
                await _updateApplicationStatus(jobId, userId, newStatus, adminNotes);
              },
              child: Text('Send Response'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateApplicationStatus(String jobId, String userId, String status, String adminNotes) async {
    try {
      // Update the application status in Firestore
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .doc(userId)
          .update({
        'status': status,
        'adminNotes': adminNotes,
        'updatedAt': Timestamp.now(),
      });

      // Create notification for the user
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'type': 'status_update',
        'message': 'Your application status has been updated to $status',
        'jobId': jobId,
        'status': status,
        'adminNotes': adminNotes,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Response sent successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the dashboard
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending response: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewUserProfile(String userId) async {
    try {
      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User profile not found')),
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('User Profile'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProfileField('Name', userData['name'] ?? 'N/A'),
                _buildProfileField('Email', userData['email'] ?? 'N/A'),
                _buildProfileField('Phone', userData['phone'] ?? 'N/A'),
                _buildProfileField('Experience', userData['experience'] ?? 'N/A'),
                _buildProfileField('Education', userData['education'] ?? 'N/A'),
                _buildProfileField('Skills', userData['skills'] ?? 'N/A'),
                _buildProfileField('CV Uploaded', userData['cvUrl'] != null ? 'Yes' : 'No'),
                _buildProfileField('Degree Uploaded', userData['degreeUrl'] != null ? 'Yes' : 'No'),
                _buildProfileField('Certificate Uploaded', userData['certificateUrl'] != null ? 'Yes' : 'No'),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading user profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
} 