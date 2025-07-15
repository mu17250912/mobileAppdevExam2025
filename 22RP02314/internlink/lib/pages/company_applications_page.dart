import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/application.dart';
import '../services/application_service.dart';
import '../services/internship_service.dart';
import '../company_home_page.dart';
import '../pages/post_internship_page.dart';
import '../pages/company_profile_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyApplicationsPage extends StatefulWidget {
  const CompanyApplicationsPage({Key? key}) : super(key: key);

  @override
  State<CompanyApplicationsPage> createState() => _CompanyApplicationsPageState();
}

class _CompanyApplicationsPageState extends State<CompanyApplicationsPage> {
  final ApplicationService _applicationService = ApplicationService();
  final InternshipService _internshipService = InternshipService();
  String _selectedStatus = 'All';

  final List<String> _statusFilters = [
    'All',
    'pending',
    'approved',
    'rejected',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Applications'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please login to view applications'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
            itemBuilder: (context) => _statusFilters.map((status) {
              return PopupMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 4),
                  Text('Filter'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedStatus != 'All')
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Filtered by: $_selectedStatus'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = 'All';
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Application>>(
              stream: _applicationService.getCompanyApplications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final allApplications = snapshot.data ?? [];
                final filteredApplications = _selectedStatus == 'All'
                    ? allApplications
                    : allApplications.where((app) => app.status == _selectedStatus).toList();

                if (filteredApplications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No applications found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Applications will appear here when students apply',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredApplications.length,
                  itemBuilder: (context, index) {
                    final application = filteredApplications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FutureBuilder(
                                    future: _internshipService.getInternshipById(application.internshipId),
                                    builder: (context, internshipSnapshot) {
                                      if (internshipSnapshot.hasData && internshipSnapshot.data != null) {
                                        final internship = internshipSnapshot.data!;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              internship.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Applied by: ${application.studentEmail}',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return const Text(
                                        'Loading...',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                _buildStatusChip(application.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.email, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  application.studentEmail,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  application.studentPhone,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Applied on ${application.appliedDate.day}/${application.appliedDate.month}/${application.appliedDate.year}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _showApplicationDetails(application);
                                    },
                                    child: const Text('View Details'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (application.status == 'pending') ...[
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _approveApplication(application);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                        ),
                                        child: const Text('Approve'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateApplicationStatus(application.id, 'rejected'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.link, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final url = application.cvGoogleDocsLink;
                                        if (await canLaunch(url)) {
                                          await launch(url);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not open link')),
                                          );
                                        }
                                      },
                                      child: Text(
                                        application.cvGoogleDocsLink,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1B2B5A),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CompanyHomePage()),
                );
              },
              child: const _NavBarItem(icon: Icons.home, label: 'Home', selected: false),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PostInternshipPage()),
                );
              },
              child: const _NavBarItem(icon: Icons.add_box_outlined, label: 'Post', selected: false),
            ),
            GestureDetector(
              onTap: () {}, // Already on Applications
              child: const _NavBarItem(icon: Icons.menu_book_outlined, label: 'Applications', selected: true),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CompanyProfilePage()),
                );
              },
              child: const _NavBarItem(icon: Icons.business_outlined, label: 'Profile', selected: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'withdrawn':
        color = Colors.grey;
        label = 'Withdrawn';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showApplicationDetails(Application application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Application Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Student: ${application.studentName}'),
              const SizedBox(height: 8),
              Text('Email: ${application.studentEmail}'),
              const SizedBox(height: 8),
              Text('Phone: ${application.studentPhone}'),
              const SizedBox(height: 8),
              Text('Applied: ${application.appliedDate.day}/${application.appliedDate.month}/${application.appliedDate.year}'),
              const SizedBox(height: 8),
              Text('Status: ${application.status}'),
              const SizedBox(height: 16),
              const Text(
                'Cover Letter:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(application.coverLetter),
              if (application.feedback != null && application.feedback!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Feedback:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(application.feedback!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateApplicationStatus(String applicationId, String status) async {
    try {
      await _applicationService.updateApplicationStatus(applicationId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application $status successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _approveApplication(Application application) async {
    await _applicationService.updateApplicationStatus(application.id, 'approved');
    // After approval, show dialog to call to interview
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call to Interview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send an interview invitation to:'),
            const SizedBox(height: 8),
            SelectableText(application.studentEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Message Template:'),
            const SizedBox(height: 8),
            SelectableText(
              'Dear Applicant,\n\nCongratulations! You have been shortlisted for an interview. Please reply to this email to schedule your interview time.\n\nBest regards,\n[Your Company]',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final email = application.studentEmail;
              final subject = Uri.encodeComponent('Interview Invitation');
              final body = Uri.encodeComponent('Dear Applicant,\n\nCongratulations! You have been shortlisted for an interview. Please reply to this email to schedule your interview time.\n\nBest regards,\n[Your Company]');
              final mailtoUrl = 'mailto:$email?subject=$subject&body=$body';
              // Fetch internship title
              String internshipTitle = 'an internship';
              try {
                final doc = await FirebaseFirestore.instance.collection('internships').doc(application.internshipId).get();
                if (doc.exists) {
                  final data = doc.data() as Map<String, dynamic>;
                  internshipTitle = data['title'] ?? internshipTitle;
                }
              } catch (_) {}
              // Send notification to Firestore
              await FirebaseFirestore.instance.collection('notifications').add({
                'userId': application.studentId,
                'title': 'Interview Invitation',
                'message': 'You have been shortlisted for an interview for the position of $internshipTitle. Please check your email for details.',
                'timestamp': FieldValue.serverTimestamp(),
                'read': false,
              });
              if (await canLaunch(mailtoUrl)) {
                await launch(mailtoUrl);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open email client')),
                );
              }
            },
            child: const Text('Send Interview Email'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _NavBarItem({required this.icon, required this.label, this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? Colors.white : Colors.white70, size: 28),
        Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
} 