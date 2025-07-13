import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'employer_dashboard.dart'; // For AddJobPostPage
import 'employer_dashboard.dart'; // For DashboardPage
import 'applications_page.dart'; // For ApplicationsPage
import 'company_profile_page.dart'; // For CompanyProfilePage
import 'premium_utils.dart'; // For PremiumUtils

class JobPostsPage extends StatelessWidget {
  const JobPostsPage({Key? key}) : super(key: key);

  Future<void> _deleteJob(BuildContext context, String jobId) async {
    await FirebaseFirestore.instance.collection('job_posts').doc(jobId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Job post deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Posts')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Job Posts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('job_posts')
            .where('employer_id', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load job posts', style: TextStyle(color: Colors.red)));
          }
          final jobs = snapshot.data?.docs ?? [];
          return _JobPostsList(jobs: jobs, user: user);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
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
            // Already on Job Posts
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

class _JobPostsList extends StatelessWidget {
  final List<QueryDocumentSnapshot> jobs;
  final User user;
  const _JobPostsList({required this.jobs, required this.user});

  void _editJob(BuildContext context, String jobId, Map<String, dynamic> jobData) async {
    final _formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: jobData['title'] ?? '');
    final descController = TextEditingController(text: jobData['description'] ?? '');
    final salaryController = TextEditingController(text: jobData['salary'] ?? '');
    final companyNameController = TextEditingController(text: jobData['company_name'] ?? '');
    final locationController = TextEditingController(text: jobData['location'] ?? '');
    String? jobType = jobData['type'];
    String? domain = jobData['domain'];
    bool loading = false;
    String? error;

    // Autofill company name if empty
    if ((companyNameController.text.isEmpty || companyNameController.text == '')) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('profile').doc(user.uid).get();
        final data = doc.data();
        if (data != null && data['companyName'] != null) {
          companyNameController.text = data['companyName'];
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Job Post'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: companyNameController,
                        decoration: const InputDecoration(labelText: 'Company Name'),
                        validator: (value) => value == null || value.isEmpty ? 'Enter company name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Job Title'),
                        validator: (value) => value == null || value.isEmpty ? 'Enter job title' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: domain,
                        decoration: const InputDecoration(labelText: 'Domain/Industry/Field'),
                        items: const [
                          DropdownMenuItem(value: 'ICT', child: Text('ICT')),
                          DropdownMenuItem(value: 'Healthcare', child: Text('Healthcare')),
                          DropdownMenuItem(value: 'Education', child: Text('Education')),
                          DropdownMenuItem(value: 'Finance', child: Text('Finance')),
                          DropdownMenuItem(value: 'Agriculture', child: Text('Agriculture')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) => setState(() => domain = value),
                        validator: (value) => value == null ? 'Select domain/industry/field' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: 'Job Description'),
                        maxLines: 3,
                        validator: (value) => value == null || value.isEmpty ? 'Enter job description' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: jobType,
                        decoration: const InputDecoration(labelText: 'Job Type'),
                        items: const [
                          DropdownMenuItem(value: 'Full Time', child: Text('Full Time')),
                          DropdownMenuItem(value: 'Part Time', child: Text('Part Time')),
                          DropdownMenuItem(value: 'Contract', child: Text('Contract')),
                          DropdownMenuItem(value: 'Internship', child: Text('Internship')),
                        ],
                        onChanged: (value) => setState(() => jobType = value),
                        validator: (value) => value == null ? 'Select job type' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: salaryController,
                        decoration: const InputDecoration(labelText: 'Salary'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? 'Enter salary' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(labelText: 'Location (city/District/sector)'),
                        validator: (value) => value == null || value.isEmpty ? 'Enter location' : null,
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(error!, style: const TextStyle(color: Colors.red)),
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
                  onPressed: loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => loading = true);
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            await FirebaseFirestore.instance.collection('job_posts').doc(jobId).update({
                              'company_name': companyNameController.text.trim(),
                              'title': titleController.text.trim(),
                              'description': descController.text.trim(),
                              'type': jobType,
                              'salary': salaryController.text.trim(),
                              'domain': domain,
                              'location': locationController.text.trim(),
                              'employer_id': user?.uid,
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Job post updated!')),
                            );
                          } catch (e) {
                            setState(() => error = 'Failed to update job.');
                          } finally {
                            setState(() => loading = false);
                          }
                        },
                  child: loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        jobs.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.work_outline, size: 64, color: Colors.blueGrey),
                      const SizedBox(height: 16),
                      const Text('No job posts yet.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Your UID: ${user.uid}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 24),
                      FutureBuilder<bool>(
                        future: PremiumUtils.isPremium(),
                        builder: (context, premiumSnapshot) {
                          final isPremium = premiumSnapshot.data ?? false;
                          if (!isPremium && jobs.length >= 5) {
                            return ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Upgrade to Premium'),
                                    content: const Text('You have reached the free limit of 5 job posts. Upgrade to premium to post more jobs.'),
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
                                        child: const Text('Upgrade'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Upgrade to Premium'),
                            );
                          }
                          return ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Job Post'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddJobPostPage()),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final job = jobs[i].data() as Map<String, dynamic>;
                  final jobId = jobs[i].id;
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                label: const Text('Edit'),
                                onPressed: () {
                                  _editJob(context, jobId, job);
                                },
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text('Delete'),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Job Post'),
                                      content: const Text('Are you sure you want to delete this job post?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance.collection('job_posts').doc(jobId).delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Job post deleted.')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FutureBuilder<bool>(
            future: PremiumUtils.isPremium(),
            builder: (context, premiumSnapshot) {
              final isPremium = premiumSnapshot.data ?? false;
              if (!isPremium && jobs.length >= 5) {
                return FloatingActionButton.extended(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Upgrade to Premium'),
                        content: const Text('You have reached the free limit of 5 job posts. Upgrade to premium to post more jobs.'),
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
                            child: const Text('Upgrade'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock),
                  label: const Text('Upgrade to Post'),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                );
              }
              return FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddJobPostPage()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Job Post'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }
} 