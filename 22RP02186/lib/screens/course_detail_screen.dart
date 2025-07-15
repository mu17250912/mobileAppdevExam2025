import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseDetailScreen extends StatefulWidget {
  final String userEmail;
  final String userRole;
  final Map<String, dynamic> course;
  
  const CourseDetailScreen({
    Key? key, 
    required this.userEmail, 
    required this.userRole,
    required this.course,
  }) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  List<Map<String, dynamic>> lessons = [];
  bool isLoading = true;
  bool isPremiumUser = false; // This should be checked from user profile
  bool _isCourseCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _checkPremiumStatus();
    _checkCourseCompleted();
  }

  void _loadLessons() {
    setState(() {
      lessons = List<Map<String, dynamic>>.from(widget.course['lessons'] ?? []);
      isLoading = false;
    });
  }

  void _checkPremiumStatus() {
    // Check if user has premium subscription
    // This should be implemented based on your premium system
    setState(() {
      isPremiumUser = false; // For now, assume not premium
    });
  }

  bool hasUnlockedPremiumLesson(String lessonTitle) {
    // For demo: use a Set in memory. In production, use Firestore or secure storage.
    return _unlockedLessons.contains(lessonTitle);
  }
  Set<String> _unlockedLessons = {};

  Future<void> _checkCourseCompleted() async {
    final snap = await FirebaseFirestore.instance
        .collection('completed_courses')
        .where('userEmail', isEqualTo: widget.userEmail)
        .where('courseId', isEqualTo: widget.course['id'])
        .get();
    setState(() {
      _isCourseCompleted = snap.docs.isNotEmpty;
    });
  }

  Future<void> _markCourseAsCompleted() async {
    if (_isCourseCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course already completed!')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('completed_courses').add({
        'userEmail': widget.userEmail,
        'courseId': widget.course['id'],
        'courseTitle': widget.course['title'],
        'trainerEmail': widget.course['trainerEmail'],
        'completedAt': FieldValue.serverTimestamp(),
      });
      setState(() { _isCourseCompleted = true; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course marked as completed!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking course as completed: $e')),
      );
    }
  }

  void _showLessonContent(Map<String, dynamic> lesson) {
    final isPremiumLesson = lesson['isPremium'] ?? false;
    final canAccess = !isPremiumLesson || isPremiumUser || widget.course['isPremium'] == false || hasUnlockedPremiumLesson(lesson['title']);

    if (!canAccess) {
      _showPremiumPrompt(lesson['title']);
      return;
    }

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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPremiumLesson ? Icons.star : Icons.play_circle_filled,
                        color: isPremiumLesson ? Colors.orange : Colors.blue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson['title'],
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isPremiumLesson)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Premium Lesson',
                                style: GoogleFonts.poppins(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if ((lesson['content'] ?? '').isNotEmpty) ...[
                  Text(
                    'Lesson Content',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson['content'],
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                ],
                if ((lesson['videoURL'] ?? '').isNotEmpty) ...[
                  Text(
                    'Lesson Video',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.play_circle_fill),
                    label: Text('Watch Video'),
                    onPressed: () => _launchVideo(lesson['videoURL']),
                  ),
                  const SizedBox(height: 24),
                ],
                if ((lesson['subtopics'] ?? []).isNotEmpty) ...[
                  Text(
                    'Lesson Outline',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List<Widget>.from((lesson['subtopics'] ?? []).map<Widget>((subtopic) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(subtopic)),
                      ],
                    ),
                  ))),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPremiumPrompt(String lessonTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Premium Content',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'This lesson is premium. Please pay to unlock.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'No real transaction will occur. This is a simulated payment.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSimulatedPaymentDialog(lessonTitle);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Pay to Unlock'),
          ),
        ],
      ),
    );
  }

  void _showSimulatedPaymentDialog(String lessonTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Simulated Payment'),
        content: Text('This is a simulated payment dialog. No real transaction will occur.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _unlockedLessons.add(lessonTitle);
              });
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Payment Successful'),
                  content: Text('You have successfully unlocked this premium lesson (simulation).'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: Text('Simulate Payment'),
          ),
        ],
      ),
    );
  }

  void _navigateToPremium() {
    // Navigate to premium features screen
    // This should be implemented based on your premium system
  }

  void _launchVideo(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch video')),
      );
    }
  }

  void _markLessonAsCompleted(Map<String, dynamic> lesson) async {
    try {
      // Check if already completed
      final existingCompletion = await FirebaseFirestore.instance
          .collection('completed_lessons')
          .where('userEmail', isEqualTo: widget.userEmail)
          .where('courseId', isEqualTo: widget.course['id'])
          .where('lessonTitle', isEqualTo: lesson['title'])
          .get();

      if (existingCompletion.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson already completed!')),
        );
        return;
      }

      // Mark lesson as completed
      await FirebaseFirestore.instance.collection('completed_lessons').add({
        'userEmail': widget.userEmail,
        'courseId': widget.course['id'],
        'courseTitle': widget.course['title'],
        'lessonTitle': lesson['title'],
        'trainerEmail': widget.course['trainerEmail'],
        'completedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson marked as completed!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking lesson as completed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Course Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseHeader(),
                  const SizedBox(height: 24),
                  _buildCourseInfo(),
                  const SizedBox(height: 24),
                  _buildLessonsList(),
                  const SizedBox(height: 24),
                  if (widget.userRole == 'learner')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCourseCompleted ? null : _markCourseAsCompleted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isCourseCompleted ? 'Course Completed' : 'Mark as Completed',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (widget.userRole == 'learner')
                    CourseRatingSection(courseId: widget.course['id'], learnerEmail: widget.userEmail),
                ],
              ),
            ),
    );
  }

  Widget _buildCourseHeader() {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
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
                    Icons.school,
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
                        widget.course['title'] ?? 'Untitled Course',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'By: ${widget.course['trainerName'] ?? 'Unknown Trainer'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.course['description'] ?? 'No description available',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfo() {
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
              'Course Information',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Category', widget.course['category'] ?? 'General'),
                ),
                Expanded(
                  child: _buildInfoItem('Level', widget.course['level'] ?? 'Beginner'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Duration', widget.course['duration'] ?? 'Not specified'),
                ),
                Expanded(
                  child: _buildInfoItem('Lessons', '${lessons.length}'),
                ),
              ],
            ),
            if (widget.course['isPremium'] == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Premium Course - \$${widget.course['price']?.toString() ?? '0'}',
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsList() {
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
              'Course Lessons',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final isPremiumLesson = lesson['isPremium'] ?? false;
                final canAccess = !isPremiumLesson || isPremiumUser || widget.course['isPremium'] == false || hasUnlockedPremiumLesson(lesson['title']);
                final subtopics = (lesson['subtopics'] is List) ? lesson['subtopics'] : [];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPremiumLesson 
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPremiumLesson ? Icons.star : Icons.play_circle_filled,
                        color: isPremiumLesson ? Colors.orange : Colors.green,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      lesson['title'] ?? 'Untitled',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPremiumLesson)
                          Text(
                            'Premium Lesson',
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        if (subtopics.isNotEmpty)
                          Text(
                            '${subtopics.length} subtopics',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        canAccess ? Icons.arrow_forward_ios : Icons.lock,
                        color: canAccess ? Colors.grey : Colors.orange,
                      ),
                      onPressed: () => _showLessonContent(lesson),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 

class CourseRatingSection extends StatefulWidget {
  final String courseId;
  final String learnerEmail;
  const CourseRatingSection({Key? key, required this.courseId, required this.learnerEmail}) : super(key: key);

  @override
  State<CourseRatingSection> createState() => _CourseRatingSectionState();
}

class _CourseRatingSectionState extends State<CourseRatingSection> {
  int _selectedRating = 0;
  String _reviewText = '';
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  bool _hasRated = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final snap = await FirebaseFirestore.instance
        .collection('course_ratings')
        .where('courseId', isEqualTo: widget.courseId)
        .get();
    final docs = snap.docs.map((d) => d.data()).toList();
    double avg = 0;
    if (docs.isNotEmpty) {
      avg = docs.map((e) => (e['rating'] ?? 0) as int).reduce((a, b) => a + b) / docs.length;
    }
    final myRating = docs.firstWhere(
      (r) => r['learnerEmail'] == widget.learnerEmail,
      orElse: () => {},
    );
    setState(() {
      _reviews = docs;
      _averageRating = avg;
      if (myRating.isNotEmpty) {
        _selectedRating = myRating['rating'] ?? 0;
        _reviewText = myRating['review'] ?? '';
        _hasRated = true;
      }
    });
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) return;
    setState(() { _isSubmitting = true; });
    final ref = FirebaseFirestore.instance.collection('course_ratings');
    // Check if already rated
    final snap = await ref
        .where('courseId', isEqualTo: widget.courseId)
        .where('learnerEmail', isEqualTo: widget.learnerEmail)
        .get();
    if (snap.docs.isNotEmpty) {
      await ref.doc(snap.docs.first.id).update({
        'rating': _selectedRating,
        'review': _reviewText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.add({
        'courseId': widget.courseId,
        'learnerEmail': widget.learnerEmail,
        'rating': _selectedRating,
        'review': _reviewText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    setState(() { _isSubmitting = false; });
    _loadReviews();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating submitted!')));
  }

  Widget _buildStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => IconButton(
        icon: Icon(
          i < _selectedRating ? Icons.star : Icons.star_border,
          color: Colors.amber,
        ),
        onPressed: (i + 1 == _selectedRating && _hasRated) ? null : () {
          setState(() { _selectedRating = i + 1; });
        },
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 20),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course Rating', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStars(),
                const SizedBox(width: 8),
                Text(_averageRating > 0 ? _averageRating.toStringAsFixed(1) : '-', style: GoogleFonts.poppins()),
                const SizedBox(width: 4),
                Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text('(${_reviews.length} reviews)', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: !_hasRated || _selectedRating != 0,
              decoration: const InputDecoration(
                labelText: 'Write a review (optional)',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
              onChanged: (v) => _reviewText = v,
              controller: TextEditingController(text: _reviewText),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isSubmitting || _selectedRating == 0 ? null : _submitRating,
              child: _isSubmitting ? const CircularProgressIndicator() : Text(_hasRated ? 'Update Rating' : 'Submit Rating'),
            ),
            const Divider(height: 24),
            Text('Reviews', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ..._reviews.map((r) => ListTile(
              leading: Icon(Icons.star, color: Colors.amber),
              title: Text('${r['rating']} stars', style: GoogleFonts.poppins()),
              subtitle: r['review'] != null && r['review'].toString().isNotEmpty ? Text(r['review']) : null,
              trailing: r['learnerEmail'] == widget.learnerEmail ? Text('(You)', style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue)) : null,
            )),
          ],
        ),
      ),
    );
  }
} 