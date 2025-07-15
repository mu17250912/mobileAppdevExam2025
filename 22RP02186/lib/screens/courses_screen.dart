import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'course_detail_screen.dart';
import 'course_creation_screen.dart'; // Added import for CourseCreationScreen

class CoursesScreen extends StatefulWidget {
  final String userEmail;
  final String userRole;
  
  const CoursesScreen({Key? key, required this.userEmail, required this.userRole}) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Map<String, dynamic>> allCourses = [];
  List<Map<String, dynamic>> filteredCourses = [];
  List<Map<String, dynamic>> userCompletedCourses = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedCategory = 'All';
  // Add filter chips (All, Free, Premium) at the top of the course list
  String selectedFilter = 'All';
  Set<String> _unlockedCourseIds = {}; // Track unlocked courses
  List<String> _trainerEmails = [];

  @override
  void initState() {
    super.initState();
    if (widget.userRole == 'learner') {
      _fetchTrainerEmails().then((_) {
        _loadCourses();
        _loadUserCompletedCourses();
        _loadUnlockedCourses();
      });
    } else {
      _loadCourses();
      _loadUserCompletedCourses();
      _loadUnlockedCourses();
    }
  }

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCourses(); // Always reload courses when screen is shown
  }

  Future<void> _loadCourses() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('courses')
          .get();
      setState(() {
        if (widget.userRole == 'learner') {
          allCourses = query.docs
              .where((doc) => _trainerEmails.contains(doc['trainerEmail']))
              .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
              .toList();
        } else {
          allCourses = query.docs
              .where((doc) => doc['trainerEmail'] == widget.userEmail)
              .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
              .toList();
        }
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading courses: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      filteredCourses = allCourses.where((course) {
        final matchesSearch = course['title']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
                             course['description']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
                             course['category']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true;
        
        final matchesCategory = selectedCategory == 'All' || course['category'] == selectedCategory;
        final isPremium = course['isPremium'] == true || (course['type']?.toString().toLowerCase() == 'premium');
        final matchesFilter = selectedFilter == 'All' ||
          (selectedFilter == 'Free' && !isPremium) ||
          (selectedFilter == 'Premium' && isPremium);
        return matchesSearch && matchesCategory && matchesFilter;
      }).toList();
    });
  }

  List<String> get _availableCategories {
    final categories = allCourses.map((course) => course['category']?.toString() ?? 'Unknown').toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  Future<void> _loadUserCompletedCourses() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('completed_courses')
          .where('userEmail', isEqualTo: widget.userEmail)
          .get();
      
      setState(() {
        userCompletedCourses = query.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error loading completed courses: $e');
    }
  }

  bool _isCourseCompleted(String courseId) {
    return userCompletedCourses.any((course) => course['courseId'] == courseId);
  }

  Future<void> _loadUnlockedCourses() async {
    final snap = await FirebaseFirestore.instance
        .collection('unlocked_courses')
        .where('userEmail', isEqualTo: widget.userEmail)
        .get();
    setState(() {
      _unlockedCourseIds = snap.docs.map((doc) => doc['courseId'] as String).toSet();
    });
  }

  bool _isCourseUnlocked(Map<String, dynamic> course) {
    return course['isPremium'] != true || _unlockedCourseIds.contains(course['id']);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Courses',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.userRole == 'trainer')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showUploadCourseDialog(context),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading courses'));
          }
          final docs = snapshot.data?.docs ?? [];
          final allCourses = widget.userRole == 'learner'
              ? docs
                  .where((doc) => _trainerEmails.contains(doc['trainerEmail']))
                  .map((doc) => {
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  })
                  .toList()
              : docs
                  .where((doc) => doc['trainerEmail'] == widget.userEmail)
                  .map((doc) => {
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  })
                  .toList();
          final filteredCourses = allCourses.where((course) {
            final matchesSearch = course['title']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
                                 course['description']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
                                 course['category']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true;
            final matchesCategory = selectedCategory == 'All' || course['category'] == selectedCategory;
            final isPremium = course['isPremium'] == true || (course['type']?.toString().toLowerCase() == 'premium');
            final matchesFilter = selectedFilter == 'All' ||
              (selectedFilter == 'Free' && !isPremium) ||
              (selectedFilter == 'Premium' && isPremium);
            return matchesSearch && matchesCategory && matchesFilter;
          }).toList();
          return Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(
                child: filteredCourses.isEmpty
                    ? _buildEmptyState()
                    : _buildCoursesList(filteredCourses),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search courses...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips (All, Free, Premium)
          Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Free'),
              const SizedBox(width: 8),
              _buildFilterChip('Premium'),
            ],
          ),
          const SizedBox(height: 12),
          // Category Filter
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableCategories.length,
              itemBuilder: (context, index) {
                final category = _availableCategories[index];
                final isSelected = category == selectedCategory;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                      });
                      _applyFilters();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: (widget.userRole == 'trainer' ? Colors.green : Colors.blue).withOpacity(0.2),
                    checkmarkColor: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = label;
        });
        _applyFilters();
      },
      selectedColor: (widget.userRole == 'trainer' ? Colors.green : Colors.blue),
      backgroundColor: Colors.grey[900],
      labelStyle: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.white70),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty || selectedCategory != 'All'
                ? 'No courses match your search'
                : 'No courses available',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userRole == 'trainer' 
                ? 'Create your first course to get started!'
                : 'Check back later for new courses!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(List<Map<String, dynamic>> filteredCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            '${filteredCourses.length} Courses Available',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.blueGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredCourses.length,
            itemBuilder: (context, index) {
              final course = filteredCourses[index];
              final isCompleted = _isCourseCompleted(course['id']);
              final isPremium = course['isPremium'] == true || (course['type']?.toString().toLowerCase() == 'premium');
              final isAccessible = _isCourseUnlocked(course); // Use unlocked logic
              final String? imageUrl = course['image'];
              final image = course['image'];
              final isAsset = image != null && image.toString().startsWith('assets/');
              final hasImage = image != null && image.toString().isNotEmpty;
              final imageProvider = hasImage
                  ? (isAsset ? AssetImage(image) as ImageProvider : NetworkImage(image))
                  : AssetImage(getAssetImageForCourse(course));
              // Badge logic
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
                onTap: () => isAccessible
                    ? _showCourseDetails(context, course)
                    : _showUnlockPremiumCourseDialog(context, course),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).cardColor,
                  child: Stack(
                    children: [
                      Padding(
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
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ),
                                  if (badges.isNotEmpty)
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Row(children: badges),
                                    ),
                                  if (isPremium)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () async {
                                          await _showUnlockPremiumCourseDialog(context, course);
                                        },
                                        child: Icon(Icons.lock, color: Colors.amber, size: 20),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Avatar
                            CircleAvatar(
                              backgroundColor: Colors.blueGrey[100],
                              child: Text(
                                (course['trainerName'] ?? course['trainerEmail'] ?? 'U')[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Course info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['title'] ?? 'Untitled Course',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey[800],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          course['category'] ?? 'General',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (course['level'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey[900],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            course['level'],
                                            style: GoogleFonts.poppins(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    course['description'] ?? 'No description available',
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Start or lock button
                            isAccessible
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    _showCourseDetails(context, course);
                                  },
                                  child: const Text('Start'),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.lock, color: Colors.amber),
                                  onPressed: () async {
                                    await _showUnlockPremiumCourseDialog(context, course);
                                  },
                                ),
                            // Trainer edit/delete buttons
                            if (widget.userRole == 'trainer')
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Edit Course',
                                    onPressed: () {
                                      _editCourse(course);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete Course',
                                    onPressed: () {
                                      _deleteCourse(course);
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
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
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
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
                              color: (widget.userRole == 'trainer' ? Colors.green : Colors.blue).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.play_circle_filled,
                              color: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
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
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            '${course['enrolledStudents'] ?? 0} students enrolled',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Trainer: ${course['trainerName'] ?? course['trainerEmail']?.split('@')[0] ?? 'Unknown'}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (widget.userRole == 'learner' && !_isCourseCompleted(course['id']))
                        FutureBuilder<bool>(
                          future: _hasStartedCourse(course['id']),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || !snapshot.data!) {
                              return SizedBox.shrink();
                            }
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _markAsCompleted(course);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Mark as Completed',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUploadCourseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    final videoURLController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Upload New Course',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Course Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: videoURLController,
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  border: OutlineInputBorder(),
                ),
              ),
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
              _uploadCourse(
                titleController.text,
                categoryController.text,
                descriptionController.text,
                videoURLController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadCourse(String title, String category, String description, String videoURL) async {
    if (title.isEmpty || category.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('courses').add({
        'title': title,
        'category': category,
        'description': description,
        'videoURL': videoURL.isNotEmpty ? videoURL : null,
        'trainerEmail': widget.userEmail,
        'trainerName': widget.userEmail.split('@')[0],
        'enrolledStudents': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course uploaded successfully!')),
      );
      
      _loadCourses(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading course: $e')),
      );
    }
  }

  Future<void> _markAsCompleted(Map<String, dynamic> course) async {
    try {
      await FirebaseFirestore.instance.collection('completed_courses').add({
        'courseId': course['id'],
        'courseTitle': course['title'],
        'userEmail': widget.userEmail,
        'completedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course marked as completed!')),
      );
      
      _loadUserCompletedCourses(); // Refresh completed courses
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking course as completed: $e')),
      );
    }
  }

  Future<void> _launchVideo(String url) async {
    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open video URL')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid video URL format')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No video URL available')),
        );
      }
    }
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _editCourse(Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseCreationScreen(
          userEmail: widget.userEmail,
          courseToEdit: course,
        ),
      ),
    ).then((_) => _loadCourses());
  }

  void _deleteCourse(Map<String, dynamic> course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Course'),
        content: Text('Are you sure you want to delete this course? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // Delete related completions
      final completions = await FirebaseFirestore.instance
          .collection('completed_courses')
          .where('courseId', isEqualTo: course['id'])
          .get();
      for (final doc in completions.docs) {
        await doc.reference.delete();
      }
      // Delete related unlocks
      final unlocks = await FirebaseFirestore.instance
          .collection('unlocked_courses')
          .where('courseId', isEqualTo: course['id'])
          .get();
      for (final doc in unlocks.docs) {
        await doc.reference.delete();
      }
      // Delete related started_courses
      final started = await FirebaseFirestore.instance
          .collection('started_courses')
          .where('courseId', isEqualTo: course['id'])
          .get();
      for (final doc in started.docs) {
        await doc.reference.delete();
      }
      // TODO: If you have an enrollments collection, repeat similar logic here
      await FirebaseFirestore.instance.collection('courses').doc(course['id']).delete();
      setState(() {
        filteredCourses.removeWhere((c) => c['id'] == course['id']);
        allCourses.removeWhere((c) => c['id'] == course['id']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course deleted successfully.')),
      );
      _loadCourses();
    }
  }

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
      await _loadUnlockedCourses(); // Refresh unlocked courses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course unlocked!')),
      );
      // Optionally, open course details after unlock
      _showCourseDetails(context, course);
    }
  }

  Future<void> _logCourseStarted(String userEmail, String courseId, String courseTitle) async {
    try {
      await FirebaseFirestore.instance.collection('started_courses').add({
        'userEmail': userEmail,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'startedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging course start: $e');
    }
  }

  Future<bool> _hasStartedCourse(String courseId) async {
    final snap = await FirebaseFirestore.instance
        .collection('started_courses')
        .where('userEmail', isEqualTo: widget.userEmail)
        .where('courseId', isEqualTo: courseId)
        .get();
    return snap.docs.isNotEmpty;
  }
} 