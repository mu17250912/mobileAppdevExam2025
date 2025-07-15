import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileManagementScreen extends StatefulWidget {
  final String userEmail;
  final String userRole;
  
  const ProfileManagementScreen({Key? key, required this.userEmail, required this.userRole}) : super(key: key);

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  bool isEditing = false;
  String? profileImageUrl;
  bool isUploadingPhoto = false;
  List<Map<String, dynamic>> completedCourses = [];
  List<Map<String, dynamic>> jobApplications = [];
  List<Map<String, dynamic>> createdCourses = [];
  List<Map<String, dynamic>> connectedLearners = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    if (widget.userRole == 'learner') {
      _loadCompletedCourses();
      _loadJobApplications();
    } else {
      _loadCreatedCourses();
      _loadConnectedLearners();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .get();
      
      if (query.docs.isNotEmpty) {
        final profile = query.docs.first.data();
        setState(() {
          userProfile = profile;
          _nameController.text = profile['name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _specializationController.text = profile['specialization'] ?? '';
          profileImageUrl = profile['profileImage'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .get();

      if (query.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(query.docs.first.id)
            .update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'bio': _bioController.text.trim(),
          'specialization': _specializationController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        
        setState(() {
          isEditing = false;
        });
        
        _loadUserProfile(); // Refresh the profile
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() { isUploadingPhoto = true; });
      final ref = FirebaseStorage.instance.ref().child('profile_photos/${widget.userEmail}');
      await ref.putData(await picked.readAsBytes());
      final url = await ref.getDownloadURL();
      // Update Firestore
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .get();
      if (query.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(query.docs.first.id)
            .update({'profileImage': url});
      }
      setState(() {
        profileImageUrl = url;
        isUploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated!')),
      );
    }
  }

  Future<void> _loadCompletedCourses() async {
    final snap = await FirebaseFirestore.instance
        .collection('completed_courses')
        .where('userEmail', isEqualTo: widget.userEmail)
        .get();
    setState(() {
      completedCourses = snap.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _loadJobApplications() async {
    final apps = await FirebaseFirestore.instance
        .collection('applications')
        .where('userEmail', isEqualTo: widget.userEmail)
        .get();
    List<Map<String, dynamic>> jobs = [];
    for (var app in apps.docs) {
      final jobSnap = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(app['jobId'])
          .get();
      if (jobSnap.exists) {
        jobs.add({
          ...jobSnap.data()!,
          'appliedAt': app['appliedAt'],
        });
      }
    }
    setState(() {
      jobApplications = jobs;
    });
  }

  Future<void> _loadCreatedCourses() async {
    final snap = await FirebaseFirestore.instance
        .collection('courses')
        .where('trainerEmail', isEqualTo: widget.userEmail)
        .get();
    setState(() {
      createdCourses = snap.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _loadConnectedLearners() async {
    final snap = await FirebaseFirestore.instance
        .collection('connections')
        .where('trainerEmail', isEqualTo: widget.userEmail)
        .where('status', isEqualTo: 'connected')
        .get();
    List<Map<String, dynamic>> learners = [];
    for (var conn in snap.docs) {
      final learnerSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: conn['learnerEmail'])
          .get();
      if (learnerSnap.docs.isNotEmpty) {
        learners.add(learnerSnap.docs.first.data());
      }
    }
    setState(() {
      connectedLearners = learners;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  Card(
                    elevation: 4,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Profile Picture
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: (widget.userRole == 'trainer' ? Colors.green : Colors.blue).withOpacity(0.1),
                                backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty ? NetworkImage(profileImageUrl!) : null,
                                child: profileImageUrl == null || profileImageUrl!.isEmpty
                                    ? Icon(Icons.person, size: 60, color: widget.userRole == 'trainer' ? Colors.green : Colors.blue)
                                    : null,
                              ),
                              if (isUploadingPhoto)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.3),
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                                ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: isUploadingPhoto ? null : _pickAndUploadPhoto,
                                    tooltip: 'Change photo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.userRole == 'learner') ...[
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Completed Courses', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (completedCourses.isEmpty)
                              Text('No courses completed yet.', style: GoogleFonts.poppins(color: Colors.grey)),
                            ...completedCourses.map((c) => ListTile(
                              leading: const Icon(Icons.check_circle, color: Colors.green),
                              title: Text(c['courseTitle'] ?? '', style: GoogleFonts.poppins()),
                              subtitle: c['completedAt'] != null ? Text('Completed') : null,
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Job Applications', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (jobApplications.isEmpty)
                              Text('No job applications yet.', style: GoogleFonts.poppins(color: Colors.grey)),
                            ...jobApplications.map((j) => ListTile(
                              leading: const Icon(Icons.work, color: Colors.indigo),
                              title: Text(j['title'] ?? '', style: GoogleFonts.poppins()),
                              subtitle: Text(j['company'] ?? ''),
                              trailing: j['appliedAt'] != null ? Text('Applied') : null,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (widget.userRole == 'trainer') ...[
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Created Courses', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (createdCourses.isEmpty)
                              Text('No courses created yet.', style: GoogleFonts.poppins(color: Colors.grey)),
                            ...createdCourses.map((c) => ListTile(
                              leading: const Icon(Icons.book, color: Colors.green),
                              title: Text(c['title'] ?? '', style: GoogleFonts.poppins()),
                              subtitle: Text(c['category'] ?? ''),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Connected Learners', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (connectedLearners.isEmpty)
                              Text('No learners connected yet.', style: GoogleFonts.poppins(color: Colors.grey)),
                            ...connectedLearners.map((l) => ListTile(
                              leading: const Icon(Icons.person, color: Colors.blue),
                              title: Text(l['name'] ?? l['email'] ?? '', style: GoogleFonts.poppins()),
                              subtitle: Text(l['email'] ?? ''),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Profile Details
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Information',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Name Field
                          _buildInfoField(
                            'Full Name',
                            _nameController,
                            Icons.person,
                            isEditing: isEditing,
                          ),
                          const SizedBox(height: 16),

                          // Phone Field
                          _buildInfoField(
                            'Phone Number',
                            _phoneController,
                            Icons.phone,
                            isEditing: isEditing,
                          ),
                          const SizedBox(height: 16),

                          // Bio Field
                          _buildInfoField(
                            'Bio',
                            _bioController,
                            Icons.info,
                            isEditing: isEditing,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),

                          // Specialization Field (for trainers)
                          if (widget.userRole == 'trainer')
                            _buildInfoField(
                              'Specialization',
                              _specializationController,
                              Icons.school,
                              isEditing: isEditing,
                            ),

                          // Action Buttons
                          if (isEditing) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        isEditing = false;
                                        // Reset to original values
                                        _nameController.text = userProfile?['name'] ?? '';
                                        _phoneController.text = userProfile?['phone'] ?? '';
                                        _bioController.text = userProfile?['bio'] ?? '';
                                        _specializationController.text = userProfile?['specialization'] ?? '';
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('Save'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Account Statistics
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Statistics',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'Member Since',
                                  _formatDate(userProfile?['createdAt']),
                                  Icons.calendar_today,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Last Updated',
                                  _formatDate(userProfile?['updatedAt']),
                                  Icons.update,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Rating & Review for trainers (if viewing as learner and not self)
                  if (widget.userRole == 'learner' && userProfile != null && userProfile!['email'] != widget.userEmail && userProfile!['role'] == 'trainer')
                    TrainerRatingSection(trainerEmail: userProfile!['email'], learnerEmail: widget.userEmail),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isEditing = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isEditing)
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              controller.text.isEmpty ? 'Not specified' : controller.text,
              style: GoogleFonts.poppins(
                color: controller.text.isEmpty ? Colors.grey[500] : Colors.black87,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
} 

class TrainerRatingSection extends StatefulWidget {
  final String trainerEmail;
  final String learnerEmail;
  const TrainerRatingSection({Key? key, required this.trainerEmail, required this.learnerEmail}) : super(key: key);

  @override
  State<TrainerRatingSection> createState() => _TrainerRatingSectionState();
}

class _TrainerRatingSectionState extends State<TrainerRatingSection> {
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
        .collection('trainer_ratings')
        .where('trainerEmail', isEqualTo: widget.trainerEmail)
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
    final ref = FirebaseFirestore.instance.collection('trainer_ratings');
    // Check if already rated
    final snap = await ref
        .where('trainerEmail', isEqualTo: widget.trainerEmail)
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
        'trainerEmail': widget.trainerEmail,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trainer Rating', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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