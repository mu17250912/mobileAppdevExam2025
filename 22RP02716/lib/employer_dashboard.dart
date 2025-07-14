import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'company_profile_page.dart';
import 'job_posts_page.dart';
import 'notifications.dart';
import 'applications_page.dart';
import 'premium_utils.dart';
import 'dart:ui'; // Added for launchUrl
import 'dart:core'; // Added for launchUrl
import 'package:url_launcher/url_launcher.dart'; // <-- Add this import
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchMode = 'Job Posts'; // or 'Applications'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CompanyProfilePage()),
      );
    }
  }

  void _navigateToProfile() {
    setState(() {
      _selectedIndex = 1;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CompanyProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return FutureBuilder<DocumentSnapshot>(
      future: user != null ? FirebaseFirestore.instance.collection('users').doc(user.uid).get() : null,
      builder: (context, snapshot) {
        String displayName = 'Employer';
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          displayName = data['name'] ?? 'Employer';
        }
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FF),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.blueGrey),
                tooltip: 'Menu',
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            title: Text(
              'Welcome, $displayName!',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.blueGrey),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: const [
                          Icon(Icons.person, color: Colors.blueGrey),
                          SizedBox(width: 8),
                          Text('My Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: const [
                          Icon(Icons.logout, color: Colors.blueGrey),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    } else if (value == 'profile') {
                      _navigateToProfile();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: const AssetImage('assets/images/applicant.jpg'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: const AssetImage('assets/images/applicant.jpg'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard_customize),
                  title: Row(
                    children: const [
                      Text('Dashboard'),
                      SizedBox(width: 8),
                      Icon(Icons.lens, size: 14, color: Colors.orange),
                    ],
                  ),
                  selected: _selectedIndex == 0,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardPage()),
                      (route) => false,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('My Profile'),
                  selected: _selectedIndex == 1,
                  onTap: _navigateToProfile,
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Applications'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ApplicationsPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.work),
                  title: const Text('Job Posts'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JobPostsPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Analytics'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmployerAnalyticsPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmployerSettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: _searchMode == 'Job Posts' ? 'Search job posts...' : 'Search applications...',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.trim();
                            });
                          },
                        ),
                      ),
                      DropdownButton<String>(
                        value: _searchMode,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'Job Posts', child: Text('Job Posts')),
                          DropdownMenuItem(value: 'Applications', child: Text('Applications')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _searchMode = value;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_box_rounded, color: Colors.blue),
                        tooltip: 'Post a Job',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const JobPostsPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Search Results
                if (_searchQuery.isNotEmpty && _searchMode == 'Job Posts')
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('job_posts')
                        .where('employer_id', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Failed to load job posts', style: TextStyle(color: Colors.red))),
                        );
                      }
                      final jobs = snapshot.data?.docs ?? [];
                      final filteredJobs = jobs.where((doc) {
                        final job = doc.data() as Map<String, dynamic>;
                        final query = _searchQuery.toLowerCase();
                        return (job['title'] ?? '').toString().toLowerCase().contains(query) ||
                               (job['description'] ?? '').toString().toLowerCase().contains(query) ||
                               (job['domain'] ?? '').toString().toLowerCase().contains(query);
                      }).toList();
                      if (filteredJobs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No job posts found.')),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredJobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final job = filteredJobs[i].data() as Map<String, dynamic>;
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.work, color: Colors.blue.shade400),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          job['title'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          job['type'] ?? '',
                                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    job['description'] ?? '',
                                    style: const TextStyle(color: Colors.black87),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                if (_searchQuery.isNotEmpty && _searchMode == 'Applications')
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('applications')
                        .where('employer_id', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Failed to load applications', style: TextStyle(color: Colors.red))),
                        );
                      }
                      final apps = snapshot.data?.docs ?? [];
                      final filteredApps = apps.where((doc) {
                        final app = doc.data() as Map<String, dynamic>;
                        final query = _searchQuery.toLowerCase();
                        return (app['applicant_name'] ?? '').toString().toLowerCase().contains(query) ||
                               (app['job_title'] ?? '').toString().toLowerCase().contains(query) ||
                               (app['status'] ?? '').toString().toLowerCase().contains(query);
                      }).toList();
                      if (filteredApps.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No applications found.')),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredApps.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final app = filteredApps[i].data() as Map<String, dynamic>;
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(app['applicant_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(app['job_title'] ?? 'N/A'),
                                  Text('Status: ${app['status'] ?? 'Pending'}'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                if (_searchQuery.isEmpty) ...[
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('job_posts')
                              .where('employer_id', isEqualTo: user?.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            int totalJobs = snapshot.data?.docs.length ?? 0;
                            return _DashboardCard(
                              icon: Icons.work_outline,
                              label: 'Total Jobs',
                              value: totalJobs.toString(),
                              color: Colors.blue,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FutureBuilder<DocumentSnapshot>(
                          future: user == null ? null : FirebaseFirestore.instance.collection('profile').doc(user.uid).get(),
                          builder: (context, profileSnapshot) {
                            String? companyName;
                            if (profileSnapshot.hasData && profileSnapshot.data != null && profileSnapshot.data!.data() != null) {
                              final data = profileSnapshot.data!.data() as Map<String, dynamic>;
                              companyName = data['companyName'];
                            }
                            if (companyName == null || companyName.isEmpty) {
                              return _DashboardCard(
                                icon: Icons.people_outline,
                                label: 'New Applications',
                                value: '-',
                                color: Colors.green,
                              );
                            }
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('applications')
                                  .where('company_name', isEqualTo: companyName)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int newApplications = snapshot.data?.docs.length ?? 0;
                                return _DashboardCard(
                                  icon: Icons.people_outline,
                                  label: 'New Applications',
                                  value: newApplications.toString(),
                                  color: Colors.green,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Add Analytics Card/Button
                  Card(
                    color: Colors.deepPurple.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.analytics, color: Colors.deepPurple, size: 32),
                      title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: const Text('View insights on your job posts and applicants.'),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EmployerAnalyticsPage()),
                        );
                      },
                    ),
                  ),
                  // My Vacancies
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Vacancies',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  // Firestore job posts list - filtered by current user
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('job_posts')
                        .where('employer_id', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Failed to load jobs', style: TextStyle(color: Colors.red))),
                        );
                      }
                      final jobs = snapshot.data?.docs ?? [];
                      if (jobs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No job posts yet.')),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: jobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final job = jobs[i].data() as Map<String, dynamic>;
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.work, color: Colors.blue.shade400),
                                      const SizedBox(width: 8),
                                      Text(
                                        job['title'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          job['type'] ?? '',
                                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    job['description'] ?? '',
                                    style: const TextStyle(color: Colors.black87),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money, color: Colors.green, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        job['salary'] ?? '',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
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
                  const SizedBox(height: 24),
                  // Recent People Applied
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent People Applied',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ApplicationsPage()),
                          );
                        },
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  FutureBuilder<DocumentSnapshot>(
                    future: user == null ? null : FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null || userSnapshot.data!.data() == null) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Failed to load applicants', style: TextStyle(color: Colors.red))),
                        );
                      }
                      final employerId = userSnapshot.data!.id;
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('applications')
                            .where('employer_id', isEqualTo: employerId)
                            .limit(2)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError) {
                            final errorMsg = snapshot.error.toString();
                            if (errorMsg.contains('FAILED_PRECONDITION') || errorMsg.contains('index')) {
                              return Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Text(
                                    'Firestore index error. Please create the required index in the Firebase console.\n$errorMsg',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              );
                            }
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('Failed to load applicants', style: TextStyle(color: Colors.red))),
                            );
                          }
                          final applications = snapshot.data?.docs ?? [];
                          if (applications.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('No applicants yet.')),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
                                        Text('Applied: ${appliedAt.year}-${appliedAt.month.toString().padLeft(2, '0')}-${appliedAt.day.toString().padLeft(2, '0')} ${appliedAt.hour.toString().padLeft(2, '0')}:${appliedAt.minute.toString().padLeft(2, '0')}'),
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
                                              showDialog(
                                                context: context,
                                                builder: (context) => ApplicationDetailsDialog(application: app, applicationId: appDoc.id),
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
                  const SizedBox(height: 24),
                  // Quick links
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Post a Job'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const JobPostsPage()),
                        );
                      },
                    ),
                  ),
                ],
                ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
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
              setState(() {
                _selectedIndex = index;
              });
              if (index == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardPage()),
                  (route) => false,
                );
              } else if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ApplicationsPage()),
                );
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmployerSettingsPage()),
                );
              }
            },
          ),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VacancyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: const Icon(Icons.design_services, color: Colors.orange),
        ),
        title: const Text('UI/UX Designer'),
        subtitle: const Text('Active • Full Time'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('£3,200', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('See Details', style: TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final String name;
  final String role;
  final String imageUrl;
  const _ApplicantCard({required this.name, required this.role, required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
              radius: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(role, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {},
              child: const Text('See Resume'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {},
              child: const Text('See Details'),
            ),
          ],
        ),
      ),
    );
  }
}

// Add a placeholder ProfilePage
class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: const Center(child: Text('Profile details go here.')),
    );
  }
}

// Add the AddJobPostPage widget
class AddJobPostPage extends StatefulWidget {
  final void Function()? onSuccess;
  const AddJobPostPage({Key? key, this.onSuccess}) : super(key: key);

  @override
  State<AddJobPostPage> createState() => _AddJobPostPageState();
}

class _AddJobPostPageState extends State<AddJobPostPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController(); // Add company name controller
  String? _jobType;
  String? _domain; // Use dropdown for domain
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCompanyName();
  }

  Future<void> _fetchCompanyName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('profile').doc(user.uid).get();
    final data = doc.data();
    if (data != null && data['companyName'] != null) {
      _companyNameController.text = data['companyName'];
    }
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _salaryController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseFirestore.instance.collection('job_posts').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'type': _jobType,
        'salary': _salaryController.text.trim(),
        'domain': _domain, // Save selected domain
        'company_name': _companyNameController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
        'employer_id': FirebaseAuth.instance.currentUser?.uid, // Save employer id
      });
      // Notify employer
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'user_id': user.uid,
          'type': 'success',
          'message': 'Your job post \'${_titleController.text.trim()}\' was posted successfully.',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      // Notify all jobseekers
      final jobseekers = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'jobseeker').get();
      for (final doc in jobseekers.docs) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'user_id': doc.id,
          'type': 'job_posted',
          'message': 'A new job "${_titleController.text.trim()}" has been posted by ${_companyNameController.text.trim()}.',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!')),
        );
        widget.onSuccess?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() { _error = 'Failed to post job. Please try again.'; });
      // Notify employer of failure
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'user_id': user.uid,
          'type': 'error',
          'message': 'Failed to post job: ' + (_titleController.text.trim()),
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Create a New Job Post',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.blue),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _companyNameController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Company Name',
                    prefixIcon: const Icon(Icons.business, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Job Title',
                    prefixIcon: const Icon(Icons.title, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter job title' : null,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _domain,
                  decoration: InputDecoration(
                    labelText: 'Domain/Industry/Field',
                    prefixIcon: const Icon(Icons.domain, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
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
                  onChanged: (value) => setState(() => _domain = value),
                  validator: (value) => value == null ? 'Select domain/industry/field' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Job Description',
                    prefixIcon: const Icon(Icons.description, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 4,
                  validator: (value) => value == null || value.isEmpty ? 'Enter job description' : null,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _jobType,
                  decoration: InputDecoration(
                    labelText: 'Job Type',
                    prefixIcon: const Icon(Icons.work_outline, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Full Time', child: Text('Full Time')),
                    DropdownMenuItem(value: 'Part Time', child: Text('Part Time')),
                    DropdownMenuItem(value: 'Contract', child: Text('Contract')),
                    DropdownMenuItem(value: 'Internship', child: Text('Internship')),
                  ],
                  onChanged: (value) => setState(() => _jobType = value),
                  validator: (value) => value == null ? 'Select job type' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _salaryController,
                  decoration: InputDecoration(
                    labelText: 'Salary',
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Enter salary' : null,
                ),
                const SizedBox(height: 28),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    icon: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_box_rounded),
                    label: Text(_loading ? 'Posting...' : 'Post Job'),
                    onPressed: _loading ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmployerSettingsPage extends StatelessWidget {
  const EmployerSettingsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.data() == null) {
            return const Center(child: Text('Failed to load user settings.'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isPremium = data['isPremium'] == true;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(data['name'] ?? 'No Name'),
                subtitle: const Text('Name'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final nameController = TextEditingController(text: data['name'] ?? '');
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Edit Name'),
                        content: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () async {
                              final newName = nameController.text.trim();
                              if (newName.isNotEmpty) {
                                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'name': newName});
                                await user.updateDisplayName(newName);
                                Navigator.pop(context, newName);
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                    if (result != null) {
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(user.email ?? 'No Email'),
                subtitle: const Text('Email'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final emailController = TextEditingController(text: user.email ?? '');
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Edit Email'),
                        content: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () async {
                              final newEmail = emailController.text.trim();
                              if (newEmail.isNotEmpty && newEmail != user.email) {
                                try {
                                  await user.updateEmail(newEmail);
                                  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'email': newEmail});
                                  Navigator.pop(context, newEmail);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update email: \n$e')),
                                  );
                                }
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                    if (result != null) {
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Password'),
                subtitle: const Text('Change your password'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final currentPasswordController = TextEditingController();
                    final newPasswordController = TextEditingController();
                    final confirmPasswordController = TextEditingController();
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Change Password'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: currentPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Current Password'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: newPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'New Password'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: confirmPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Confirm New Password'),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () async {
                              final currentPassword = currentPasswordController.text.trim();
                              final newPassword = newPasswordController.text.trim();
                              final confirmPassword = confirmPasswordController.text.trim();
                              if (newPassword != confirmPassword) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Passwords do not match.')),
                                );
                                return;
                              }
                              try {
                                final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
                                await user.reauthenticateWithCredential(cred);
                                await user.updatePassword(newPassword);
                                Navigator.pop(context, true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password updated successfully.')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update password: \n$e')),
                                );
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                    if (result == true) {
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ),
              const Divider(height: 32),
              const Text('Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Card(
                color: Colors.blue[50],
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Premium Plans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.calendar_view_month, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Monthly: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(' 20 USD'),
                          SizedBox(width: 24),
                          Icon(Icons.calendar_today, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Annual: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(' 199 USD'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Premium Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('• Unlimited job applications'),
                      const Text('• Priority support'),
                      const Text('• Featured company profile'),
                      const Text('• Early access to new features'),
                      const Text('• And more coming soon!'),
                    ],
                  ),
                ),
              ),
              if (isPremium)
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: const Text('Premium Member', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  subtitle: const Text('You have unlimited job posts and applications.'),
                )
              else
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.grey),
                  title: const Text('Upgrade to Premium'),
                  subtitle: const Text('Unlock unlimited job posts and more features.'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      PremiumUtils.showPremiumUpgradeDialog(context);
                    },
                    child: const Text('Upgrade'),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4, // Settings tab
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Applicants'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Company'),
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
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ApplicationsPage()),
              (route) => false,
            );
          } else if (index == 2) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CompanyProfilePage()),
              (route) => false,
            );
          } else if (index == 3) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const JobPostsPage()),
              (route) => false,
            );
          } // index 4 is settings, do nothing
        },
      ),
    );
  }
}

class ApplicationDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> application;
  final String applicationId;
  const ApplicationDetailsDialog({Key? key, required this.application, required this.applicationId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final app = application;
    final jobseekerId = app['jobseeker_id'];
    final List<String> userInfoOrder = [
      'fullName', 'email', 'phone', 'education', 'experience', 'skills', 'languages', 'about', 'location', 'portfolio', 'preferredJobType', 'cvUrl', 'imageUrl', 'otherDomain', 'domain'
    ];
    final List<String> jobInfoOrder = [
      'job_title', 'company_name', 'job_type', 'salary', 'description', 'cover_letter', 'expected_salary', 'preferred_start_date', 'applied_at', 'status', 'additional_notes'
    ];
    String formatDate(dynamic value) {
      if (value == null) return '';
      if (value is Timestamp) {
        final dt = value.toDate();
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      if (value is DateTime) {
        return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      }
      return value.toString();
    }
    return AlertDialog(
      title: const Text('Application Details'),
      content: SingleChildScrollView(
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
                    ...jobInfoOrder.where((key) => app.containsKey(key) && app[key] != null && app[key].toString().isNotEmpty).map((key) {
                      final isDateField = key == 'applied_at' || key == 'preferred_start_date';
                      return Padding(
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
                            _buildFieldValue(isDateField ? formatDate(app[key]) : app[key]),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatFieldName(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'([a-z])([A-Z])'), r' $2')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
        .join(' ');
  }

  Widget _buildFieldValue(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const Text('-', style: TextStyle(color: Colors.black87, fontSize: 15));
    }
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.map<Widget>((item) => Text(item.toString(), style: const TextStyle(color: Colors.black87, fontSize: 15))).toList(),
      );
    }
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.entries.map<Widget>((e) => Text(' : ', style: const TextStyle(color: Colors.black87, fontSize: 15))).toList(),
      );
    }
    return Text(value.toString(), style: const TextStyle(color: Colors.black87, fontSize: 15));
  }
}

class EmployerAnalyticsPage extends StatelessWidget {
  const EmployerAnalyticsPage({Key? key}) : super(key: key);

  Future<List<QueryDocumentSnapshot>> _fetchApplicationsByJobIds(List<String> jobIds) async {
    if (jobIds.isEmpty) return [];
    // Firestore whereIn supports up to 10 items per query, so batch if needed
    List<QueryDocumentSnapshot> allApps = [];
    for (int i = 0; i < jobIds.length; i += 10) {
      final batchIds = jobIds.sublist(i, i + 10 > jobIds.length ? jobIds.length : i + 10);
      final snap = await FirebaseFirestore.instance
          .collection('applications')
          .where('job_id', whereIn: batchIds)
          .get();
      allApps.addAll(snap.docs);
    }
    return allApps;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('job_posts').where('employer_id', isEqualTo: user.uid).get(),
        builder: (context, jobSnapshot) {
          if (jobSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (jobSnapshot.hasError) {
            return const Center(child: Text('Failed to load analytics', style: TextStyle(color: Colors.red)));
          }
          final jobs = jobSnapshot.data?.docs ?? [];
          final jobIds = jobs.map((doc) => doc.id).toList();
          if (jobIds.length > 30) {
            return const Center(child: Text('Too many job posts for analytics. Please reduce to 30 or fewer.'));
          }
          return FutureBuilder<List<QueryDocumentSnapshot>>(
            future: _fetchApplicationsByJobIds(jobIds),
            builder: (context, appSnapshot) {
              if (appSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (appSnapshot.hasError) {
                return const Center(child: Text('Failed to load analytics', style: TextStyle(color: Colors.red)));
              }
              final applications = appSnapshot.data ?? [];
              // Applications per job post
              final Map<String, int> appsPerJob = {};
              for (final jobId in jobIds) {
                appsPerJob[jobId] = applications.where((a) => a['job_id'] == jobId).length;
              }
              final jobTitles = jobs.map((jobDoc) => (jobDoc.data() as Map<String, dynamic>)['title'] ?? 'Untitled').toList();
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Card(
                    color: Colors.blue.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.work, color: Colors.blue),
                      title: const Text('Total Job Posts'),
                      trailing: Text(jobs.length.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.people, color: Colors.green),
                      title: const Text('Total Applications'),
                      trailing: Text(applications.length.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Applications per Job Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (appsPerJob.values.isNotEmpty ? (appsPerJob.values.reduce((a, b) => a > b ? a : b) + 1).toDouble() : 1),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= jobTitles.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    jobTitles[idx].toString().length > 8
                                        ? jobTitles[idx].toString().substring(0, 8) + '...'
                                        : jobTitles[idx].toString(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                              reservedSize: 40,
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(jobIds.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: appsPerJob[jobIds[i]]?.toDouble() ?? 0,
                                color: Colors.deepPurple,
                                width: 18,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...jobs.map((jobDoc) {
                    final job = jobDoc.data() as Map<String, dynamic>;
                    final jobId = jobDoc.id;
                    final count = appsPerJob[jobId] ?? 0;
                    return Card(
                      child: ListTile(
                        title: Text(job['title'] ?? 'Untitled'),
                        subtitle: Text('Job ID: $jobId'),
                        trailing: Text('$count applicants', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Set to 0 or the appropriate index for Analytics if you want to highlight it
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ApplicationsPage()),
            );
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmployerSettingsPage()),
            );
          }
        },
      ),
    );
  }
} 