import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 40),
              SizedBox(height: 16),
              Text(
                'You are not logged in.\nPlease log in again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.grade), text: 'Grades'),
            Tab(icon: Icon(Icons.check_circle), text: 'Attendance'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: email)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 40),
                  SizedBox(height: 16),
                  Text(
                    'No student profile found for this account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text('Logout'),
                  ),
                ],
              ),
            );
          }
          final student = docs.first.data() as Map<String, dynamic>;
          final studentId = student['studentId'] ?? '';
          final docId = docs.first.id;

          // Debug print
          print('Logged in studentId: $studentId');

          if (studentId.isEmpty) {
            return Center(
              child: Text(
                'Student ID is missing from your profile. Please contact your administrator.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(student, studentId),
              _buildGradesTab(studentId),
              _buildAttendanceTab(studentId),
              _buildProfileTab(student, docId),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoProfileCard(String email) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Text('No profile found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'We could not find your student profile for:\n$email\n\n'
              'Please make sure you are using the correct email, or contact your administrator to be added to the system.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Login'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // You can add a contact admin action here
                  },
                  icon: const Icon(Icons.contact_support),
                  label: const Text('Contact Admin'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(Map<String, dynamic> student, String docId) {
    final createdAt = student['createdAt'] != null && student['createdAt'] is Timestamp
        ? (student['createdAt'] as Timestamp).toDate()
        : null;
    final hasUid = student['uid'] != null && student['uid'].toString().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Profile Card
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Profile Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Icon(Icons.person, size: 50, color: Colors.deepPurple),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 28,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Active Student',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Personal Information Section
                      _buildInfoSection(
                        'Personal Information',
                        Icons.person_outline,
                        [
                          _buildInfoRow('Full Name', student['name'] ?? 'N/A', Icons.person),
                          _buildInfoRow('Student ID', student['studentId'] ?? 'N/A', Icons.badge),
                          _buildInfoRow('Email', student['email'] ?? 'N/A', Icons.email),
                          if (student['gender'] != null)
                            _buildInfoRow('Gender', student['gender'], Icons.person_outline),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Account Information Section
                      _buildInfoSection(
                        'Account Information',
                        Icons.account_circle,
                        [
                          _buildInfoRow('Account Status', hasUid ? 'Active' : 'Pending', Icons.check_circle, 
                              color: hasUid ? Colors.green : Colors.orange),
                          _buildInfoRow('Role', student['role'] ?? 'Student', Icons.security),
                          if (createdAt != null)
                            _buildInfoRow('Account Created', createdAt.toString().substring(0, 10), Icons.calendar_today),
                          if (student['uid'] != null)
                            _buildInfoRow('User ID', student['uid'].toString().substring(0, 8) + '...', Icons.fingerprint),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.edit, color: Colors.deepPurple),
                      tooltip: 'Edit Profile',
                      onPressed: () => _showEditProfileDialog(student, docId),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // System Information Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'System Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your account was created by an administrator in the EduManage system. '
                    'You have access to view your academic records including grades and attendance.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Email and password authentication enabled',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Access to grades and attendance records',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Add prominent logout button
          SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.deepPurple, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> student, String studentId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Icon(Icons.school, size: 30, color: Colors.white),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              student['name'] ?? 'Student',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Here\'s your academic overview for today',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Courses List
          Text('Your Courses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('courses').orderBy('name').limit(20).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              final courses = snapshot.data!.docs;
              if (courses.isEmpty) {
                return Text('No courses found.', style: TextStyle(color: Colors.grey));
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index].data() as Map<String, dynamic>;
                  final courseName = course['name'] ?? '';
                  final courseId = courses[index].id;
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.book, color: Colors.deepPurple),
                      title: Text(courseName, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Code: ${course['code'] ?? ''}'),
                      onTap: () => _showCourseDetailsDialog(context, studentId, courseId, courseName),
                    ),
                  );
                },
              );
            },
          ),

          SizedBox(height: 24),

          // Statistics Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Courses', Icons.book, Colors.blue, studentId)),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard('Total Grades', Icons.grade, Colors.orange, studentId)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Present Days', Icons.check_circle, Colors.green, studentId)),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard('Absent Days', Icons.cancel, Colors.red, studentId)),
            ],
          ),

          SizedBox(height: 24),

          // Recent Activity
          Text(
            'Recent Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          _buildRecentActivityCard(studentId),

          // Add prominent logout button at the bottom
          SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCourseDetailsDialog(BuildContext context, String studentId, String courseId, String courseName) async {
    // Fetch grade for this course and student
    final gradeSnapshot = await FirebaseFirestore.instance
        .collection('grades')
        .where('studentId', isEqualTo: studentId)
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .get();
    final gradeData = gradeSnapshot.docs.isNotEmpty ? gradeSnapshot.docs.first.data() as Map<String, dynamic> : null;

    // Fetch attendance for this course and student
    final attendanceSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .where('courseId', isEqualTo: courseId)
        .get();
    final attendanceRecords = attendanceSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Details for $courseName'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grade:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (gradeData != null) ...[
                  if (gradeData['marks'] != null)
                    Text('Marks: ${gradeData['marks']}'),
                  Text('Grade: ${gradeData['grade'] ?? 'N/A'}'),
                  if (gradeData['gpa'] != null)
                    Text('GPA: ${gradeData['gpa']}'),
                ],
                if (gradeData == null)
                  Text('No grade found for this course.'),
                SizedBox(height: 16),
                Text('Attendance:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (attendanceRecords.isNotEmpty)
                  ...attendanceRecords.map((record) => Text(
                        '${record['status']} on ${record['timestamp'] != null && record['timestamp'] is Timestamp ? (record['timestamp'] as Timestamp).toDate().toString().substring(0, 10) : ''}',
                      )),
                if (attendanceRecords.isEmpty)
                  Text('No attendance records for this course.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, String studentId) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _getStreamForStat(title, studentId),
              builder: (context, snapshot) {
                int count = 0;
                if (snapshot.hasData) {
                  count = snapshot.data!.docs.length;
                }
                return Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot>? _getStreamForStat(String title, String studentId) {
    switch (title) {
      case 'Total Courses':
        return FirebaseFirestore.instance.collection('courses').snapshots();
      case 'Total Grades':
        return FirebaseFirestore.instance
            .collection('grades')
            .where('studentId', isEqualTo: studentId)
            .snapshots();
      case 'Present Days':
        return FirebaseFirestore.instance
            .collection('attendance')
            .where('studentId', isEqualTo: studentId)
            .where('status', isEqualTo: 'Present')
            .snapshots();
      case 'Absent Days':
        return FirebaseFirestore.instance
            .collection('attendance')
            .where('studentId', isEqualTo: studentId)
            .where('status', isEqualTo: 'Absent')
            .snapshots();
      default:
        return null;
    }
  }

  Widget _buildRecentActivityCard(String studentId) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Latest Updates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('grades')
                  .where('studentId', isEqualTo: studentId)
                  .orderBy('createdAt', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                
                final grades = snapshot.data!.docs;
                if (grades.isEmpty) {
                  return Text(
                    'No recent activity found',
                    style: TextStyle(color: Colors.grey[600]),
                  );
                }

                return Column(
                  children: grades.map((grade) {
                    final data = grade.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Icon(Icons.grade, color: Colors.orange),
                      title: Text('Grade added for ${data['course'] ?? ''}'),
                      subtitle: Text('Grade: ${data['grade'] ?? ''}'),
                      trailing: Text(
                        data['createdAt'] != null
                            ? (data['createdAt'] as Timestamp).toDate().toString().substring(0, 10)
                            : '',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesTab(String studentId) {
    print('Querying grades for studentId: $studentId'); // Debug print
    if (studentId.isEmpty) {
      return Center(
        child: Text(
          'No student ID found. Please contact your administrator.',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('grades')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(); // No spinner, just empty
        }
        final grades = snapshot.data!.docs;
        print('Grades found:  [32m${grades.length} [0m'); // Debug print
        if (grades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grade, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No grades found yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Your grades will appear here once they are added by your instructor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: grades.length,
          itemBuilder: (context, index) {
            final grade = grades[index].data() as Map<String, dynamic>;
            // Determine grade color
            final gradeValue = grade['grade'] ?? '';
            Color gradeColor = Colors.grey;
            if (gradeValue is String) {
              if (gradeValue.contains('A')) gradeColor = Colors.green;
              else if (gradeValue.contains('B')) gradeColor = Colors.blue;
              else if (gradeValue.contains('C')) gradeColor = Colors.orange;
              else if (gradeValue.contains('D') || gradeValue.contains('F')) gradeColor = Colors.red;
            }
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: gradeColor.withOpacity(0.2),
                  child: Icon(Icons.grade, color: gradeColor),
                ),
                title: Text(
                  grade['course'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (grade['courseId'] != null) Text('Course ID: ${grade['courseId']}'),
                    if (grade['marks'] != null) Text('Marks: ${grade['marks']}'),
                    if (grade['grade'] != null) Text('Grade: ${grade['grade']}'),
                    if (grade['gpa'] != null) Text('GPA: ${grade['gpa']}'),
                    if (grade['semester'] != null) Text('Semester: ${grade['semester']}'),
                    if (grade['createdAt'] != null && grade['createdAt'] is Timestamp)
                      Text('Added: ${(grade['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}'),
                  ],
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gradeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    gradeValue,
                    style: TextStyle(
                      color: gradeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceTab(String studentId) {
    if (studentId.isEmpty) {
      return Center(
        child: Text(
          'No student ID found. Please contact your administrator.',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(); // No spinner, just empty
        }
        final attendance = snapshot.data!.docs;
        if (attendance.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No attendance records found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Your attendance will be recorded when you attend classes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: attendance.length,
          itemBuilder: (context, index) {
            final record = attendance[index].data() as Map<String, dynamic>;
            final status = record['status'] ?? '';
            final timestamp = record['timestamp'] != null && record['timestamp'] is Timestamp
                ? (record['timestamp'] as Timestamp).toDate()
                : null;
            Color statusColor = Colors.grey;
            IconData statusIcon = Icons.help;
            if (status == 'Present') {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
            } else if (status == 'Absent') {
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
            } else if (status == 'Late') {
              statusColor = Colors.orange;
              statusIcon = Icons.schedule;
            }
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(statusIcon, color: statusColor),
                ),
                title: Text(status),
                subtitle: timestamp != null
                    ? Text('Date: ${timestamp.toString().substring(0, 16)}')
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog(Map<String, dynamic> student, String docId) {
    final nameController = TextEditingController(text: student['name'] ?? '');
    final genderController = TextEditingController(text: student['gender'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: genderController,
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              TextField(
                controller: TextEditingController(text: student['email'] ?? ''),
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: false,
              ),
              TextField(
                controller: TextEditingController(text: student['studentId']?.toString() ?? ''),
                decoration: const InputDecoration(labelText: 'Student ID'),
                enabled: false,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.lock),
                label: Text('Change Password'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showChangePasswordDialog();
                },
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
            onPressed: () async {
              final newName = nameController.text.trim();
              final newGender = genderController.text.trim();
              if (newName.isEmpty) return;
              try {
                await FirebaseFirestore.instance.collection('students').doc(docId).update({
                  'name': newName,
                  'gender': newGender,
                });
                if (mounted) {
                  Navigator.of(context).pop();
                  setState(() {}); // Refresh UI
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile: \\${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
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
            onPressed: () async {
              final password = passwordController.text.trim();
              final confirm = confirmController.text.trim();
              if (password.isEmpty || password.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 8 characters.')),
                );
                return;
              }
              if (password != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match.')),
                );
                return;
              }
              try {
                await FirebaseAuth.instance.currentUser?.updatePassword(password);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to change password: \\${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
} 