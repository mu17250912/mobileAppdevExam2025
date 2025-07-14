import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'courses_screen.dart';
import 'profile_management_screen.dart';
import 'notifications_screen.dart';
import 'chat_screen.dart';
import 'premium_features_screen.dart';
import 'course_creation_screen.dart';
import 'analytics_dashboard.dart';

class TrainerDashboard extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onThemeToggle;
  final ThemeMode? themeMode;
  
  const TrainerDashboard({Key? key, required this.userEmail, this.onThemeToggle, this.themeMode}) : super(key: key);

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> learners = [];
  List<Map<String, dynamic>> connectionRequests = [];
  String _selectedCategory = 'All';

  List<String> get _categories {
    final cats = courses.map((c) => c['category'] as String? ?? 'General').toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<Map<String, dynamic>> get _filteredFeaturedCourses {
    if (_selectedCategory == 'All') return courses.take(4).toList();
    return courses.where((c) => c['category'] == _selectedCategory).take(4).toList();
  }

  String getAssetImageForCourse(Map<String, dynamic> course) {
    final title = (course['title'] ?? '').toString().toLowerCase();
    final category = (course['category'] ?? '').toString().toLowerCase();
    if (title.contains('music') || category.contains('music')) {
      return 'assets/music.jpg';
    } else if (title.contains('bake') || title.contains('cook') || category.contains('cooking')) {
      return 'assets/cooking.png';
    } else if (title.contains('computer') || title.contains('digital') || category.contains('digital')) {
      return 'assets/digital-skills.png';
    } else if (title.contains('fitness') || title.contains('health') || category.contains('health')) {
      return 'assets/Health&Fitness.jpg';
    }
    return 'assets/default_course.png';
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCourses();
    _loadLearners();
    _loadConnectionRequests();
  }

  Future<void> _loadUserProfile() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .get();
      
      if (query.docs.isNotEmpty) {
        setState(() {
          userProfile = query.docs.first.data();
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadCourses() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('courses')
          .where('trainerEmail', isEqualTo: widget.userEmail)
          .get();
      
      setState(() {
        courses = query.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error loading courses: $e');
    }
  }

  Future<void> _loadLearners() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'learner')
          .limit(10)
          .get();
      
      setState(() {
        learners = query.docs.map((doc) => doc.data()).toList();
      });
      
      _loadConnectedLearners();
    } catch (e) {
      print('Error loading learners: $e');
    }
  }

  Future<void> _loadConnectedLearners() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('connections')
          .where('trainerEmail', isEqualTo: widget.userEmail)
          .where('status', isEqualTo: 'connected')
          .get();
      
      List<Map<String, dynamic>> connectedLearners = [];
      for (var doc in query.docs) {
        final connection = doc.data();
        final learnerQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: connection['learnerEmail'])
            .get();
        
        if (learnerQuery.docs.isNotEmpty) {
          connectedLearners.add({
            ...learnerQuery.docs.first.data(),
            'connectionId': doc.id,
          });
        }
      }
      
      setState(() {
        learners = learners.map((learner) {
          final isConnected = connectedLearners.any((connected) => connected['email'] == learner['email']);
          return {
            ...learner,
            'isConnected': isConnected,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading connected learners: $e');
    }
  }

  Future<void> _loadConnectionRequests() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('connection_requests')
          .where('trainerEmail', isEqualTo: widget.userEmail)
          .where('status', isEqualTo: 'pending')
          .get();
      
      setState(() {
        connectionRequests = query.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error loading connection requests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Trainer Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.themeMode != null)
            TextButton.icon(
              onPressed: widget.onThemeToggle,
              icon: Icon(
                widget.themeMode == ThemeMode.dark ? Icons.wb_sunny : Icons.nightlight_round,
                color: Colors.white,
              ),
              label: Text(
                widget.themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PremiumFeaturesScreen(
                    userEmail: widget.userEmail,
                    userRole: 'trainer',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userProfile?['name'] ?? widget.userEmail.split('@')[0]),
              accountEmail: Text(widget.userEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white),
              ),
              decoration: const BoxDecoration(color: Colors.green),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() { _selectedIndex = 0; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Courses'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() { _selectedIndex = 1; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Learners'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() { _selectedIndex = 2; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() { _selectedIndex = 3; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble),
              title: const Text('Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      userEmail: widget.userEmail,
                      userRole: 'trainer',
                      otherUserEmail: '',
                      otherUserName: '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() { _selectedIndex = 4; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnalyticsDashboard()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create Course'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseCreationScreen(
                      userEmail: widget.userEmail,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Premium Features'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PremiumFeaturesScreen(
                      userEmail: widget.userEmail,
                      userRole: 'trainer',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseCreationScreen(
                userEmail: widget.userEmail,
              ),
            ),
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Learners'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return CoursesScreen(userEmail: widget.userEmail, userRole: 'trainer');
      case 2:
        return _buildLearnersTab();
      case 3:
        return NotificationsScreen(userEmail: widget.userEmail, userRole: 'trainer');
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildCategoryChips(),
          const SizedBox(height: 20),
          _buildFeaturedCoursesSection(),
          const SizedBox(height: 20),
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
          const SizedBox(height: 20),
          _buildConnectionRequests(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${widget.userEmail.split('@')[0]}!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to inspire and teach today?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(cat),
            selected: _selectedCategory == cat,
            onSelected: (_) {
              setState(() {
                _selectedCategory = cat;
              });
            },
            backgroundColor: Colors.grey[900],
            selectedColor: Colors.green,
            labelStyle: GoogleFonts.poppins(color: Colors.white),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildFeaturedCoursesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('courses').where('trainerEmail', isEqualTo: widget.userEmail).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading courses'));
        }
        final docs = snapshot.data?.docs ?? [];
        courses = docs.map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }).toList();
        final featuredCourses = _filteredFeaturedCourses;
        if (courses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(
                  'No courses created yet.',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first course to get started!',
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          );
        }
        if (featuredCourses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No courses in this category.',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Featured Courses',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featuredCourses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final course = featuredCourses[index];
                  final image = course['image'];
                  final isAsset = image != null && image.toString().startsWith('assets/');
                  final hasImage = image != null && image.toString().isNotEmpty;
                  final imageProvider = hasImage
                      ? (isAsset ? AssetImage(image) as ImageProvider : NetworkImage(image))
                      : AssetImage(getAssetImageForCourse(course));
                  final title = course['title'] ?? 'Untitled Course';
                  final category = course['category'] ?? 'General';
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showCourseDetails(context, course),
                    child: Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _showCourseDetails(context, course),
                                child: const Text('Start'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCourseDetails(BuildContext context, Map<String, dynamic> course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.play_circle_filled,
                        color: Colors.green,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['title'] ?? 'Untitled Course',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Category: ${course['category'] ?? 'General'}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Description',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  course['description'] ?? 'No description available',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Text(
                  'Video Content',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (course['videoURL'] != null)
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _launchVideo(course['videoURL']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No video available',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _launchVideo(String url) async {
    // Use url_launcher or similar to open the video URL
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Courses', courses.length.toString(), Icons.book, Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Learners', learners.length.toString(), Icons.people, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Requests', connectionRequests.length.toString(), Icons.notifications, Colors.orange),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem('New course "Flutter Basics" created', '2 hours ago'),
            _buildActivityItem('Learner John connected with you', '1 day ago'),
            _buildActivityItem('Course "React Advanced" completed by 5 learners', '3 days ago'),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('connection_requests')
          .where('trainerEmail', isEqualTo: widget.userEmail)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        final connectionRequests = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        return Card(
          elevation: 4,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Requests',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...connectionRequests.take(3).map((request) => _buildRequestItem(request)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(Icons.person, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['learnerEmail']?.split('@')[0] ?? 'Unknown Learner',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Wants to connect with you',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _acceptRequest(request),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Accept'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _rejectRequest(request),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Learners',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'learner')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading learners'));
                }
                final docs = snapshot.data?.docs ?? [];
                final learnersList = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                // Merge connection status
                final mergedLearners = learnersList.map((learner) {
                  final isConnected = learners.any((l) => l['email'] == learner['email'] && l['isConnected'] == true);
                  return {
                    ...learner,
                    'isConnected': isConnected,
                  };
                }).toList();
                if (mergedLearners.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.blueGrey),
                        const SizedBox(height: 16),
                        Text(
                          'No learners available right now.',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later or invite learners to join!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: mergedLearners.length,
                  itemBuilder: (context, index) {
                    final learner = mergedLearners[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: learner['profileImage'] != null && learner['profileImage'].toString().isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(learner['profileImage']),
                                backgroundColor: Colors.blue.withOpacity(0.1),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                child: Text(
                                  (learner['name'] ?? learner['email'] ?? 'L')[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        title: Text(
                          learner['name'] ?? learner['email']?.split('@')[0] ?? 'Unknown Learner',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Skills:  [0m${learner['skills']?.join(', ') ?? 'No skills listed'}',
                          style: GoogleFonts.poppins(),
                        ),
                        trailing: learner['isConnected'] == true
                            ? ElevatedButton.icon(
                                onPressed: () => _messageLearner(learner),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                icon: Icon(Icons.chat_bubble),
                                label: Text('Chat'),
                              )
                            : ElevatedButton(
                                onPressed: () => _connectWithLearner(learner),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Connect'),
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
    );
  }

  Widget _buildProfileTab() {
    return ProfileManagementScreen(userEmail: widget.userEmail, userRole: 'trainer');
  }

  void _connectWithLearner(Map<String, dynamic> learner) async {
    try {
      final existingConnection = await FirebaseFirestore.instance
          .collection('connections')
          .where('trainerEmail', isEqualTo: widget.userEmail)
          .where('learnerEmail', isEqualTo: learner['email'])
          .get();

      if (existingConnection.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already connected with this learner!')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('connection_requests').add({
        'trainerEmail': widget.userEmail,
        'learnerEmail': learner['email'],
        'trainerName': userProfile?['name'] ?? widget.userEmail.split('@')[0],
        'learnerName': learner['name'] ?? learner['email'].split('@')[0],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection request sent successfully!')),
      );
      
      _loadConnectedLearners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending connection request: $e')),
      );
    }
  }

  void _messageLearner(Map<String, dynamic> learner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          userEmail: widget.userEmail,
          userRole: 'trainer',
          otherUserEmail: learner['email'],
          otherUserName: learner['name'] ?? learner['email'].split('@')[0],
        ),
      ),
    );
  }

  void _acceptRequest(Map<String, dynamic> request) async {
    try {
      await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(request['id'])
          .update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('connections').add({
        'trainerEmail': request['trainerEmail'],
        'learnerEmail': request['learnerEmail'],
        'trainerName': request['trainerName'],
        'learnerName': request['learnerName'],
        'status': 'connected',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection request accepted!')),
      );
      
      _loadConnectionRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting request: $e')),
      );
    }
  }

  void _rejectRequest(Map<String, dynamic> request) async {
    try {
      await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(request['id'])
          .update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection request rejected!')),
      );
      
      _loadConnectionRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    }
  }
} 