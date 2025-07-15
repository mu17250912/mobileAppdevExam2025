// lib/screens/job_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobListingsScreen extends StatefulWidget {
  const JobListingsScreen({super.key});

  @override
  State<JobListingsScreen> createState() => _JobListingsScreenState();
}

class _JobListingsScreenState extends State<JobListingsScreen> {
  bool _isPremium = false;
  bool _loading = true;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  String _searchQuery = '';
  String? _selectedCategory;
  final List<String> _categories = ['All', 'Design', 'Writing', 'Tutoring', 'Delivery', 'Other'];
  String _sortOption = 'All';
  final List<String> _sortOptions = ['All', 'Highest Pay', 'Newest'];
  Map<String, String> _myApplications = {};

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _loadMyApplications();
  }

  Future<void> _loadJobs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final isPremium = doc.data()?['premium'] ?? false;

      final snapshot = await FirebaseFirestore.instance.collection('jobs').get();

      setState(() {
        _isPremium = isPremium;
        _loading = false;
        _jobs = snapshot.docs.map((doc) {
          final data = doc.data();
          data['docId'] = doc.id; // Add document ID for reference
          return data;
        }).toList();
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  Future<void> _loadMyApplications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final appsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('applications')
          .get();
      
      setState(() {
        _myApplications = {
          for (final doc in appsSnap.docs)
            doc.data()['jobId']: doc.data()['status'] as String,
        };
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _applyFilters() {
    setState(() {
      List<Map<String, dynamic>> jobs = List.from(_jobs);
      
      // Apply sorting
      if (_isPremium) {
        if (_sortOption == 'Highest Pay') {
          jobs.sort((a, b) => ((b['pay'] ?? 0) as num).compareTo((a['pay'] ?? 0) as num));
        } else if (_sortOption == 'Newest') {
          jobs.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp?;
            final bTime = b['timestamp'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
        }
      }
      
      // Apply filters
      _filteredJobs = jobs.where((job) {
        final matchesSearch = _searchQuery.isEmpty ||
            (job['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (job['description']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        final matchesCategory = _selectedCategory == null ||
            _selectedCategory == 'All' ||
            (job['category'] == _selectedCategory);
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _addJob() async {
    if (!_isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upgrade to Premium to post jobs')),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final payController = TextEditingController();
    String? selectedCategory = _categories.firstWhere((c) => c != 'All', orElse: () => 'Other');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post New Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController, 
                decoration: const InputDecoration(labelText: 'Job Title'),
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController, 
                decoration: const InputDecoration(labelText: 'Job Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: payController,
                decoration: const InputDecoration(labelText: 'Pay Amount (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: _categories.where((c) => c != 'All').map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                )).toList(),
                onChanged: (val) => selectedCategory = val,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final desc = descriptionController.text.trim();
              final pay = double.tryParse(payController.text.trim()) ?? 0.0;
              
              if (title.isNotEmpty && desc.isNotEmpty && selectedCategory != null) {
                try {
                  await FirebaseFirestore.instance.collection('jobs').add({
                    'title': title,
                    'description': desc,
                    'category': selectedCategory,
                    'pay': pay,
                    'timestamp': FieldValue.serverTimestamp(),
                    'posterId': FirebaseAuth.instance.currentUser?.uid ?? '',
                    'posterName': FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
                  });
                  
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadJobs();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Job posted successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error posting job: $e')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
              }
            },
            child: const Text('Post Job'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyForJob(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('applications')
          .doc(jobId)
          .set({
            'jobId': jobId, 
            'status': 'applied',
            'appliedAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
          });
      
      _loadMyApplications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully applied for job!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying for job: $e')),
        );
      }
    }
  }

  Future<void> _chatWithPoster(Map<String, dynamic> job) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final jobId = job['docId'] ?? '';
    final posterId = job['posterId'] ?? '';
    final jobTitle = job['title'] ?? '';
    
    if (jobId.isEmpty || posterId.isEmpty || jobTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open chat: missing job information')),
      );
      return;
    }
    
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'gigId': jobId,
        'posterId': posterId,
        'gigTitle': jobTitle,
        'applicantId': user.uid,
      },
    );
  }

  Future<void> _editJob(Map<String, dynamic> job) async {
    if (!_isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium feature only')),
      );
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid != job['posterId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only edit your own jobs')),
      );
      return;
    }

    final titleController = TextEditingController(text: job['title'] ?? '');
    final descriptionController = TextEditingController(text: job['description'] ?? '');
    final payController = TextEditingController(text: (job['pay'] ?? 0).toString());
    String? selectedCategory = job['category'] ?? 'Other';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController, 
                decoration: const InputDecoration(labelText: 'Job Title'),
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController, 
                decoration: const InputDecoration(labelText: 'Job Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: payController,
                decoration: const InputDecoration(labelText: 'Pay Amount (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: _categories.where((c) => c != 'All').map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                )).toList(),
                onChanged: (val) => selectedCategory = val,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final desc = descriptionController.text.trim();
              final pay = double.tryParse(payController.text.trim()) ?? 0.0;
              
              if (title.isNotEmpty && desc.isNotEmpty && selectedCategory != null) {
                try {
                  await FirebaseFirestore.instance.collection('jobs').doc(job['docId']).update({
                    'title': title,
                    'description': desc,
                    'category': selectedCategory,
                    'pay': pay,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadJobs();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Job updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating job: $e')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
              }
            },
            child: const Text('Update Job'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Listings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Listings'),
        actions: [
          if (_isPremium)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Post New Job',
              onPressed: _addJob,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search jobs',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory ?? 'All',
                        items: _categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        )).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                          _applyFilters();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (_isPremium) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sortOption,
                          items: _sortOptions.map((opt) => DropdownMenuItem(
                            value: opt,
                            child: Text(opt),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              _sortOption = val!;
                            });
                            _applyFilters();
                          },
                          decoration: const InputDecoration(
                            labelText: 'Sort by',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Jobs List
          Expanded(
            child: _filteredJobs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No jobs found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('Try adjusting your search or filters', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = _filteredJobs[index];
                      final jobId = job['docId'] ?? '';
                      final status = _myApplications[jobId];
                      final isMyJob = job['posterId'] == FirebaseAuth.instance.currentUser?.uid;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      job['title'] ?? 'Untitled Job',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (isMyJob)
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editJob(job),
                                      tooltip: 'Edit Job',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                job['description'] ?? 'No description',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(job['category'] ?? 'Other'),
                                    backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                                  ),
                                  const Spacer(),
                                  if (job['pay'] != null && job['pay'] > 0)
                                    Text(
                                      '\$${job['pay']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (status != null)
                                    Chip(
                                      label: Text('Status: ${status.toUpperCase()}'),
                                      backgroundColor: status == 'completed' 
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.orange.withValues(alpha: 0.1),
                                    ),
                                  const Spacer(),
                                  if (!isMyJob && status == null)
                                    ElevatedButton(
                                      onPressed: () => _applyForJob(jobId),
                                      child: const Text('Apply'),
                                    ),
                                  if (status != null || isMyJob)
                                    TextButton.icon(
                                      onPressed: () => _chatWithPoster(job),
                                      icon: const Icon(Icons.chat),
                                      label: const Text('Chat'),
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
    );
  }
}
