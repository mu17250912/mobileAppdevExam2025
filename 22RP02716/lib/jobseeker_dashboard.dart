import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'jobseeker_profile_page.dart';
import 'package:intl/intl.dart';
import 'jobseeker_applications_page.dart';
import 'job_posts_filtered_page.dart';
import 'premium_utils.dart';
import 'notifications.dart'; // Correct import for NotificationsPage

class JobseekerDashboardPage extends StatefulWidget {
  const JobseekerDashboardPage({Key? key}) : super(key: key);

  @override
  State<JobseekerDashboardPage> createState() => _JobseekerDashboardPageState();
}

class _JobseekerDashboardPageState extends State<JobseekerDashboardPage> {
  static bool shouldFocusSearch = false;
  String _searchQuery = '';
  String _searchMode = 'Jobs'; // or 'Applications'
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Helper to check if a job is saved
  Stream<bool> isJobSaved(String userId, String jobId) {
    return FirebaseFirestore.instance
        .collection('saved_jobs')
        .where('user_id', isEqualTo: userId)
        .where('job_id', isEqualTo: jobId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  // Helper to save a job
  Future<void> saveJob(String userId, String jobId, Map<String, dynamic> job) async {
    await FirebaseFirestore.instance.collection('saved_jobs').add({
      'user_id': userId,
      'job_id': jobId,
      'saved_at': FieldValue.serverTimestamp(),
      'job_title': job['title'] ?? '',
      'company_name': job['company_name'] ?? '',
      'domain': job['domain'] ?? '',
    });
    // Add notification for jobseeker
    await FirebaseFirestore.instance.collection('notifications').add({
      'user_id': userId,
      'type': 'job_saved',
      'message': 'You saved the job: \'${job['title'] ?? ''}\' at ${job['company_name'] ?? ''}',
      'job_id': jobId,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Helper to unsave a job
  Future<void> unsaveJob(String userId, String jobId) async {
    final query = await FirebaseFirestore.instance
        .collection('saved_jobs')
        .where('user_id', isEqualTo: userId)
        .where('job_id', isEqualTo: jobId)
        .limit(1)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // Helper to check if a user has applied to a job
  Stream<bool> hasUserApplied(String userId, String jobId) {
    return FirebaseFirestore.instance
        .collection('applications')
        .where('jobseeker_id', isEqualTo: userId)
        .where('job_id', isEqualTo: jobId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_JobseekerDashboardPageState.shouldFocusSearch) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        FocusScope.of(context).requestFocus(_searchFocusNode);
        _JobseekerDashboardPageState.shouldFocusSearch = false;
      }
    });
    final user = FirebaseAuth.instance.currentUser;
    return FutureBuilder<DocumentSnapshot>(
      future: user != null ? FirebaseFirestore.instance.collection('users').doc(user.uid).get() : null,
      builder: (context, snapshot) {
        String displayName = 'Jobseeker';
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          displayName = data['name'] ?? 'Jobseeker';
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
              StreamBuilder<QuerySnapshot>(
                stream: user == null
                    ? null
                    : FirebaseFirestore.instance
                        .collection('notifications')
                        .where('user_id', isEqualTo: user.uid)
                        .where('read', isEqualTo: false)
                        .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData && snapshot.data != null) {
                    unreadCount = snapshot.data!.docs.length;
                  }
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.blueGrey),
                        tooltip: 'Notifications',
                        onPressed: () async {
                          // Mark all as read when opening notifications page
                          final unread = snapshot.data?.docs ?? [];
                          for (var doc in unread) {
                            doc.reference.update({'read': true});
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsPage()),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            child: Center(
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const JobseekerProfilePage()),
                      );
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
                      Icon(Icons.lens, size: 14, color: Colors.orange), // Lint icon
                    ],
                  ),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const JobseekerDashboardPage()),
                      (route) => false,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: const Text('Job Posts'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JobPostsFilteredPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue, size: 28), // Make icon blue and larger
                  title: Row(
                    children: const [
                      Text('My Applications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)), // Make text blue and bold
                      SizedBox(width: 8),
                      Icon(Icons.lens, size: 14, color: Colors.orange),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JobseekerApplicationsPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: const Text('Saved Jobs'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JobseekerSavedJobsPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('My Profile'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JobseekerProfilePage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JobseekerSettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
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
                          focusNode: _searchFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Search jobs or applications...', // updated hint
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
                          DropdownMenuItem(value: 'Jobs', child: Text('Jobs')),
                          DropdownMenuItem(value: 'Applications', child: Text('Applications')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _searchMode = value;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_list, color: Colors.blue),
                        tooltip: 'Filter',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_searchQuery.isNotEmpty && _searchMode == 'Jobs')
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('job_posts')
                        .orderBy('created_at', descending: true)
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
                      final filteredJobs = jobs.where((doc) {
                        final job = doc.data() as Map<String, dynamic>;
                        final query = _searchQuery.toLowerCase();
                        return (job['title'] ?? '').toString().toLowerCase().contains(query) ||
                               (job['company_name'] ?? '').toString().toLowerCase().contains(query) ||
                               (job['domain'] ?? '').toString().toLowerCase().contains(query) ||
                               (job['industry'] ?? '').toString().toLowerCase().contains(query);
                      }).toList();
                      if (filteredJobs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No jobs found.')),
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
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money, color: Colors.green, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        job['salary'] ?? '',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const Spacer(),
                                                                              ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          onPressed: () async {
                                            if (await PremiumUtils.hasReachedApplicationLimit()) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Upgrade to Premium'),
                                                  content: const Text('You have reached the free application limit (5 jobs). Upgrade to premium to apply for unlimited jobs.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        PremiumUtils.showPremiumUpgradeDialog(context);
                                                      },
                                                      child: const Text('Upgrade to Premium'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              return;
                                            }
                                            _showApplyDialog(context, job, filteredJobs[i].id);
                                          },
                                        child: const Text('Apply'),
                                      ),
                                      const SizedBox(width: 8),
                                      StreamBuilder<bool>(
                                        stream: user == null ? Stream.value(false) : isJobSaved(user.uid, filteredJobs[i].id),
                                        builder: (context, savedSnapshot) {
                                          final isSaved = savedSnapshot.data ?? false;
                                          return OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: isSaved ? Colors.blue : Colors.transparent,
                                              foregroundColor: isSaved ? Colors.white : Colors.blue,
                                              side: BorderSide(color: isSaved ? Colors.blue : Colors.blue),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            onPressed: user == null
                                                ? null
                                                : () async {
                                                    if (isSaved) {
                                                      await unsaveJob(user.uid, filteredJobs[i].id);
                                                    } else {
                                                      await saveJob(user.uid, filteredJobs[i].id, job);
                                                    }
                                                  },
                                            child: Text(isSaved ? 'Saved' : 'Save'),
                                          );
                                        },
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
                if (_searchQuery.isNotEmpty && _searchMode == 'Applications' && user != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('applications')
                        .where('jobseeker_id', isEqualTo: user.uid)
                        .orderBy(FieldPath.documentId, descending: true)
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
                        return (app['job_title'] ?? '').toString().toLowerCase().contains(query) ||
                               (app['company_name'] ?? '').toString().toLowerCase().contains(query) ||
                               (app['domain'] ?? '').toString().toLowerCase().contains(query) ||
                               (app['industry'] ?? '').toString().toLowerCase().contains(query);
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
                          final appliedAt = app['applied_at'] != null && app['applied_at'] is Timestamp
                              ? (app['applied_at'] as Timestamp).toDate()
                              : null;
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
                                      Icon(Icons.description, color: Colors.blue.shade400),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          app['job_title'] ?? '',
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
                                          app['status'] ?? '',
                                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    app['company_name'] ?? '',
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                  if (appliedAt != null)
                                    Text(
                                      'Applied on ${appliedAt.day}/${appliedAt.month}/${appliedAt.year}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: user == null
                            ? null
                            : FirebaseFirestore.instance
                                .collection('applications')
                                .where('jobseeker_id', isEqualTo: user.uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          int appliedJobs = snapshot.data?.docs.length ?? 0;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const JobseekerApplicationsPage()),
                              );
                            },
                            child: _DashboardCard(
                              icon: Icons.description_outlined,
                              label: 'My Applications',
                              value: appliedJobs.toString(),
                              color: Colors.blue,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: user == null
                            ? null
                            : FirebaseFirestore.instance
                                .collection('saved_jobs')
                                .where('user_id', isEqualTo: user.uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          int savedJobs = snapshot.data?.docs.length ?? 0;
                          return _DashboardCard(
                            icon: Icons.bookmark_outline,
                            label: 'Saved Jobs',
                            value: savedJobs.toString(),
                            color: Colors.green,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Premium Status and Application Limit
                FutureBuilder<bool>(
                  future: PremiumUtils.isPremium(),
                  builder: (context, premiumSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: user == null
                          ? null
                          : FirebaseFirestore.instance
                              .collection('applications')
                              .where('jobseeker_id', isEqualTo: user.uid)
                              .snapshots(),
                      builder: (context, appsSnapshot) {
                        final isPremium = premiumSnapshot.data ?? false;
                        final applicationCount = appsSnapshot.data?.docs.length ?? 0;
                        final remainingApplications = isPremium ? -1 : (5 - applicationCount);
                        
                        if (isPremium) {
                          return Card(
                            color: Colors.amber[50],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Premium Member',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const Text(
                                          'Unlimited applications available',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return Card(
                            color: remainingApplications <= 0 ? Colors.red[50] : Colors.blue[50],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    remainingApplications <= 0 ? Icons.warning : Icons.info,
                                    color: remainingApplications <= 0 ? Colors.red : Colors.blue,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          remainingApplications <= 0 
                                              ? 'Application Limit Reached'
                                              : '$remainingApplications applications remaining',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: remainingApplications <= 0 ? Colors.red : Colors.blue,
                                          ),
                                        ),
                                        Text(
                                          remainingApplications <= 0
                                              ? 'Upgrade to premium for unlimited applications'
                                              : 'Free tier: 5 applications per month',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (remainingApplications <= 0)
                                    ElevatedButton(
                                      onPressed: () => PremiumUtils.showPremiumUpgradeDialog(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text('Upgrade'),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Available Jobs (Filtered by Domain)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Jobs Matching Your Domain',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See all'),
                    ),
                  ],
                ),
                // Fetch user's domain and filter jobs
                FutureBuilder<DocumentSnapshot>(
                  future: user != null ? FirebaseFirestore.instance.collection('jobseeker_profiles').doc(user.uid).get() : null,
                  builder: (context, profileSnapshot) {
                    if (profileSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    String? userDomain;
                    if (profileSnapshot.hasData && profileSnapshot.data != null && profileSnapshot.data!.data() != null) {
                      final profileData = profileSnapshot.data!.data() as Map<String, dynamic>;
                      userDomain = profileData['domain'];
                    }
                    
                    if (userDomain == null || userDomain.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please set your domain/industry in your profile to see matching jobs.',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Map user domain to company industry for matching
                    String? matchingIndustry;
                    switch (userDomain) {
                      case 'ICT':
                        matchingIndustry = 'ICT';
                        break;
                      case 'Healthcare':
                        matchingIndustry = 'Healthcare';
                        break;
                      case 'Education':
                        matchingIndustry = 'Education';
                        break;
                      case 'Finance':
                        matchingIndustry = 'Finance';
                        break;
                      case 'Agriculture':
                        matchingIndustry = 'Agriculture';
                        break;
                      case 'Other':
                        // For "Other" domain, we need to get the specified domain from the profile
                        if (profileSnapshot.hasData && profileSnapshot.data != null && profileSnapshot.data!.data() != null) {
                          final profileData = profileSnapshot.data!.data() as Map<String, dynamic>;
                          final otherDomain = profileData['otherDomain'];
                          if (otherDomain != null && otherDomain.isNotEmpty) {
                            matchingIndustry = otherDomain;
                          } else {
                            matchingIndustry = 'Other';
                          }
                        } else {
                          matchingIndustry = 'Other';
                        }
                        break;
                      default:
                        matchingIndustry = 'Other';
                    }
                    
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('job_posts')
                          .orderBy('created_at', descending: true)
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
                          return Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.work, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No jobs available in your domain ($userDomain) at the moment.',
                                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
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
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.attach_money, color: Colors.green, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          job['salary'] ?? '',
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const Spacer(),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          onPressed: () async {
                                            if (await PremiumUtils.hasReachedApplicationLimit()) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Upgrade to Premium'),
                                                  content: const Text('You have reached the free application limit (5 jobs). Upgrade to premium to apply for unlimited jobs.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        PremiumUtils.showPremiumUpgradeDialog(context);
                                                      },
                                                      child: const Text('Upgrade to Premium'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              return;
                                            }
                                            _showApplyDialog(context, job, jobs[i].id);
                                          },
                                          child: StreamBuilder<bool>(
                                            stream: user == null ? Stream.value(false) : hasUserApplied(user.uid, jobs[i].id),
                                            builder: (context, appliedSnapshot) {
                                              final applied = appliedSnapshot.data ?? false;
                                              return Text(applied ? 'Applied' : 'Apply');
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StreamBuilder<bool>(
                                          stream: user == null ? Stream.value(false) : isJobSaved(user.uid, jobs[i].id),
                                          builder: (context, savedSnapshot) {
                                            final isSaved = savedSnapshot.data ?? false;
                                            return OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor: isSaved ? Colors.blue : Colors.transparent,
                                                foregroundColor: isSaved ? Colors.white : Colors.blue,
                                                side: BorderSide(color: isSaved ? Colors.blue : Colors.blue),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              ),
                                              onPressed: user == null
                                                  ? null
                                                  : () async {
                                                      if (isSaved) {
                                                        await unsaveJob(user.uid, jobs[i].id);
                                                      } else {
                                                        await saveJob(user.uid, jobs[i].id, job);
                                                      }
                                                    },
                                              child: Text(isSaved ? 'Saved' : 'Save'),
                                            );
                                          },
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
                // Recent Applications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Applications (My Applications)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const JobseekerApplicationsPage()),
                        );
                      },
                      child: const Text('See all'),
                    ),
                  ],
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: user == null
                      ? null
                      : FirebaseFirestore.instance
                          .collection('applications')
                          .where('jobseeker_id', isEqualTo: user.uid)
                          .orderBy(FieldPath.documentId, descending: true)
                          .limit(3)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Failed to load recent applications', style: TextStyle(color: Colors.red)));
                    }
                    final applications = snapshot.data?.docs ?? [];
                    if (applications.isEmpty) {
                      return const Center(child: Text('No recent applications.'));
                    }
                    return Column(
                      children: applications.map((doc) {
                        final app = doc.data() as Map<String, dynamic>;
                        final appliedAt = app['applied_at'] != null && app['applied_at'] is Timestamp
                            ? (app['applied_at'] as Timestamp).toDate()
                            : null;
                        return _ApplicationCard(
                          companyName: app['company_name'] ?? 'Unknown Company',
                          position: app['job_title'] ?? 'Unknown Job',
                          status: app['status'] ?? 'Pending',
                          appliedDate: appliedAt != null
                              ? '${appliedAt.day}/${appliedAt.month}/${appliedAt.year}'
                              : '',
                        );
                      }).toList(),
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
                    icon: const Icon(Icons.search),
                    label: const Text('Browse All Jobs'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const JobPostsFilteredPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Bottom navigation (placeholder)
          bottomNavigationBar: JobseekerBottomNavBar(currentIndex: 0, context: context),
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

class _ApplicationCard extends StatelessWidget {
  final String companyName;
  final String position;
  final String status;
  final String appliedDate;
  const _ApplicationCard({
    required this.companyName,
    required this.position,
    required this.status,
    required this.appliedDate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'under review':
        statusColor = Colors.orange;
        break;
      case 'shortlisted':
        statusColor = Colors.blue;
        break;
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.business, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(position, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(appliedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder pages for jobseeker features
class JobseekerSavedJobsPage extends StatelessWidget {
  const JobseekerSavedJobsPage({Key? key}) : super(key: key);

  // Helper to unsave a job (reuse from dashboard)
  Future<void> unsaveJob(String userId, String jobId) async {
    final query = await FirebaseFirestore.instance
        .collection('saved_jobs')
        .where('user_id', isEqualTo: userId)
        .where('job_id', isEqualTo: jobId)
        .limit(1)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Jobs')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Jobs')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('saved_jobs')
            .where('user_id', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load saved jobs', style: TextStyle(color: Colors.red)));
          }
          final savedJobs = snapshot.data?.docs ?? [];
          if (savedJobs.isEmpty) {
            return const Center(child: Text('No saved jobs.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: savedJobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final job = savedJobs[i].data() as Map<String, dynamic>;
              final jobId = job['job_id'] ?? '';
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('job_posts').doc(jobId).get(),
                builder: (context, jobSnapshot) {
                  if (jobSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!jobSnapshot.hasData || !jobSnapshot.data!.exists) {
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Job post not found.', style: const TextStyle(color: Colors.red)),
                      ),
                    );
                  }
                  final jobPost = jobSnapshot.data!.data() as Map<String, dynamic>;
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          Text(jobPost['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                          Text(jobPost['company_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                          const SizedBox(height: 4),
                          if (jobPost['location'] != null && jobPost['location'].toString().isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.red, size: 18),
                                const SizedBox(width: 4),
                                Text(jobPost['location'], style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          if (jobPost['created_at'] != null && jobPost['created_at'] is Timestamp)
                            Builder(
                              builder: (context) {
                                final createdAt = (jobPost['created_at'] as Timestamp).toDate();
                                return Text(
                                  'Published at: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                  style: const TextStyle(color: Colors.grey),
                                );
                              },
                            ),
                      const SizedBox(height: 8),
                          if (jobPost['type'] != null && jobPost['type'].toString().isNotEmpty)
                            Text('Type: ${jobPost['type']}', style: const TextStyle(color: Colors.deepPurple)),
                          if (jobPost['description'] != null && jobPost['description'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(jobPost['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                            ),
                          if (jobPost['domain'] != null && jobPost['domain'].toString().isNotEmpty)
                            Text('Domain: ${jobPost['domain']}', style: const TextStyle(color: Colors.blue)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                                onPressed: () async {
                                  if (await PremiumUtils.hasReachedApplicationLimit()) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Upgrade to Premium'),
                                        content: const Text('You have reached the free application limit. Upgrade to premium to apply for more jobs.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                            onPressed: () {
                                              // TODO: Implement premium upgrade flow
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Upgrade'),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                              FirebaseFirestore.instance.collection('job_posts').doc(jobId).get().then((doc) {
                                if (doc.exists) {
                                  final jobData = doc.data() as Map<String, dynamic>;
                                  _showApplyDialog(context, jobData, jobId);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Job post not found.')),
                                  );
                                }
                              });
                            },
                            child: const Text('Apply'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () async {
                              await unsaveJob(user.uid, jobId);
                            },
                            child: const Text('Unsave'),
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
      bottomNavigationBar: JobseekerBottomNavBar(currentIndex: 2, context: context),
    );
  }
}

class JobseekerSettingsPage extends StatelessWidget {
  const JobseekerSettingsPage({Key? key}) : super(key: key);
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
                      const Text('• Featured profile for employers'),
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
                  subtitle: const Text('You have unlimited job applications.'),
                )
              else
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.grey),
                  title: const Text('Upgrade to Premium'),
                  subtitle: const Text('Apply for unlimited jobs and unlock more features.'),
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
      bottomNavigationBar: JobseekerBottomNavBar(currentIndex: 5, context: context),
    );
  }
} 

void _showApplyDialog(BuildContext context, Map<String, dynamic> job, String jobId) {
  final coverLetterController = TextEditingController();
  final expectedSalaryController = TextEditingController();
  final additionalNotesController = TextEditingController();
  DateTime? preferredStartDate;
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Apply for Job'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Job Summary
                    Text(job['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(job['company_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(job['description'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (job['type'] != null) ...[
                          const Icon(Icons.work_outline, size: 18, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(job['type'], style: const TextStyle(color: Colors.blue)),
                          const SizedBox(width: 12),
                        ],
                        if (job['salary'] != null && job['salary'].toString().isNotEmpty) ...[
                          const Icon(Icons.attach_money, size: 18, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(job['salary'], style: const TextStyle(color: Colors.green)),
                        ],
                      ],
                    ),
                    const Divider(height: 24),
                    // Application Fields
                    TextFormField(
                      controller: coverLetterController,
                      decoration: const InputDecoration(
                        labelText: 'Cover Letter (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (picked != null) setState(() => preferredStartDate = picked);
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Preferred Start Date',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: preferredStartDate != null ? DateFormat('yyyy-MM-dd').format(preferredStartDate!) : '',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: expectedSalaryController,
                      decoration: const InputDecoration(
                        labelText: 'Expected Salary (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: additionalNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (user == null) return;
                  if (!_formKey.currentState!.validate()) return;
                  await FirebaseFirestore.instance.collection('applications').add({
                    'jobseeker_id': user.uid,
                    'job_id': jobId,
                    'job_title': job['title'] ?? '',
                    'company_name': job['company_name'] ?? '',
                    'description': job['description'] ?? '',
                    'job_type': job['type'] ?? '',
                    'salary': job['salary'] ?? '',
                    'cover_letter': coverLetterController.text.trim(),
                    'preferred_start_date': preferredStartDate != null ? Timestamp.fromDate(preferredStartDate!) : null,
                    'expected_salary': expectedSalaryController.text.trim(),
                    'additional_notes': additionalNotesController.text.trim(),
                    'status': 'Pending',
                    'applied_at': FieldValue.serverTimestamp(),
                  });
                  // Add notification for jobseeker
                  await FirebaseFirestore.instance.collection('notifications').add({
                    'user_id': user.uid,
                    'type': 'application_submitted',
                    'message': 'You applied for the job: \'${job['title'] ?? ''}\' at ${job['company_name'] ?? ''}',
                    'job_id': jobId,
                    'created_at': FieldValue.serverTimestamp(),
                  });
                  // Notify employer
                  final jobPostDoc = await FirebaseFirestore.instance.collection('job_posts').doc(jobId).get();
                  final employerId = jobPostDoc.data()?['employer_id'];
                  if (employerId != null) {
                    await FirebaseFirestore.instance.collection('notifications').add({
                      'user_id': employerId,
                      'type': 'success',
                      'message': 'A new jobseeker applied to your job: \'${job['title'] ?? ''}\'',
                      'created_at': FieldValue.serverTimestamp(),
                    });
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Application submitted!')),
                  );
                },
                child: const Text('Submit Application'),
              ),
            ],
          );
        },
      );
    },
  );
} 

// Add JobseekerBottomNavBar widget
class JobseekerBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final BuildContext context;
  const JobseekerBottomNavBar({required this.currentIndex, required this.context, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
        BottomNavigationBarItem(icon: Icon(Icons.description, color: Colors.blue), label: 'My Applications'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      onTap: (index) {
        if (index == 1) {
          _JobseekerDashboardPageState.shouldFocusSearch = true;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const JobseekerDashboardPage()),
            (route) => false,
          );
          return;
        }
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const JobseekerDashboardPage()),
            (route) => false,
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JobseekerSavedJobsPage()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JobseekerApplicationsPage()),
          );
        } else if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JobseekerProfilePage()),
          );
        } else if (index == 5) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JobseekerSettingsPage()),
          );
        }
      },
    );
  }
} 

// Helper to add a premium update notification
Future<void> addPremiumNotification(String userId, String message) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'user_id': userId,
    'type': 'premium_update',
    'message': message,
    'created_at': FieldValue.serverTimestamp(),
  });
} 