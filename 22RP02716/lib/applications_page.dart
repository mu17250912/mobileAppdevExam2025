import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'employer_dashboard.dart'; // For DashboardPage
import 'company_profile_page.dart'; // For CompanyProfilePage
import 'job_posts_page.dart'; // For JobPostsPage

class ApplicationsPage extends StatelessWidget {
  const ApplicationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Applications')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('profile').doc(user.uid).get(),
        builder: (context, profileSnapshot) {
          String? companyName;
          if (profileSnapshot.hasData && profileSnapshot.data != null && profileSnapshot.data!.data() != null) {
            final data = profileSnapshot.data!.data() as Map<String, dynamic>;
            companyName = data['companyName'];
          }
          if (companyName == null || companyName.isEmpty) {
            return const Center(child: Text('No company profile found.'));
          }
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .where('company_name', isEqualTo: companyName)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load applications', style: TextStyle(color: Colors.red)));
              }
              final applications = snapshot.data?.docs ?? [];
              if (applications.isEmpty) {
                return const Center(child: Text('No applications yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: applications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final appDoc = applications[i];
                  final app = appDoc.data() as Map<String, dynamic>;
                  final jobTitle = app['job_title'] ?? '';
                  final applicantName = app['applicant_name'] ?? 'Jobseeker';
                  final status = app['status'] ?? 'Pending';
                  final appliedAt = app['applied_at'] != null && app['applied_at'] is Timestamp
                      ? (app['applied_at'] as Timestamp).toDate()
                      : null;
                  final resumeUrl = app['resume_url'];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text('Applicant: $applicantName'),
                          Text('Status: $status'),
                          if (appliedAt != null)
                            Text('Applied: ${DateFormat('yyyy-MM-dd HH:mm').format(appliedAt)}'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: resumeUrl != null && resumeUrl.isNotEmpty
                                    ? () {
                                        launchUrl(Uri.parse(resumeUrl));
                                      }
                                    : null,
                                child: const Text('View Resume'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ApplicationDetailsPage(
                                        application: app,
                                        applicationId: appDoc.id,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('View Application'),
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
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Job Posts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
              (route) => false,
            );
          } else if (index == 1) {
            // Already on Applications
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CompanyProfilePage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const JobPostsPage()),
            );
          } else if (index == 4) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings page coming soon!')),
            );
          }
        },
      ),
    );
  }
}

class ApplicationDetailsPage extends StatefulWidget {
  final Map<String, dynamic> application;
  final String applicationId;
  const ApplicationDetailsPage({Key? key, required this.application, required this.applicationId}) : super(key: key);

  @override
  State<ApplicationDetailsPage> createState() => _ApplicationDetailsPageState();
}

class _ApplicationDetailsPageState extends State<ApplicationDetailsPage> {
  late String status;
  final List<String> statusOptions = [
    'Pending',
    'Shortlisted',
    'Under Review',
    'Interview Scheduled',
    'Rejected',
    'Accepted',
  ];

  // Define jobInfo as a field
  late final Map<String, dynamic> jobInfo;

  // User info order for display
  final List<String> userInfoOrder = [
    'fullName', 'email', 'phone', 'education', 'experience', 'skills', 'languages', 'about', 'location', 'portfolio', 'preferredJobType', 'cvUrl', 'imageUrl', 'otherDomain', 'domain'
  ];

  @override
  void initState() {
    super.initState();
    status = widget.application['status'] ?? 'Pending';
    // Build jobInfo map
    final app = widget.application;
    final List<String> jobInfoOrder = [
      'job_title', 'company_name', 'job_type', 'salary', 'description', 'cover_letter', 'expected_salary', 'preferred_start_date', 'applied_at', 'status', 'additional_notes'
    ];
    jobInfo = <String, dynamic>{};
    for (final key in jobInfoOrder) {
      if (app.containsKey(key) && app[key] != null && app[key].toString().isNotEmpty) {
        jobInfo[key] = app[key];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final jobseekerId = app['jobseeker_id'];
    // Format date fields
    String formatDate(dynamic value) {
      if (value == null) return '';
      if (value is Timestamp) {
        final dt = value.toDate();
        return DateFormat('yyyy-MM-dd').format(dt);
      }
      if (value is DateTime) {
        return DateFormat('yyyy-MM-dd').format(value);
      }
      return value.toString();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Application Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (jobseekerId != null && jobseekerId.toString().isNotEmpty)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('jobseeker_profiles').doc(jobseekerId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Applicant profile not found.', style: TextStyle(color: Colors.red[800])),
                      ),
                    );
                  }
                  final userProfile = snapshot.data!.data() as Map<String, dynamic>;
                  return Card(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Applicant Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.primary)),
                          const SizedBox(height: 16),
                          ...userInfoOrder.where((key) => userProfile.containsKey(key) && userProfile[key] != null && userProfile[key].toString().isNotEmpty).map((key) => Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatFieldName(key),
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildFieldValue(userProfile[key]),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 18),
            Card(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.06),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Job Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.secondary)),
                    const SizedBox(height: 16),
                    ...jobInfo.entries.map((e) {
                      final isDateField = e.key == 'applied_at' || e.key == 'preferred_start_date';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatFieldName(e.key),
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildFieldValue(isDateField ? formatDate(e.value) : e.value),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Update Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: status,
                  items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => status = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('applications').doc(widget.applicationId).update({'status': status});
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to format field names to Title Case
  String _formatFieldName(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
        .join(' ');
  }

  // Helper to build field value widget
  Widget _buildFieldValue(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const Text('-', style: TextStyle(color: Colors.black87, fontSize: 15));
    }
    if (value is List) {
      // For lists (education, experience, skills, languages)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.map<Widget>((item) => Text(item.toString(), style: const TextStyle(color: Colors.black87, fontSize: 15))).toList(),
      );
    }
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.entries.map<Widget>((e) => Text('${_formatFieldName(e.key)}: ${e.value}', style: const TextStyle(color: Colors.black87, fontSize: 15))).toList(),
      );
    }
    return Text(value.toString(), style: const TextStyle(color: Colors.black87, fontSize: 15));
  }
} 