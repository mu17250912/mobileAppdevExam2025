import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/employer_profile_screen.dart';
import 'screens/chat_screen.dart';
import 'main.dart'; // for kGoldenBrown
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';


class EmployerDashboard extends StatefulWidget {
  final String userId;
  const EmployerDashboard({super.key, this.userId = 'test@example.com'});
  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  int _selectedIndex = 0;
  String? _companyName;
  String? _companyLogoUrl;
  int _dashboardTab = 0; // 0 = Jobs Posted, 1 = Interested Candidates
  List<DocumentSnapshot> _candidates = [];
  List<DocumentSnapshot> _jobs = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEmployerInfo();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployerInfo() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (!mounted) return;
      setState(() {
        _companyName = data['companyName'] ?? '';
        _companyLogoUrl = data['companyLogoUrl'];
      });
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    try {
      // Fetch jobs posted by this employer
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('employerId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();
      if (!mounted) return;
      setState(() {
        _jobs = jobsSnapshot.docs;
      });

      // Fetch candidates who liked any job from this employer
      final candidates = <DocumentSnapshot>[];
      for (final job in jobsSnapshot.docs) {
        final likesSnapshot = await FirebaseFirestore.instance
            .collection('job_likes')
            .where('jobId', isEqualTo: job.id)
            .get();
        
        for (final like in likesSnapshot.docs) {
          final userId = like['userId'];
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          
          if (userDoc.exists && !candidates.any((c) => c.id == userDoc.id)) {
            candidates.add(userDoc);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _candidates = candidates;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  List<DocumentSnapshot> _getFilteredCandidates() {
    if (_searchQuery.isEmpty) return _candidates;
    
    return _candidates.where((candidate) {
      final data = candidate.data() as Map<String, dynamic>? ?? {};
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final skills = (data['skills'] as List?)?.join(' ').toLowerCase() ?? '';
      
      return name.contains(_searchQuery.toLowerCase()) ||
             email.contains(_searchQuery.toLowerCase()) ||
             skills.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern toggle switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSwitcherButton('Jobs Posted (${_jobs.length})', true, () => setState(() => _dashboardTab = 0)),
              const SizedBox(width: 12),
              _buildSwitcherButton('Candidates (${_candidates.length})', false, () => setState(() => _dashboardTab = 1)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search bar for candidates
          if (_dashboardTab == 1) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search candidates by name, email, or skills...',
                prefixIcon: const Icon(Icons.search, color: kGoldenBrown),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kGoldenBrown, width: 2),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
          ],
          
          Expanded(
            child: _dashboardTab == 0 ? _buildJobList() : _buildCandidateList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcherButton(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kGoldenBrown : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGoldenBrown, width: 2),
          boxShadow: selected
              ? [BoxShadow(color: kGoldenBrown.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : kGoldenBrown,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildJobList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kGoldenBrown));
    }
    
    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No jobs posted yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Start by posting your first job to attract candidates'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Post Job'),
              style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
              onPressed: () => _showPostJobDialog(context),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Jobs Posted (${_jobs.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Post New Job'),
              style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
              onPressed: () => _showPostJobDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _jobs.length,
                itemBuilder: (context, index) {
              final job = _jobs[index];
              final data = job.data() as Map<String, dynamic>? ?? {};
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: kGoldenBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.work, color: kGoldenBrown, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? 'No Title',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Salary: ${data['salary'] ?? 'Not specified'}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  'Posted: ${_formatDate(data['createdAt'])}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                              _showEditJobDialog(context, job);
                              } else if (value == 'delete') {
                                _showDeleteJobDialog(context, job);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildCandidateList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kGoldenBrown));
    }
    
    final filteredCandidates = _getFilteredCandidates();
    
    if (_candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No candidates yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Candidates will appear here when they like your jobs'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
              onPressed: _fetchData,
            ),
          ],
        ),
      );
    }

    if (filteredCandidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No candidates found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Try adjusting your search criteria'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Candidates (${filteredCandidates.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: filteredCandidates.length,
            itemBuilder: (context, index) {
              final candidate = filteredCandidates[index];
              final data = candidate.data() as Map<String, dynamic>? ?? {};
              final name = data['name'] ?? 'Unknown';
              final email = data['email'] ?? '';
              final photoUrl = data['profileImageUrl'];
              final skills = (data['skills'] as List?)?.join(', ') ?? 'No skills listed';
              final jobType = data['jobType'] ?? 'Not specified';
              final salary = data['salary'] ?? 'Not specified';
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null ? const Icon(Icons.person, size: 30) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  email,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: kGoldenBrown.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        jobType,
                                        style: TextStyle(color: kGoldenBrown, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        salary,
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Skills: $skills',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Pass', style: TextStyle(color: Colors.red)),
                              onPressed: () => _passCandidate(candidate.id),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.favorite, color: Colors.white),
                              label: const Text('Like', style: TextStyle(color: Colors.white)),
                              onPressed: () => _likeCandidate(candidate.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kGoldenBrown,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.chat, color: kGoldenBrown),
                              label: const Text('Chat', style: TextStyle(color: kGoldenBrown)),
                              onPressed: () => _openChat(candidate.id, name),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: kGoldenBrown),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          ),
        ),
      ],
    );
  }

  void _passCandidate(String candidateId) {
    setState(() {
      _candidates.removeWhere((c) => c.id == candidateId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Candidate passed')),
    );
  }

  void _likeCandidate(String candidateId) async {
    try {
      // Record employer like
      await FirebaseFirestore.instance.collection('candidate_likes').add({
        'employerId': widget.userId,
        'candidateId': candidateId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Check for mutual like and create match
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('employerId', isEqualTo: widget.userId)
          .get();
      
      for (final job in jobsSnapshot.docs) {
        final likeSnapshot = await FirebaseFirestore.instance
            .collection('job_likes')
            .where('jobId', isEqualTo: job.id)
            .where('userId', isEqualTo: candidateId)
            .get();
        
        if (likeSnapshot.docs.isNotEmpty) {
          // Mutual like - create match
          await FirebaseFirestore.instance.collection('matches').add({
            'employerId': widget.userId,
            'candidateId': candidateId,
            'jobId': job.id,
            'timestamp': FieldValue.serverTimestamp(),
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Match! You can now chat with this candidate')),
            );
          }
          break;
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidate liked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _openChat(String candidateId, String candidateName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          currentUserId: widget.userId,
          otherUserId: candidateId,
          otherUserName: candidateName,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showPostJobDialog(BuildContext context) {
    final titleController = TextEditingController();
    final salaryController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    String selectedJobType = 'Full-time';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post New Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: salaryController,
                decoration: const InputDecoration(
                  labelText: 'Salary',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedJobType,
                decoration: const InputDecoration(
                  labelText: 'Job Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Full-time', 'Part-time', 'Freelance', 'Contract', 'Internship']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => selectedJobType = value!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job title is required')),
                );
                return;
              }
              
              try {
                await FirebaseFirestore.instance.collection('jobs').add({
                  'title': titleController.text.trim(),
                  'salary': salaryController.text.trim(),
                  'location': locationController.text.trim(),
                  'jobType': selectedJobType,
                  'description': descriptionController.text.trim(),
                  'employerId': widget.userId,
                  'companyName': _companyName,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                
                Navigator.of(context).pop();
                _fetchData(); // Refresh data
                
                if (mounted) {
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
            },
            child: const Text('Post Job'),
          ),
        ],
      ),
    );
  }

  void _showEditJobDialog(BuildContext context, DocumentSnapshot job) {
    final data = job.data() as Map<String, dynamic>? ?? {};
    final titleController = TextEditingController(text: data['title'] ?? '');
    final salaryController = TextEditingController(text: data['salary'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    final locationController = TextEditingController(text: data['location'] ?? '');
    String selectedJobType = data['jobType'] ?? 'Full-time';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Job'),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(),
                ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: salaryController,
                decoration: const InputDecoration(
                  labelText: 'Salary',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedJobType,
                decoration: const InputDecoration(
                  labelText: 'Job Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Full-time', 'Part-time', 'Freelance', 'Contract', 'Internship']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => selectedJobType = value!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
            onPressed: () async {
              try {
              await FirebaseFirestore.instance.collection('jobs').doc(job.id).update({
                'title': titleController.text.trim(),
                'salary': salaryController.text.trim(),
                  'location': locationController.text.trim(),
                  'jobType': selectedJobType,
                  'description': descriptionController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                Navigator.of(context).pop();
                _fetchData(); // Refresh data
                
                if (mounted) {
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
            },
            child: const Text('Update Job'),
          ),
        ],
      ),
    );
  }

  void _showDeleteJobDialog(BuildContext context, DocumentSnapshot job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to delete this job? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('jobs').doc(job.id).delete();
                Navigator.of(context).pop();
                _fetchData(); // Refresh data
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job deleted successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting job: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    try {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildDashboard(),
      EmployerProfileScreen(userId: widget.userId),
      ChatScreen(userId: widget.userId, isEmployer: true),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_companyName ?? 'Employer Dashboard'),
        backgroundColor: kGoldenBrown,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: kGoldenBrown),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: _companyLogoUrl != null ? NetworkImage(_companyLogoUrl!) : null,
                    child: _companyLogoUrl == null ? const Icon(Icons.business, size: 48, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _companyName ?? 'Company',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: kGoldenBrown),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.business, color: kGoldenBrown),
              title: const Text('Company Profile'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: kGoldenBrown),
              title: const Text('Chats'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 2);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(context).pop();
                await handleLogout(context);
              },
            ),
          ],
        ),
      ),
      body: screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 && _dashboardTab == 0
          ? FloatingActionButton(
              backgroundColor: kGoldenBrown,
              onPressed: () => _showPostJobDialog(context),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kGoldenBrown,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}

Future<void> handleLogout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => LoginScreen(onRegisterTap: () {})),
    (route) => false,
  );
} 