import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'manager_employee_list.dart';
import './manager_add_edit_employee.dart';
import 'manager_create_edit_task.dart';
import 'manager_task_list.dart';
import 'manager_reports_viewer.dart';
import 'manager_notifications.dart';
import 'manager_profile_settings.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({Key? key}) : super(key: key);

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  late Future<Map<String, dynamic>> _dashboardData;
  String? _profileImageUrl;
  bool _uploading = false;
  bool _showAddEmployeeButton = true;

  @override
  void initState() {
    super.initState();
    _dashboardData = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');
    final managerDoc = await FirebaseFirestore.instance.collection('managers').doc(user.uid).get();
    final employeesSnap = await FirebaseFirestore.instance.collection('employees').where('managerId', isEqualTo: user.uid).get();
    final tasksSnap = await FirebaseFirestore.instance.collection('tasks').where('managerId', isEqualTo: user.uid).get();
    int totalTasks = tasksSnap.size;
    int pendingTasks = tasksSnap.docs.where((doc) => doc['status'] == 'pending').length;
    int completedTasks = tasksSnap.docs.where((doc) => doc['status'] == 'completed').length;
    List<Map<String, dynamic>> employees = employeesSnap.docs.map((e) => e.data()).toList();
    final managerData = managerDoc.data();
    if (managerData != null && managerData['profileImageUrl'] != null) {
      _profileImageUrl = managerData['profileImageUrl'];
    }
    return {
      'manager': managerData,
      'employees': employees,
      'totalTasks': totalTasks,
      'pendingTasks': pendingTasks,
      'completedTasks': completedTasks,
    };
  }

  Future<void> _pickAndUploadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() { _uploading = true; });
    try {
      Uint8List bytes = await picked.readAsBytes();
      final ref = FirebaseStorage.instance.ref().child('manager_profile_pics/${user.uid}.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('managers').doc(user.uid).update({'profileImageUrl': url});
      setState(() { _profileImageUrl = url; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      setState(() { _uploading = false; });
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goTo(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _showProPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Upgrade to Pro'),
        content: const Text(
          'Unlock Pro features like advanced analytics, priority support, and more!\n\nA payment is required to upgrade your account.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Integrate payment flow here
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manager Dashboard', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_showAddEmployeeButton ? Icons.visibility : Icons.visibility_off, color: Colors.deepPurple),
            tooltip: _showAddEmployeeButton ? 'Hide Add Employee Button' : 'Show Add Employee Button',
            onPressed: () {
              setState(() {
                _showAddEmployeeButton = !_showAddEmployeeButton;
              });
            },
          ),
        ],
      ),
      floatingActionButton: _showAddEmployeeButton
          ? Builder(
              builder: (context) {
                final isSmall = width < 350 || height < 700;
                return FloatingActionButton.extended(
                  onPressed: () => _goTo(context, ManagerAddEditEmployee()),
                  icon: Icon(Icons.person_add, size: isSmall ? width * 0.055 : 24),
                  label: Text(
                    'Add Employee',
                    style: TextStyle(
                      fontSize: isSmall ? width * 0.04 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: Colors.deepPurple,
                  extendedPadding: EdgeInsets.symmetric(
                    horizontal: isSmall ? width * 0.04 : 24,
                    vertical: isSmall ? height * 0.012 : 16,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                );
              },
            )
          : null,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final manager = data['manager'] ?? {};
          final employees = data['employees'] as List<Map<String, dynamic>>;
          final totalTasks = data['totalTasks'] as int;
          final pendingTasks = data['pendingTasks'] as int;
          final completedTasks = data['completedTasks'] as int;
          return SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.015),
              children: [
                // Premium Banner
                Container(
                  margin: EdgeInsets.only(bottom: height * 0.018),
                  padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.018),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.white, size: width * 0.08),
                      SizedBox(width: width * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unlock Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.045,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Upgrade to Pro for advanced analytics, priority support, and more!',
                              style: TextStyle(color: Colors.white, fontSize: width * 0.035),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showProPaymentDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.03,
                            vertical: height * 0.01,
                          ),
                        ),
                        child: Text('Go Pro', style: TextStyle(fontSize: width * 0.035)),
                      ),
                    ],
                  ),
                ),
                // Header Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  margin: EdgeInsets.zero,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6A5AE0), Color(0xFF8F67E8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    padding: EdgeInsets.all(width * 0.05),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _uploading ? null : _pickAndUploadProfileImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: width * 0.08,
                                backgroundColor: Colors.white,
                                backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                                child: _profileImageUrl == null
                                    ? Icon(Icons.account_circle, size: width * 0.12, color: Colors.deepPurple.shade400)
                                    : null,
                              ),
                              if (_uploading)
                                const Positioned.fill(
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                              if (!_uploading)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: CircleAvatar(
                                    radius: width * 0.035,
                                    backgroundColor: Colors.deepPurple,
                                    child: Icon(Icons.edit, size: width * 0.04, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: width * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                manager['name'] ?? 'Manager',
                                style: TextStyle(
                                  fontSize: width * 0.06,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                manager['department'] != null ? 'Department: ${manager['department']}' : '',
                                style: TextStyle(
                                  fontSize: width * 0.035,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.logout, color: Colors.white, size: width * 0.07),
                          tooltip: 'Logout',
                          onPressed: () => _logout(context),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * 0.025),
                // Stats Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPillStatCard('Total Tasks', totalTasks, Colors.blue, Icons.assignment, width, height),
                      _buildPillStatCard('Pending', pendingTasks, Colors.orange, Icons.hourglass_empty, width, height),
                      _buildPillStatCard('Completed', completedTasks, Colors.green, Icons.check_circle, width, height),
                    ],
                  ),
                ),
                SizedBox(height: height * 0.03),
                // Employees Horizontal Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Employees', style: TextStyle(fontSize: width * 0.055, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.people, color: Colors.deepPurple, size: width * 0.07),
                      tooltip: 'View All Employees',
                      onPressed: () => _goTo(context, const ManagerEmployeeList()),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.012),
                SizedBox(
                  height: height * 0.16,
                  child: employees.isEmpty
                      ? Center(child: Text('No employees found.', style: TextStyle(fontSize: width * 0.04)))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: employees.length,
                          separatorBuilder: (_, __) => SizedBox(width: width * 0.04),
                          itemBuilder: (context, i) => _buildEmployeeCard(employees[i], width, height),
                        ),
                ),
                SizedBox(height: height * 0.03),
                // Quick Actions
                Text('Quick Actions', style: TextStyle(fontSize: width * 0.055, fontWeight: FontWeight.bold)),
                SizedBox(height: height * 0.012),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircleAction(Icons.assignment, 'Create Task', () => _goTo(context, const ManagerCreateEditTask()), width, height),
                    _buildCircleAction(Icons.list, 'View Tasks', () => _goTo(context, const ManagerTaskList()), width, height),
                    _buildCircleAction(Icons.report, 'Reports', () => _goTo(context, const ManagerReportsViewer()), width, height),
                    _buildCircleAction(Icons.notifications, 'Notify', () => _goTo(context, const ManagerNotifications()), width, height),
                    _buildCircleAction(Icons.settings, 'Settings', () => _goTo(context, const ManagerProfileSettings()), width, height),
                  ],
                ),
                SizedBox(height: height * 0.02),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPillStatCard(String label, int value, Color color, IconData icon, double width, double height) {
    // Reduce vertical padding and font size for small screens
    final isSmall = height < 700 || width < 350;
    return Container(
      margin: EdgeInsets.only(right: width * 0.04),
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.045,
        vertical: isSmall ? height * 0.012 : height * 0.018,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.18),
            child: Icon(
              icon, 
              color: color, 
              size: isSmall ? width * 0.045 : width * 0.055
            ),
            radius: isSmall ? width * 0.035 : width * 0.045,
          ),
          SizedBox(width: width * 0.025),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: isSmall ? width * 0.035 : width * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmall ? width * 0.025 : width * 0.032,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp, double width, double height) {
    final isSmall = height < 700 || width < 350;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: width * 0.45,
        padding: EdgeInsets.all(width * 0.035),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    emp['name']?[0] ?? '?',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: isSmall ? width * 0.035 : width * 0.045,
                    ),
                  ),
                ),
                SizedBox(width: width * 0.025),
                Expanded(
                  child: Text(
                    emp['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmall ? width * 0.03 : width * 0.04,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.01),
            Flexible(
              child: Text(
                'Department: ${emp['department'] ?? ''}',
                style: TextStyle(
                  fontSize: isSmall ? width * 0.025 : width * 0.032,
                  color: Colors.black54,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, String label, VoidCallback onTap, double width, double height) {
    return Column(
      children: [
        Material(
          color: Colors.deepPurple.shade50,
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(width * 0.035),
              child: Icon(icon, color: Colors.deepPurple, size: width * 0.06),
            ),
          ),
        ),
        SizedBox(height: height * 0.008),
        Text(label, style: TextStyle(fontSize: width * 0.032, fontWeight: FontWeight.w500)),
      ],
    );
  }
} 