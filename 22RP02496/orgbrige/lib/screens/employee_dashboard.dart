import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'employee_task_detail.dart';
import 'employee_notifications.dart';
import 'employee_settings.dart';
import 'employee_reports.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');
    final employeeDoc = await FirebaseFirestore.instance.collection('employees').doc(user.uid).get();
    final tasksSnap = await FirebaseFirestore.instance.collection('tasks').where('employeeId', isEqualTo: user.uid).get();
    final now = DateTime.now();
    // Check for overdue tasks and set to rejected if needed
    for (final doc in tasksSnap.docs) {
      final data = doc.data();
      final deadline = data['deadline'] is Timestamp ? (data['deadline'] as Timestamp).toDate() : null;
      final status = data['status'];
      if (deadline != null && now.isAfter(deadline) && status != 'completed' && status != 'rejected') {
        // Check if a report exists for this task
        final reports = await FirebaseFirestore.instance.collection('reports')
          .where('taskId', isEqualTo: doc.id)
          .get();
        if (reports.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('tasks').doc(doc.id).update({'status': 'rejected'});
        }
      }
    }
    int totalTasks = tasksSnap.size;
    int pendingTasks = tasksSnap.docs.where((doc) => doc['status'] == 'pending').length;
    int inProgressTasks = tasksSnap.docs.where((doc) => doc['status'] == 'in_progress').length;
    int completedTasks = tasksSnap.docs.where((doc) => doc['status'] == 'completed').length;
    List<Map<String, dynamic>> tasks = tasksSnap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    return {
      'employee': employeeDoc.data(),
      'tasks': tasks,
      'totalTasks': totalTasks,
      'pendingTasks': pendingTasks,
      'inProgressTasks': inProgressTasks,
      'completedTasks': completedTasks,
    };
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showReportableTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final tasksSnap = await FirebaseFirestore.instance
          .collection('tasks')
          .where('employeeId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      final tasks = tasksSnap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (tasks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tasks available for report submission')),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Select Task for Report',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(
                      task['title'] ?? 'Task',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Status: ${task['status']}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeTaskDetail(task: task),
                        ),
                      ).then((value) {
                        if (value == true) {
                          setState(() {
                            _dashboardData = _fetchDashboardData();
                          });
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
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

  void _showProPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Upgrade to Pro',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Unlock Pro features like advanced analytics, priority support, and more!\n\nA payment is required to upgrade your account.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Employee Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: () => _logout(context),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final data = snapshot.data!;
          final employee = data['employee'] ?? {};
          final tasks = data['tasks'] as List<Map<String, dynamic>>;
          final totalTasks = data['totalTasks'] as int;
          final pendingTasks = data['pendingTasks'] as int;
          final inProgressTasks = data['inProgressTasks'] as int;
          final completedTasks = data['completedTasks'] as int;
          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04, // Responsive padding
              vertical: 12,
            ),
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                      Color(0xFFf093fb),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05), // Responsive padding
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFf8f9fa)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: MediaQuery.of(context).size.width * 0.08, // Responsive size
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            Icons.person, 
                            size: MediaQuery.of(context).size.width * 0.12, 
                            color: const Color(0xFF667eea)
                          ),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee['name'] ?? 'Employee',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.06, // Responsive font
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              employee['department'] != null ? 'Department: ${employee['department']}' : '',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive font
                                color: Colors.white.withOpacity(0.9),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02), // Responsive spacing
              // Premium Banner
              Container(
                margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.015),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: MediaQuery.of(context).size.height * 0.015,
                ),
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
                    Icon(
                      Icons.workspace_premium, 
                      color: Colors.white, 
                      size: MediaQuery.of(context).size.width * 0.08
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unlock Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width * 0.045,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Upgrade to Pro for advanced features!',
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: MediaQuery.of(context).size.width * 0.035
                            ),
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
                          horizontal: MediaQuery.of(context).size.width * 0.03,
                          vertical: MediaQuery.of(context).size.height * 0.01,
                        ),
                      ),
                      child: Text(
                        'Go Pro',
                        style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),
                      ),
                    ),
                  ],
                ),
              ),
              // Stats
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.12, // Fixed height for stats
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('Total', totalTasks, Colors.blue, Icons.assignment),
                    _buildStatCard('Pending', pendingTasks, Colors.orange, Icons.hourglass_empty),
                    _buildStatCard('In Progress', inProgressTasks, Colors.amber, Icons.timelapse),
                    _buildStatCard('Completed', completedTasks, Colors.green, Icons.check_circle),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              Text(
                'My Tasks',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.055,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF667eea).withOpacity(0.5),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              tasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks assigned.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                      itemBuilder: (context, i) {
                        final task = tasks[i];
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.003),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.03,
                              vertical: MediaQuery.of(context).size.height * 0.005,
                            ),
                            leading: Container(
                              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.assignment, 
                                color: Colors.white, 
                                size: MediaQuery.of(context).size.width * 0.05
                              ),
                            ),
                            title: Text(
                              task['title'] ?? '',
                              style: TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.w600,
                                fontSize: MediaQuery.of(context).size.width * 0.04,
                              ),
                            ),
                            subtitle: Text(
                              'Deadline: ${task['deadline'] != null ? (task['deadline'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : 'N/A'}\nPriority: ${task['priority']}\nStatus: ${task['status']}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: MediaQuery.of(context).size.width * 0.035,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmployeeTaskDetail(task: task),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  setState(() {
                                    _dashboardData = _fetchDashboardData();
                                  });
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.055,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF667eea).withOpacity(0.5),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleAction(Icons.assignment_turned_in, 'Submit Report', () {
                    _showReportableTasks();
                  }),
                  _buildCircleAction(Icons.description, 'My Reports', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmployeeReports(),
                      ),
                    );
                  }),
                  _buildCircleAction(Icons.notifications, 'Notifications', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmployeeNotifications(),
                      ),
                    );
                  }),
                  _buildCircleAction(Icons.settings, 'Settings', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmployeeSettings(),
                      ),
                    );
                  }),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.2, // Responsive width
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.008,
          horizontal: MediaQuery.of(context).size.width * 0.015,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon, 
                color: Colors.white, 
                size: MediaQuery.of(context).size.width * 0.05
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.006),
            Text(
              '$value',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.002),
            Text(
              label,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.03,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                child: Icon(
                  icon, 
                  color: Colors.white, 
                  size: MediaQuery.of(context).size.width * 0.06
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.006),
        Text(
          label,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.03,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 