import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'jobseeker_dashboard.dart';

class JobPostsFilteredPage extends StatelessWidget {
  const JobPostsFilteredPage({Key? key}) : super(key: key);

  void _showJobDetailsDialog(BuildContext context, Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(job['title'] ?? 'Job Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Company: ${job['company_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Type: ${job['type'] ?? ''}'),
                const SizedBox(height: 8),
                Text('Domain: ${job['domain'] ?? ''}'),
                const SizedBox(height: 8),
                Text('Location: ${job['location'] ?? ''}'),
                const SizedBox(height: 8),
                Text('Salary: ${job['salary'] ?? ''}'),
                const SizedBox(height: 8),
                Text('Description:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(job['description'] ?? ''),
                const SizedBox(height: 8),
                if (job['created_at'] != null && job['created_at'] is Timestamp)
                  Text('Posted: ${DateFormat('yyyy-MM-dd').format((job['created_at'] as Timestamp).toDate())}'),
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
      },
    );
  }

  void _showJobApplySummaryDialog(BuildContext context, Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Application'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Job Title: ${job['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Company: ${job['company_name'] ?? ''}'),
                const SizedBox(height: 8),
                Text('Type: ${job['type'] ?? ''}'),
                const SizedBox(height: 8),
                Text('Location: ${job['location'] ?? ''}'),
                const SizedBox(height: 8),
                Text('Salary: ${job['salary'] ?? ''}'),
                const SizedBox(height: 8),
                Text('Description:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(job['description'] ?? ''),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Application submitted!')),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Filtered Jobs')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('jobseeker_profiles').doc(user.uid).get(),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Filtered Jobs')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!profileSnapshot.hasData || profileSnapshot.data == null || profileSnapshot.data!.data() == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Filtered Jobs')),
            body: const Center(child: Text('Profile not found.')),
          );
        }
        final profile = profileSnapshot.data!.data() as Map<String, dynamic>;
        final userDomain = (profile['domain'] ?? '').toString().toLowerCase();
        final userLocation = (profile['location'] ?? '').toString().toLowerCase();
        return Scaffold(
          appBar: AppBar(title: const Text('Jobs Matching Your Domain & Location')),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('job_posts')
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load jobs', style: TextStyle(color: Colors.red)));
              }
              final jobs = snapshot.data?.docs ?? [];
              final filteredJobs = jobs.where((doc) {
                final job = doc.data() as Map<String, dynamic>;
                final jobDomain = (job['domain'] ?? '').toString().toLowerCase();
                final jobLocation = (job['location'] ?? '').toString().toLowerCase();
                // Show if either domain or location matches (or both)
                return (userDomain.isNotEmpty && jobDomain == userDomain) ||
                       (userLocation.isNotEmpty && jobLocation == userLocation);
              }).toList();
              if (filteredJobs.isEmpty) {
                return const Center(child: Text('No jobs found for your domain or location.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredJobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final job = filteredJobs[i].data() as Map<String, dynamic>;
                  final jobId = filteredJobs[i].id;
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                job['location'] ?? '',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
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
                                onPressed: user == null ? null : () async {
                                  final hasApplied = await FirebaseFirestore.instance
                                      .collection('applications')
                                      .where('jobseeker_id', isEqualTo: user.uid)
                                      .where('job_id', isEqualTo: jobId)
                                      .limit(1)
                                      .get();
                                  if (hasApplied.docs.isNotEmpty) return;
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Apply for Job'),
                                      content: Text('Are you sure you want to apply for "${job['title'] ?? ''}" at "${job['company_name'] ?? ''}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Apply'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await FirebaseFirestore.instance.collection('applications').add({
                                      'jobseeker_id': user.uid,
                                      'job_id': jobId,
                                      'job_title': job['title'] ?? '',
                                      'company_name': job['company_name'] ?? '',
                                      'description': job['description'] ?? '',
                                      'job_type': job['type'] ?? '',
                                      'salary': job['salary'] ?? '',
                                      'status': 'Pending',
                                      'applied_at': FieldValue.serverTimestamp(),
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Application submitted!')),
                                    );
                                  }
                                },
                                child: StreamBuilder<bool>(
                                  stream: user == null ? Stream.value(false) : hasUserApplied(user.uid, jobId),
                                  builder: (context, appliedSnapshot) {
                                    final applied = appliedSnapshot.data ?? false;
                                    return Text(applied ? 'Applied' : 'Apply Now');
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () {
                                  _showJobDetailsDialog(context, job);
                                },
                                child: const Text('View Details'),
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
          bottomNavigationBar: JobseekerBottomNavBar(currentIndex: 1, context: context),
        );
      },
    );
  }
} 