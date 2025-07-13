import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/freemium_service.dart';
import '../services/ad_service.dart';
import '../services/security_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'premium_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final FreemiumService _freemiumService = FreemiumService();
  final AdService _adService = AdService();
  bool _isPremium = false;
  bool _showUpgradePrompt = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final isPremium = await _freemiumService.isPremium();
    setState(() {
      _isPremium = isPremium;
    });
  }

  Future<void> _checkFeatureLimit(String feature) async {
    bool canUse = false;
    switch (feature) {
      case 'student':
        canUse = await _freemiumService.canAddStudent();
        break;
      case 'course':
        canUse = await _freemiumService.canAddCourse();
        break;
      case 'attendance':
        canUse = await _freemiumService.canTakeAttendance();
        break;
      case 'grade':
        canUse = await _freemiumService.canAddGrade();
        break;
    }

    if (!canUse && !_isPremium) {
      setState(() {
        _showUpgradePrompt = true;
      });
      _showUpgradeDialog();
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
          'You\'ve reached the free tier limit. Upgrade to Premium for unlimited access to all features!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumScreen()),
              );
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.flash_on, color: Colors.deepPurple, size: 24),
                SizedBox(width: 8),
                Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await _checkFeatureLimit('student');
                    if (await _freemiumService.canAddStudent() || _isPremium) {
                      Navigator.pushNamed(context, '/add_student');
                    }
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Student'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add_grades'),
                  icon: const Icon(Icons.grade),
                  label: const Text('Add Grades'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _checkFeatureLimit('course');
                    if (await _freemiumService.canAddCourse() || _isPremium) {
                      Navigator.pushNamed(context, '/add_course');
                    }
                  },
                  icon: const Icon(Icons.book),
                  label: const Text('Add Course'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _checkFeatureLimit('attendance');
                    if (await _freemiumService.canTakeAttendance() || _isPremium) {
                      Navigator.pushNamed(context, '/take_attendance');
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Take Attendance'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                // Add more actions here as needed
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _summaryCard('Students', Icons.group, Colors.deepPurple, 'students'),
        _summaryCard('Courses', Icons.book, Colors.blue, 'courses'),
        _summaryCard('Grades', Icons.grade, Colors.orange, 'grades'),
      ],
    );
  }

  Widget _summaryCard(String label, IconData icon, Color color, String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(count, style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome to EduManage',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              // Premium Upgrade Prompt
              if (!_isPremium && _showUpgradePrompt)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade100, Colors.blue.shade100],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.purple.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upgrade to Premium',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                            Text(
                              'Unlock unlimited features and remove ads',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PremiumScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Upgrade'),
                      ),
                    ],
                  ),
                ),

              _buildQuickActions(context),
              _buildSummaryCards(),

              // (No Recent Admins or Recent Students section)

              // Students Section
              _buildSection(
                title: 'Recent Students',
                icon: Icons.group,
                color: Colors.deepPurple,
                child: SizedBox(
                  height: 150,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('students').orderBy('createdAt', descending: true).limit(5).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final students = snapshot.data!.docs;
                      if (students.isEmpty) return const Text('No students found.');
                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final doc = students[index];
                          final s = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.person, color: Colors.deepPurple),
                            title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Full Name: ${s['name'] ?? ''}\nStudent ID:  ${s['studentId'] ?? ''} | Email: ${s['email'] ?? ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  tooltip: 'Edit Student',
                                  onPressed: () {
                                    _showEditStudentDialog(context, doc.id, s);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete Student',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Student'),
                                        content: Text('Are you sure you want to delete ${s['name'] ?? 'this student'}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FirebaseFirestore.instance.collection('students').doc(doc.id).delete();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Student deleted.')),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.deepPurple),
                              tooltip: 'View Details',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Student Details'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Name:  ${s['name'] ?? ''} '),
                                        Text('Student ID: ${s['studentId'] ?? ''}'),
                                        Text('Email: ${s['email'] ?? ''}'),
                                        // Add more fields if available
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Courses Section
              _buildSection(
                title: 'Recent Courses',
                icon: Icons.book,
                color: Colors.blue,
                child: SizedBox(
                  height: 150,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('courses').orderBy('createdAt', descending: true).limit(5).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final courses = snapshot.data!.docs;
                      if (courses.isEmpty) return const Text('No courses found.');
                      return ListView.builder(
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final doc = courses[index];
                          final c = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.book, color: Colors.blue),
                            title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Code: ${c['code'] ?? ''} | Credit: ${c['credit'] ?? ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  tooltip: 'Edit Course',
                                  onPressed: () {
                                    _showEditCourseDialog(context, doc.id, c);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete Course',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Course'),
                                        content: Text('Are you sure you want to delete ${c['name'] ?? 'this course'}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FirebaseFirestore.instance.collection('courses').doc(doc.id).delete();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Course deleted.')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Grades Section
              _buildSection(
                title: 'Recent Grades',
                icon: Icons.grade,
                color: Colors.orange,
                child: SizedBox(
                  height: 150,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('grades').orderBy('createdAt', descending: true).limit(5).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final grades = snapshot.data!.docs;
                      if (grades.isEmpty) return const Text('No grades found.');
                      return ListView.builder(
                        itemCount: grades.length,
                        itemBuilder: (context, index) {
                          final doc = grades[index];
                          final g = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.grade, color: Colors.orange),
                            title: Text(g['course'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (g['studentId'] != null) Text('Student ID: ${g['studentId']}'),
                                if (g['courseId'] != null) Text('Course ID: ${g['courseId']}'),
                                if (g['marks'] != null) Text('Marks: ${g['marks']}'),
                                if (g['grade'] != null) Text('Grade: ${g['grade']}'),
                                if (g['gpa'] != null) Text('GPA: ${g['gpa']}'),
                                if (g['semester'] != null) Text('Semester: ${g['semester']}'),
                                if (g['createdAt'] != null && g['createdAt'] is Timestamp)
                                  Text('Added: ${(g['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  tooltip: 'Edit Grade',
                                  onPressed: () {
                                    _showEditGradeDialog(context, doc.id, g);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete Grade',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Grade'),
                                        content: Text('Are you sure you want to delete this grade?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FirebaseFirestore.instance.collection('grades').doc(doc.id).delete();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Grade deleted.')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Attendance Section (with names)
              _buildSection(
                title: 'Recent Attendance',
                icon: Icons.check_circle,
                color: Colors.green,
                child: SizedBox(
                  height: 150,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('attendance').orderBy('timestamp', descending: true).limit(5).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final records = snapshot.data!.docs;
                      if (records.isEmpty) return const Text('No attendance records found.');
                      return ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final doc = records[index];
                          final record = doc.data() as Map<String, dynamic>;
                          final timestamp = record['timestamp'] != null && record['timestamp'] is Timestamp
                              ? (record['timestamp'] as Timestamp).toDate().toString().substring(0, 16)
                              : '';
                                return ListTile(
                                  leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text('Student ID: ${record['studentId'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (record['studentName'] != null) Text('Student Name: ${record['studentName']}'),
                                if (record['courseId'] != null) Text('Course ID: ${record['courseId']}'),
                                if (record['status'] != null) Text('Status: ${record['status']}'),
                                if (timestamp.isNotEmpty) Text('Time: $timestamp'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  tooltip: 'Edit Attendance',
                                  onPressed: () {
                                    _showEditAttendanceDialog(context, doc.id, record);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete Attendance',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Attendance'),
                                        content: Text('Are you sure you want to delete this attendance record?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FirebaseFirestore.instance.collection('attendance').doc(doc.id).delete();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Attendance deleted.')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Add more sections here as needed
            ],
          ),
        );
      case 1:
        // Students Tab: Show all students from Firestore
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('All Students', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/add_student'),
                    icon: Icon(Icons.person_add),
                    label: Text('Add Student'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('students').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final students = snapshot.data!.docs;
                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No students found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add your first student to get started',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/add_student'),
                              icon: Icon(Icons.person_add),
                              label: Text('Add Student'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index].data() as Map<String, dynamic>;
                        final hasUid = s['uid'] != null && s['uid'].toString().isNotEmpty;
                        final createdAt = s['createdAt'] != null && s['createdAt'] is Timestamp
                            ? (s['createdAt'] as Timestamp).toDate()
                            : null;
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.deepPurple.shade100,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s['name'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'ID: ${s['studentId'] ?? 'N/A'}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: hasUid ? Colors.green.shade100 : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        hasUid ? 'Active' : 'Pending',
                                        style: TextStyle(
                                          color: hasUid ? Colors.green.shade700 : Colors.orange.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.email, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        s['email'] ?? 'No email',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (s['gender'] != null) ...[
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 8),
                                      Text(
                                        'Gender: ${s['gender']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (createdAt != null) ...[
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 8),
                                      Text(
                                        'Added: ${createdAt.toString().substring(0, 10)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      hasUid ? Icons.check_circle : Icons.info_outline,
                                      size: 16,
                                      color: hasUid ? Colors.green : Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        hasUid 
                                            ? 'Student can log in with email and password'
                                            : 'Account created but login not configured',
                                        style: TextStyle(
                                          color: hasUid ? Colors.green.shade700 : Colors.orange.shade700,
                                          fontSize: 12,
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
                    );
                  },
                ),
              ),
            ],
          ),
        );
      case 2:
        // Courses Tab: Show all courses from Firestore
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All Courses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('courses').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final courses = snapshot.data!.docs;
                    if (courses.isEmpty) return const Text('No courses found.');
                    return ListView.builder(
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final c = courses[index].data() as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.book, color: Colors.blue),
                            title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Code: ${c['code'] ?? ''} | Credit: ${c['credit'] ?? ''}'),
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
      case 3:
        return _buildSettingsPage();
      case 4:
        return const PremiumScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _showEditStudentDialog(BuildContext context, String docId, Map<String, dynamic> student) {
    final nameController = TextEditingController(text: student['name'] ?? '');
    final emailController = TextEditingController(text: student['email'] ?? '');
    final idController = TextEditingController(text: student['studentId'] ?? '');
    final genderController = TextEditingController(text: student['gender'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
              TextField(
                controller: genderController,
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('students').doc(docId).update({
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'studentId': idController.text.trim(),
                'gender': genderController.text.trim(),
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Student updated.')),
              );
            },
            child: const Text('Update', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(BuildContext context, String docId, Map<String, dynamic> course) {
    final nameController = TextEditingController(text: course['name'] ?? '');
    final codeController = TextEditingController(text: course['code'] ?? '');
    final creditController = TextEditingController(text: course['credit']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Course Code'),
              ),
              TextField(
                controller: creditController,
                decoration: const InputDecoration(labelText: 'Credit'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('courses').doc(docId).update({
                'name': nameController.text.trim(),
                'code': codeController.text.trim(),
                'credit': creditController.text.trim(),
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Course updated.')),
              );
            },
            child: const Text('Update', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showEditGradeDialog(BuildContext context, String docId, Map<String, dynamic> grade) {
    final courseController = TextEditingController(text: grade['course'] ?? '');
    final courseIdController = TextEditingController(text: grade['courseId'] ?? '');
    final marksController = TextEditingController(text: grade['marks']?.toString() ?? '');
    final gradeController = TextEditingController(text: grade['grade'] ?? '');
    final gpaController = TextEditingController(text: grade['gpa'] ?? '');
    final semesterController = TextEditingController(text: grade['semester'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Grade'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courseController,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
              TextField(
                controller: courseIdController,
                decoration: const InputDecoration(labelText: 'Course ID'),
              ),
              TextField(
                controller: marksController,
                decoration: const InputDecoration(labelText: 'Marks'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(labelText: 'Grade'),
              ),
              TextField(
                controller: gpaController,
                decoration: const InputDecoration(labelText: 'GPA'),
              ),
              TextField(
                controller: semesterController,
                decoration: const InputDecoration(labelText: 'Semester'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('grades').doc(docId).update({
                'course': courseController.text.trim(),
                'courseId': courseIdController.text.trim(),
                'marks': marksController.text.trim(),
                'grade': gradeController.text.trim(),
                'gpa': gpaController.text.trim(),
                'semester': semesterController.text.trim(),
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Grade updated.')),
              );
            },
            child: const Text('Update', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showEditAttendanceDialog(BuildContext context, String docId, Map<String, dynamic> record) {
    final studentNameController = TextEditingController(text: record['studentName'] ?? '');
    final courseIdController = TextEditingController(text: record['courseId'] ?? '');
    final statusController = TextEditingController(text: record['status'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Attendance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: studentNameController,
                decoration: const InputDecoration(labelText: 'Student Name'),
              ),
              TextField(
                controller: courseIdController,
                decoration: const InputDecoration(labelText: 'Course ID'),
              ),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('attendance').doc(docId).update({
                'studentName': studentNameController.text.trim(),
                'courseId': courseIdController.text.trim(),
                'status': statusController.text.trim(),
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Attendance updated.')),
              );
            },
            child: const Text('Update', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildSettingsCard(
                  title: 'Profile Admin',
                  subtitle: 'Manage your admin profile and preferences',
                  icon: Icons.person,
                  color: Colors.deepPurple,
                  onTap: () {
                    _showProfileAdminDialog();
                  },
                ),
                _buildSettingsCard(
                  title: 'Account Settings',
                  subtitle: 'Manage your account and security settings',
                  icon: Icons.security,
                  color: Colors.blue,
                  onTap: () {
                    _showAccountSettingsDialog();
                  },
                ),
                _buildSettingsCard(
                  title: 'App Preferences',
                  subtitle: 'Customize your app experience',
                  icon: Icons.settings,
                  color: Colors.orange,
                  onTap: () {
                    _showAppPreferencesDialog();
                  },
                ),
                _buildSettingsCard(
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  icon: Icons.notifications,
                  color: Colors.green,
                  onTap: () {
                    _showNotificationsDialog();
                  },
                ),
                _buildSettingsCard(
                  title: 'Data & Privacy',
                  subtitle: 'Manage your data and privacy settings',
                  icon: Icons.privacy_tip,
                  color: Colors.red,
                  onTap: () {
                    _showDataPrivacyDialog();
                  },
                ),
                _buildSettingsCard(
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  icon: Icons.help,
                  color: Colors.teal,
                  onTap: () {
                    _showHelpSupportDialog();
                  },
                ),
                _buildSettingsCard(
                  title: 'About',
                  subtitle: 'App version and information',
                  icon: Icons.info,
                  color: Colors.grey,
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showProfileAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Admin'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Profile Management'),
            SizedBox(height: 16),
            Text('• View and edit your admin profile'),
            Text('• Update personal information'),
            Text('• Change profile picture'),
            Text('• Manage admin permissions'),
            Text('• View admin activity log'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to detailed profile admin page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile Admin feature coming soon!')),
              );
            },
            child: const Text('Open Profile'),
          ),
        ],
      ),
    );
  }

  void _showAccountSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Management'),
            SizedBox(height: 16),
            Text('• Change password'),
            Text('• Update email address'),
            Text('• Two-factor authentication'),
            Text('• Account security settings'),
            Text('• Login history'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAppPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Preferences'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Customization'),
            SizedBox(height: 16),
            Text('• Theme settings'),
            Text('• Language preferences'),
            Text('• Display options'),
            Text('• Default settings'),
            Text('• Accessibility options'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification Settings'),
            SizedBox(height: 16),
            Text('• Push notifications'),
            Text('• Email notifications'),
            Text('• SMS notifications'),
            Text('• Notification frequency'),
            Text('• Quiet hours'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDataPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data & Privacy'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Settings'),
            SizedBox(height: 16),
            Text('• Data collection preferences'),
            Text('• Privacy policy'),
            Text('• Data export'),
            Text('• Account deletion'),
            Text('• GDPR compliance'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Support Options'),
            SizedBox(height: 16),
            Text('• FAQ and tutorials'),
            Text('• Contact support'),
            Text('• Bug reporting'),
            Text('• Feature requests'),
            Text('• User guide'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About EduManage'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Information'),
            SizedBox(height: 16),
            Text('Version: 1.0.0'),
            Text('Build: 2025.01.01'),
            Text('Developer: EduManage Team'),
            Text('© 2025 EduManage'),
            SizedBox(height: 8),
            Text('A comprehensive education management system for teachers and institutions.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            setState(() => _isLoggingOut = true);
            try {
              await SecurityService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: ${e.toString()}')),
                );
              }
            } finally {
              if (mounted) setState(() => _isLoggingOut = false);
            }
          },
        ),
        actions: [
          _isLoggingOut
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () async {
                    setState(() => _isLoggingOut = true);
                    try {
                      await SecurityService.signOut();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logout failed: ${e.toString()}')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoggingOut = false);
                    }
                  },
                ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(context)),
          // Banner Ad for free users
          if (!_isPremium) const BannerAdWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_student'),
        backgroundColor: Colors.green,
        child: const Icon(Icons.person_add),
        tooltip: 'Add Student',
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
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
            icon: Icon(Icons.group),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Premium',
          ),
        ],
      ),
    );
  }
} 