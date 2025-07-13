// Requires video_player: ^2.10.0 in pubspec.yaml
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/job_seeker_profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/companies_screen.dart';
import 'main.dart'; // for kGoldenBrown
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class SwipeScreen extends StatefulWidget {
  final String userId;
  const SwipeScreen({super.key, this.userId = 'test@example.com'});
  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  Future<void> _fetchCandidates() async {
    setState(() { _loading = true; });
    // Find job seekers who liked any job posted by this employer
    final jobsSnap = await FirebaseFirestore.instance.collection('jobs').where('employerId', isEqualTo: widget.userId).get();
    final jobIds = jobsSnap.docs.map((doc) => doc.id).toList();
    final candidates = <DocumentSnapshot>[];
    for (final jobId in jobIds) {
      final likesSnap = await FirebaseFirestore.instance.collection('job_likes').where('jobId', isEqualTo: jobId).get();
      for (final like in likesSnap.docs) {
        final userId = like['userId'];
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) candidates.add(userDoc);
      }
    }
    setState(() {
      _candidates = candidates;
      _loading = false;
      _currentIndex = 0;
    });
  }
  
  int _selectedIndex = 0;
  int _currentIndex = 0;
  List<DocumentSnapshot> _jobs = [];
  List<DocumentSnapshot> _filteredJobs = [];
  List<DocumentSnapshot> _candidates = [];
  bool _loading = true;
  String? _userName;
  String? _userPhotoUrl;
  bool _isEmployer = false;
  
  // Search and filter variables
  String _searchQuery = '';
  String _selectedJobType = 'All';
  String _selectedSalaryRange = 'All';
  bool _showListView = false;
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _jobTypes = ['All', 'Full-time', 'Part-time', 'Freelance', 'Contract', 'Internship'];
  final List<String> _salaryRanges = ['All', 'Under \$30k', '\$30k - \$50k', '\$50k - \$80k', '\$80k - \$120k', 'Over \$120k'];

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    setState(() { _loading = true; });
    final snapshot = await FirebaseFirestore.instance.collection('jobs').orderBy('createdAt', descending: true).get();
    setState(() {
      _jobs = snapshot.docs;
      _filteredJobs = snapshot.docs;
      _loading = false;
      _currentIndex = 0;
    });
  }

  void _filterJobs() {
    setState(() {
      _filteredJobs = _jobs.where((job) {
        final data = job.data() as Map<String, dynamic>? ?? {};
        final title = (data['title'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();
        final company = (data['companyName'] ?? '').toString().toLowerCase();
        final jobType = (data['jobType'] ?? '').toString();
        final salary = (data['salary'] ?? '').toString();
        
        // Search filter
        final matchesSearch = _searchQuery.isEmpty || 
          title.contains(_searchQuery.toLowerCase()) ||
          description.contains(_searchQuery.toLowerCase()) ||
          company.contains(_searchQuery.toLowerCase());
        
        // Job type filter
        final matchesJobType = _selectedJobType == 'All' || jobType == _selectedJobType;
        
        // Salary range filter
        bool matchesSalary = _selectedSalaryRange == 'All';
        if (!matchesSalary && salary.isNotEmpty) {
          final salaryNum = double.tryParse(salary.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
          switch (_selectedSalaryRange) {
            case 'Under \$30k':
              matchesSalary = salaryNum < 30000;
              break;
            case '\$30k - \$50k':
              matchesSalary = salaryNum >= 30000 && salaryNum < 50000;
              break;
            case '\$50k - \$80k':
              matchesSalary = salaryNum >= 50000 && salaryNum < 80000;
              break;
            case '\$80k - \$120k':
              matchesSalary = salaryNum >= 80000 && salaryNum < 120000;
              break;
            case 'Over \$120k':
              matchesSalary = salaryNum >= 120000;
              break;
          }
        }
        
        return matchesSearch && matchesJobType && matchesSalary;
      }).toList();
    });
  }

  Future<void> _fetchUserInfo() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _userName = data['companyName'] ?? data['name'] ?? '';
        _userPhotoUrl = data['profileImageUrl'] ?? data['companyLogoUrl'];
        _isEmployer = data['userType'] == 'employer';
      });
      if (_isEmployer) {
        _fetchCandidates();
      } else {
        _fetchJobs();
      }
    }
  }

  // --- SWIPE LOGIC ---
  void _swipeLeft() {
    setState(() {
      if (_isEmployer) {
        if (_currentIndex < _candidates.length - 1) _currentIndex++;
      } else {
        if (_currentIndex < _filteredJobs.length - 1) _currentIndex++;
      }
    });
  }

  // Handles right swipe for both job seekers and employers
  void _swipeRight() async {
    if (_isEmployer) {
      final candidate = _candidates[_currentIndex];
      final candidateId = candidate.id;
      // Record employer like
      await FirebaseFirestore.instance.collection('candidate_likes').add({
        'employerId': widget.userId,
        'candidateId': candidateId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Check if candidate liked any job from this employer
      final jobsSnap = await FirebaseFirestore.instance.collection('jobs').where('employerId', isEqualTo: widget.userId).get();
      for (final job in jobsSnap.docs) {
        final likeSnap = await FirebaseFirestore.instance.collection('job_likes')
          .where('jobId', isEqualTo: job.id)
          .where('userId', isEqualTo: candidateId)
          .get();
        if (likeSnap.docs.isNotEmpty) {
          // Mutual like, create match
          await FirebaseFirestore.instance.collection('matches').add({
            'employerId': widget.userId,
            'candidateId': candidateId,
            'jobId': job.id,
            'timestamp': FieldValue.serverTimestamp(),
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Match! You can now chat with ${candidate['name'] ?? candidate['email']}')),
            );
            // Optionally, open chat immediately:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(userId: widget.userId, isEmployer: true),
              ),
            );
          }
          break;
        }
      }
      setState(() {
        if (_currentIndex < _candidates.length - 1) _currentIndex++;
      });
    } else {
      final job = _filteredJobs[_currentIndex];
      // Record job seeker like
      await FirebaseFirestore.instance.collection('job_likes').add({
        'userId': widget.userId,
        'jobId': job.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Check if employer liked this candidate
      final employerId = job['employerId'];
      final likeSnap = await FirebaseFirestore.instance.collection('candidate_likes')
        .where('employerId', isEqualTo: employerId)
        .where('candidateId', isEqualTo: widget.userId)
        .get();
      if (likeSnap.docs.isNotEmpty) {
        // Mutual like, create match
        await FirebaseFirestore.instance.collection('matches').add({
          'employerId': employerId,
          'candidateId': widget.userId,
          'jobId': job.id,
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Match! You can now chat with the employer.')),
          );
          // Optionally, open chat immediately:
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(userId: widget.userId),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Applied for ${job['title']}')),
          );
        }
      }
      setState(() {
        if (_currentIndex < _filteredJobs.length - 1) _currentIndex++;
      });
    }
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search jobs, companies, or keywords...',
              prefixIcon: const Icon(Icons.search, color: kGoldenBrown),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _filterJobs();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kGoldenBrown),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kGoldenBrown, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterJobs();
            },
          ),
          const SizedBox(height: 12),
          
          // Filter chips
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedJobType,
                  decoration: InputDecoration(
                    labelText: 'Job Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _jobTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedJobType = value!;
                    });
                    _filterJobs();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSalaryRange,
                  decoration: InputDecoration(
                    labelText: 'Salary',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _salaryRanges.map((range) => DropdownMenuItem(value: range, child: Text(range))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSalaryRange = value!;
                    });
                    _filterJobs();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // View toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredJobs.length} jobs found',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.view_list,
                      color: _showListView ? kGoldenBrown : Colors.grey,
                    ),
                    onPressed: () => setState(() => _showListView = true),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.swipe,
                      color: !_showListView ? kGoldenBrown : Colors.grey,
                    ),
                    onPressed: () => setState(() => _showListView = false),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(DocumentSnapshot job) {
    final data = job.data() as Map<String, dynamic>? ?? {};
    final title = data['title'] ?? 'No Title';
    final company = data['companyName'] ?? 'Unknown Company';
    final salary = data['salary'] ?? 'Salary not specified';
    final jobType = data['jobType'] ?? 'Full-time';
    final description = data['description'] ?? 'No description available';
    final location = data['location'] ?? 'Location not specified';
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: kGoldenBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work, color: kGoldenBrown, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        company,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        location,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Pass', style: TextStyle(color: Colors.red)),
                    onPressed: _swipeLeft,
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
                    label: const Text('Apply', style: TextStyle(color: Colors.white)),
                    onPressed: _swipeRight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGoldenBrown,
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
  }

  Widget _buildSwipeJobs() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kGoldenBrown));
    }
    
    if (_isEmployer) {
      if (_candidates.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No candidates have liked your jobs yet.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
                onPressed: _fetchCandidates,
              ),
            ],
          ),
        );
      }
      final candidate = _candidates[_currentIndex];
      final name = candidate.data().toString().contains('name') ? candidate['name'] : candidate.id;
      final photo = candidate.data().toString().contains('profileImageUrl') ? candidate['profileImageUrl'] : null;
      return Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null ? const Icon(Icons.person, size: 48) : null,
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 36),
                      onPressed: _swipeLeft,
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite, color: kGoldenBrown, size: 36),
                      onPressed: _swipeRight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      if (_filteredJobs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No jobs found matching your criteria.'),
              const SizedBox(height: 8),
              const Text('Try adjusting your search or filters.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
                onPressed: _fetchJobs,
              ),
            ],
          ),
        );
      }
      
      if (_showListView) {
        // List view with search and filter
        return Column(
          children: [
            _buildSearchAndFilterSection(),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredJobs.length,
                itemBuilder: (context, index) => _buildJobCard(_filteredJobs[index]),
              ),
            ),
          ],
        );
      } else {
        // Swipe view
        final job = _filteredJobs[_currentIndex];
        final data = job.data() as Map<String, dynamic>? ?? {};
        final title = data['title'] ?? 'No Title';
        final company = data['companyName'] ?? 'Unknown Company';
        final salary = data['salary'] ?? 'Salary not specified';
        final jobType = data['jobType'] ?? 'Full-time';
        final description = data['description'] ?? 'No description available';
        final location = data['location'] ?? 'Location not specified';
        
        return Column(
          children: [
            _buildSearchAndFilterSection(),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Card(
                    elevation: 8,
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: kGoldenBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.work, color: kGoldenBrown, size: 40),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title, 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            company, 
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            location, 
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                          const SizedBox(height: 16),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 100),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              description,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 32),
                                onPressed: _swipeLeft,
                              ),
                              IconButton(
                                icon: const Icon(Icons.favorite, color: kGoldenBrown, size: 32),
                                onPressed: _swipeRight,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('TinderJob'),
          backgroundColor: kGoldenBrown,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: kGoldenBrown),
        ),
      );
    }
    final isEmployer = _isEmployer; // or however you determine user type
    final screens = isEmployer
      ? [
          _buildSwipeJobs(),
          ChatScreen(userId: widget.userId),
          JobSeekerProfileScreen(userId: widget.userId),
        ]
      : [
          _buildSwipeJobs(),
          CompaniesScreen(userId: widget.userId),
          ChatScreen(userId: widget.userId),
          JobSeekerProfileScreen(userId: widget.userId),
        ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('TinderJob'),
        backgroundColor: kGoldenBrown,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_isEmployer) {
                _fetchCandidates();
              } else {
                _fetchJobs();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications or navigate to notifications screen
            },
          ),
        ],
      ),
      body: screens[_selectedIndex],
      resizeToAvoidBottomInset: false,
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
        items: isEmployer
          ? const [
              BottomNavigationBarItem(
                icon: Icon(Icons.work),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ]
          : const [
              BottomNavigationBarItem(
                icon: Icon(Icons.work),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business),
                label: 'Companies',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
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