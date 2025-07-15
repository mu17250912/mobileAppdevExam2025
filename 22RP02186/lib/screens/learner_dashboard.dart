import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'profile_management_screen.dart';
import 'courses_screen.dart';
import 'skills_management_screen.dart';
import 'notifications_screen.dart';
import 'chat_screen.dart';
import 'premium_features_screen.dart';
import 'course_detail_screen.dart';
import 'jobs_screen.dart';
import '../utils/rating_utils.dart';

class LearnerDashboard extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onThemeToggle;
  final ThemeMode? themeMode;
  
  const LearnerDashboard({Key? key, required this.userEmail, this.onThemeToggle, this.themeMode}) : super(key: key);

  @override
  State<LearnerDashboard> createState() => _LearnerDashboardState();
}

class _LearnerDashboardState extends State<LearnerDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> userSkills = [];
  List<Map<String, dynamic>> availableTrainers = [];
  List<Map<String, dynamic>> myCreatedCourses = [];

  // Add state for selected category and featured courses
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _allFeaturedCourses = [];

  // 1. Add a Set<String> _unlockedCourseIds to state.
  Set<String> _unlockedCourseIds = {};

  List<String> get _categories {
    final cats = _allFeaturedCourses.map((c) => c['category'] as String? ?? 'General').toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<Map<String, dynamic>> get _filteredFeaturedCourses {
    if (_selectedCategory == 'All') return _allFeaturedCourses;
    return _allFeaturedCourses.where((c) =>
      (c['category'] ?? '').toString().trim().toLowerCase() == _selectedCategory.trim().toLowerCase()
    ).toList();
  }

  List<String> _trainerEmails = [];

  Future<void> _fetchTrainerEmails() async {
    final trainers = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'trainer')
        .get();
    setState(() {
      _trainerEmails = trainers.docs.map((doc) => doc['email'] as String).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchTrainerEmails().then((_) {
      _loadUserProfile();
      _loadUserSkills();
      _loadAvailableTrainers();
      _loadConnectedTrainers();
      _loadAllCourses();
      _loadMyCreatedCourses();
      _listenForNewMessages();
      _initFCM();
      _loadUnlockedCourses();
    });
  }

  void _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    String? token = await messaging.getToken();
    print('FCM Token: $token');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Push: ${message.notification!.title ?? ''} \n${message.notification!.body ?? ''}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
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

  Future<void> _loadUserSkills() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('user_skills')
          .where('userEmail', isEqualTo: widget.userEmail)
          .get();
      
      setState(() {
        userSkills = query.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error loading user skills: $e');
    }
  }

  Future<void> _loadAvailableTrainers() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'trainer')
          .limit(10)
          .get();
      
      setState(() {
        availableTrainers = query.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error loading trainers: $e');
    }
  }

  Future<void> _loadConnectedTrainers() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('connections')
          .where('learnerEmail', isEqualTo: widget.userEmail)
          .where('status', isEqualTo: 'connected')
          .get();
      
      // Get trainer details for connected trainers
      List<Map<String, dynamic>> connectedTrainers = [];
      for (var doc in query.docs) {
        final connection = doc.data();
        final trainerQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: connection['trainerEmail'])
            .get();
        
        if (trainerQuery.docs.isNotEmpty) {
          connectedTrainers.add({
            ...trainerQuery.docs.first.data(),
            'connectionId': doc.id,
          });
        }
      }
      
      setState(() {
        // Update the trainers list to include connection status
        availableTrainers = availableTrainers.map((trainer) {
          final isConnected = connectedTrainers.any((connected) => connected['email'] == trainer['email']);
          return {
            ...trainer,
            'isConnected': isConnected,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading connected trainers: $e');
    }
  }

  Future<void> _loadAllCourses() async {
    try {
      await _fetchTrainerEmails();
      final query = await FirebaseFirestore.instance
          .collection('courses')
          .get();
      setState(() {
        _allFeaturedCourses = query.docs
            .where((doc) => _trainerEmails.contains(doc['trainerEmail']))
            .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
            .toList();
      });
    } catch (e) {
      print('Error loading courses: $e');
    }
  }

  Future<void> _loadMyCreatedCourses() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('courses')
          .where('trainerEmail', isEqualTo: widget.userEmail)
          .get();
      setState(() {
        myCreatedCourses = query.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      });
    } catch (e) {
      print('Error loading my created courses: $e');
    }
  }

  // 2. Add a method to load unlocked courses for the learner.
  Future<void> _loadUnlockedCourses() async {
    final snap = await FirebaseFirestore.instance
        .collection('unlocked_courses')
        .where('userEmail', isEqualTo: widget.userEmail)
        .get();
    setState(() {
      _unlockedCourseIds = snap.docs.map((doc) => doc['courseId'] as String).toSet();
    });
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
    return 'assets/default_course.png'; // fallback, if you have one
  }

  // 3. Call _loadUnlockedCourses in initState.
  // 4. In _buildAllCoursesSection and _buildFeaturedCoursesSection, update the card UI:
  //    - If premium and not unlocked, show a lock icon overlay.
  //    - Make the whole card clickable. On tap, if premium and not unlocked, show unlock dialog; else open details.
  //    - Add a helper: bool _isCourseUnlocked(Map<String, dynamic> course) => !course['isPremium'] || _unlockedCourseIds.contains(course['id']);
  bool _isCourseUnlocked(Map<String, dynamic> course) {
    return course['isPremium'] != true || _unlockedCourseIds.contains(course['id']);
  }

  // 5. Add a method to show unlock/payment dialog and unlock the course in Firestore.
  Future<void> _showUnlockPremiumCourseDialog(BuildContext context, Map<String, dynamic> course) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlock Premium Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text('This is a premium course. Simulate payment to unlock.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Simulate Payment'),
          ),
        ],
      ),
    );
    if (result == true) {
      // Simulate payment and unlock
      await FirebaseFirestore.instance.collection('unlocked_courses').add({
        'userEmail': widget.userEmail,
        'courseId': course['id'],
        'unlockedAt': FieldValue.serverTimestamp(),
      });
      await _loadUnlockedCourses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course unlocked!')),
      );
      // Optionally, open course details after unlock
      _showCourseDetails(context, course);
    }
  }

  void _showCourseDetails(BuildContext context, Map<String, dynamic> course) {
    if (course['isPremium'] == true && !_isCourseUnlocked(course)) {
      _showUnlockPremiumCourseDialog(context, course);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(
            userEmail: widget.userEmail,
            userRole: 'learner',
            course: course,
          ),
        ),
      );
    }
  }

  void _markAsCompleted(Map<String, dynamic> course) async {
    try {
      // Check if already completed
      final existingCompletion = await FirebaseFirestore.instance
          .collection('completed_courses')
          .where('userEmail', isEqualTo: widget.userEmail)
          .where('courseId', isEqualTo: course['id'])
          .get();

      if (existingCompletion.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course already completed!')),
        );
        return;
      }

      // Mark as completed
      await FirebaseFirestore.instance.collection('completed_courses').add({
        'userEmail': widget.userEmail,
        'courseId': course['id'],
        'courseTitle': course['title'],
        'trainerEmail': course['trainerEmail'],
        'completedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course marked as completed!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking course as completed: $e')),
      );
    }
  }

  void _launchVideo(String url) async {
    // Use url_launcher or similar to open the video URL
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Skills', userSkills.length.toString(), Icons.school, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Trainers', availableTrainers.length.toString(), Icons.people, Colors.green),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
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
            _buildActivityItem('Added Flutter to your skills', '2 hours ago'),
            _buildActivityItem('Connected with John Trainer', '1 day ago'),
            _buildActivityItem('Completed React Basics course', '3 days ago'),
          ],
        ),
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
              color: Colors.blue,
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
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Trainers',
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
                  .where('role', isEqualTo: 'trainer')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading trainers'));
                }
                final docs = snapshot.data?.docs ?? [];
                final trainers = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                // Merge connection status
                final mergedTrainers = trainers.map((trainer) {
                  final isConnected = availableTrainers.any((t) => t['email'] == trainer['email'] && t['isConnected'] == true);
                  return {
                    ...trainer,
                    'isConnected': isConnected,
                  };
                }).toList();
                if (mergedTrainers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sentiment_dissatisfied, size: 64, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(height: 16),
                        Text(
                          'No trainers available right now.',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later or try a different skill category!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: mergedTrainers.length,
                  itemBuilder: (context, index) {
                    final trainer = mergedTrainers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        leading: trainer['profileImage'] != null && trainer['profileImage'].toString().isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(trainer['profileImage']),
                                backgroundColor: Colors.green.withOpacity(0.1),
                                child: Semantics(
                                  label: trainer['name'] ?? trainer['email'] ?? 'Trainer avatar',
                                  child: SizedBox.shrink(),
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.green.withOpacity(0.1),
                                child: Semantics(
                                  label: trainer['name'] ?? trainer['email'] ?? 'Trainer avatar',
                                  child: Text(
                                    (trainer['name'] ?? trainer['email'] ?? 'T')[0].toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                        title: Text(
                          trainer['name'] ?? trainer['email']?.split('@')[0] ?? 'Unknown Trainer',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trainer['email'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RatingUtils.buildTrainerRatingWidget(
                              trainer['email'],
                              size: 12,
                            ),
                          ],
                        ),
                        trailing: trainer['isConnected'] == true
                            ? ElevatedButton.icon(
                                onPressed: () => _messageTrainer(trainer),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                icon: Icon(Icons.chat_bubble),
                                label: Text('Chat'),
                              )
                            : ElevatedButton(
                                onPressed: () => _connectWithTrainer(trainer),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
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
    return ProfileManagementScreen(userEmail: widget.userEmail, userRole: 'learner');
  }

  void _addNewSkill() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkillsManagementScreen(userEmail: widget.userEmail, userRole: 'learner'),
      ),
    );
  }

  void _editSkill(Map<String, dynamic> skill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkillsManagementScreen(userEmail: widget.userEmail, userRole: 'learner'),
      ),
    );
  }

  void _connectWithTrainer(Map<String, dynamic> trainer) async {
    try {
      // Check if connection already exists
      final existingConnection = await FirebaseFirestore.instance
          .collection('connections')
          .where('learnerEmail', isEqualTo: widget.userEmail)
          .where('trainerEmail', isEqualTo: trainer['email'])
          .get();

      if (existingConnection.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already connected with this trainer!')),
        );
        return;
      }

      // Create connection request
      await FirebaseFirestore.instance.collection('connection_requests').add({
        'learnerEmail': widget.userEmail,
        'trainerEmail': trainer['email'],
        'learnerName': userProfile?['name'] ?? widget.userEmail.split('@')[0],
        'trainerName': trainer['name'] ?? trainer['email'].split('@')[0],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection request sent successfully!')),
      );
      
      _loadConnectedTrainers(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending connection request: $e')),
      );
    }
  }

  void _messageTrainer(Map<String, dynamic> trainer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          userEmail: widget.userEmail,
          userRole: 'learner',
          otherUserEmail: trainer['email'],
          otherUserName: trainer['name'] ?? trainer['email'].split('@')[0],
        ),
      ),
    );
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileManagementScreen(
          userEmail: widget.userEmail,
          userRole: 'learner',
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _logCourseStarted(String userEmail, String courseId, String courseTitle) async {
    await FirebaseFirestore.instance.collection('started_courses').add({
      'userEmail': userEmail,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  // Listen for new messages in any chat involving this user
  void _listenForNewMessages() {
    final userEmail = widget.userEmail;
    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: userEmail)
        .snapshots()
        .listen((chatSnapshot) {
      for (var chatDoc in chatSnapshot.docs) {
        final chatId = chatDoc.id;
        FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots()
            .listen((msgSnapshot) {
          if (msgSnapshot.docs.isNotEmpty) {
            final msg = msgSnapshot.docs.first.data();
            final sender = msg['senderEmail'];
            final messageText = msg['message'];
            final deletedFor = msg['deletedFor'] as List?;
            final isOwn = sender == userEmail;
            final isDeleted = deletedFor != null && deletedFor.contains(userEmail);
            if (!isOwn && !isDeleted) {
              // Show SnackBar for new message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('New message from ${msg['senderName'] ?? 'Someone'}: $messageText'),
                  action: SnackBarAction(
                    label: 'Open',
                    onPressed: () {
                      // Open chat screen with sender
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            userEmail: userEmail,
                            userRole: 'learner',
                            otherUserEmail: sender,
                            otherUserName: msg['senderName'] ?? sender,
                          ),
                        ),
                      );
                    },
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        });
      }
    });
  }

  // --- BEGIN: RESTYLE AND FUNCTIONALITY UPDATE ---
  // Update _buildWelcomeCard for blue accent and modern look
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
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to learn something new today?',
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

  // Update _buildCategoryChips for blue accent and modern look
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
              });
            },
            backgroundColor: Colors.blue[900],
            selectedColor: Colors.blue,
            labelStyle: GoogleFonts.poppins(color: Colors.white),
          );
        },
      ),
    );
  }

  // Use StreamBuilder for real-time course updates in featured and all courses sections
  Widget _buildFeaturedCoursesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading courses'));
        }
        final docs = snapshot.data?.docs ?? [];
        final featured = docs
            .where((doc) => _trainerEmails.contains(doc['trainerEmail']))
            .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
            .toList();
        final filtered = _selectedCategory == 'All'
            ? featured.take(4).toList()
            : featured.where((c) => (c['category'] ?? '').toString().trim().toLowerCase() == _selectedCategory.trim().toLowerCase()).take(4).toList();
        if (filtered.isEmpty) {
          return Text('No featured courses in this category.', style: GoogleFonts.poppins(fontSize: 16));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Featured Courses',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final course = filtered[index];
                  final image = course['image'];
                  final isAsset = image != null && image.toString().startsWith('assets/');
                  final hasImage = image != null && image.toString().isNotEmpty;
                  final imageProvider = hasImage
                      ? (isAsset ? AssetImage(image) as ImageProvider : NetworkImage(image))
                      : AssetImage(getAssetImageForCourse(course));
                  final bool isPremium = course['isPremium'] == true || (course['type']?.toString().toLowerCase() == 'premium');
                  final bool isUnlocked = _isCourseUnlocked(course);
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showCourseDetails(context, course),
                    child: Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
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
                              course['title'] ?? 'Untitled Course',
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
                              course['category'] ?? 'General',
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
                                  backgroundColor: isPremium ? Colors.amber : Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _showCourseDetails(context, course),
                                child: Text(isPremium && !isUnlocked ? 'Unlock' : 'Start'),
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

  Widget _buildAllCoursesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading courses'));
        }
        final docs = snapshot.data?.docs ?? [];
        final allCourses = docs
            .where((doc) => _trainerEmails.contains(doc['trainerEmail']))
            .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
            .toList();
        if (allCourses.isEmpty) {
          return Text('No courses available.', style: GoogleFonts.poppins(fontSize: 16));
        }
        final limitedCourses = allCourses.take(4).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'All Courses',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '(${allCourses.length})',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CoursesScreen(userEmail: widget.userEmail, userRole: 'learner'),
                      ),
                    );
                  },
                  child: Text('See All', style: GoogleFonts.poppins(color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: limitedCourses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final course = limitedCourses[index];
                final image = course['image'];
                final isAsset = image != null && image.toString().startsWith('assets/');
                final hasImage = image != null && image.toString().isNotEmpty;
                final imageProvider = hasImage
                    ? (isAsset ? AssetImage(image) as ImageProvider : NetworkImage(image))
                    : AssetImage(getAssetImageForCourse(course));
                final bool isPremium = course['isPremium'] == true || (course['type']?.toString().toLowerCase() == 'premium');
                final bool isUnlocked = _isCourseUnlocked(course);
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showCourseDetails(context, course),
                  child: Stack(
                    children: [
                      Card(
                        elevation: 2,
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course['title'] ?? 'Untitled',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      course['category'] ?? 'General',
                                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                                    ),
                                    Row(
                                      children: [
                                        if (isPremium)
                                          _buildBadge('Premium', Colors.amber),
                                        const SizedBox(width: 4),
                                        RatingUtils.buildCourseRatingWidget(course['id'], size: 14),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isPremium && !isUnlocked)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(Icons.lock, color: Colors.amber, size: 28),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (isPremium && !isUnlocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
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
          _buildAllCoursesSection(),
          const SizedBox(height: 20),
          if (myCreatedCourses.isNotEmpty) ...[
            Text(
              'My Created Courses',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: myCreatedCourses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final course = myCreatedCourses[index];
                  final image = course['image'];
                  final isAsset = image != null && image.toString().startsWith('assets/');
                  final hasImage = image != null && image.toString().isNotEmpty;
                  final imageProvider = hasImage
                      ? (isAsset ? AssetImage(image) as ImageProvider : NetworkImage(image))
                      : AssetImage(getAssetImageForCourse(course));
                  // Badge logic
                  final bool isPremium = course['isPremium'] == true || (course['type']?.toString().toLowerCase() == 'premium');
                  final DateTime? createdAt = course['createdAt'] is Timestamp
                      ? (course['createdAt'] as Timestamp).toDate()
                      : (course['createdAt'] is DateTime ? course['createdAt'] : null);
                  final bool isNew = createdAt != null && DateTime.now().difference(createdAt).inDays < 7;
                  final int studentsEnrolled = course['studentsEnrolled'] ?? 0;
                  final bool isPopular = studentsEnrolled > 10;
                  List<Widget> badges = [];
                  if (isPremium) {
                    badges.add(_buildBadge('Premium', Colors.amber));
                  }
                  if (isNew) {
                    badges.add(_buildBadge('New', Colors.green));
                  }
                  if (isPopular) {
                    badges.add(_buildBadge('Popular', Colors.blue));
                  }
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showCourseDetails(context, course),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Image(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                    width: 48,
                                    height: 48,
                                  ),
                                  // Badges row
                                  if (badges.isNotEmpty)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Row(children: badges),
                                    ),
                                  // Course rating
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: RatingUtils.buildCourseRatingWidget(
                                        course['id'],
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    course['title'] ?? 'Untitled Course',
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.onBackground,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    course['category'] ?? 'General',
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await _logCourseStarted(widget.userEmail, course['id'], course['title'] ?? '');
                                        _showCourseDetails(context, course);
                                      },
                                      child: Semantics(
                                        label: 'Start course: ${course['title'] ?? ''}',
                                        button: true,
                                        child: const Text('Start'),
                                      ),
                                    ),
                                  ),
                                ],
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
            const SizedBox(height: 20),
          ],
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Learner Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
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
                    userRole: 'learner',
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
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              decoration: const BoxDecoration(color: Colors.blue),
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
              title: const Text('Trainers'),
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
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() { _selectedIndex = 4; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Jobs'),
              selected: _selectedIndex == 5,
              onTap: () {
                setState(() { _selectedIndex = 5; });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Premium Features'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PremiumFeaturesScreen(
                      userEmail: widget.userEmail,
                      userRole: 'learner',
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // Removed Skills tab
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Trainers'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildRecentActivity();
      case 2:
        return _buildTrainersTab();
      case 3:
        return NotificationsScreen(userEmail: widget.userEmail, userRole: 'learner');
      case 4:
        return _buildProfileTab();
      case 5:
        return JobsScreen(userEmail: widget.userEmail);
      default:
        return Center(child: Text('Dashboard content not implemented for index $_selectedIndex'));
    }
  }
} 