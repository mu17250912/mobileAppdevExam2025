import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/browse_internships_page.dart';
import 'pages/my_applications_page.dart';
import 'pages/notifications_page.dart';
import 'pages/career_resources_page.dart';
import 'pages/student_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({Key? key}) : super(key: key);

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int available = 0;
  int applied = 0;
  int interview = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final firestore = FirebaseFirestore.instance;
    final availableSnap = await firestore
        .collection('internships')
        .where('status', isEqualTo: 'active')
        .get();
    final appliedSnap = await firestore
        .collection('applications')
        .where('studentId', isEqualTo: user.uid)
        .get();
    final interviewSnap = await firestore
        .collection('applications')
        .where('studentId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'interview')
        .get();
    setState(() {
      available = availableSnap.docs.length;
      applied = appliedSnap.docs.length;
      interview = interviewSnap.docs.length;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              backgroundImage: AssetImage('assets/images/logo.png'),
              child: Icon(Icons.school, color: Color(0xFF0D3B24), size: 20), // Add an icon overlay
            ),
            const SizedBox(width: 12),
            const Text(
              'Internlink',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D3B24),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            // Horizontal scrollable stats card
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _StatCard(
                    icon: Icons.work_outline,
                    label: 'Available',
                    value: loading ? '-' : available.toString(),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _StatCard(
                    icon: Icons.send,
                    label: 'Applied',
                    value: loading ? '-' : applied.toString(),
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _StatCard(
                    icon: Icons.star,
                    label: 'Interview',
                    value: loading ? '-' : interview.toString(),
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            // Upgrade Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.amber[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.white, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Upgrade for More Features',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 4),
                          Text('Unlock unlimited applications, priority support, and more!',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.amber[800],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Upgrade Your Account'),
                            content: const Text('Unlock premium features such as unlimited applications, priority support, and more!'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Implement upgrade logic
                                  Navigator.pop(context);
                                },
                                child: const Text('Upgrade Now'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Upgrade'),
                    ),
                  ],
                ),
              ),
            ),
            // Feature List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _FeatureCard(
                    icon: Icons.work_outline,
                    title: 'Browse Internships',
                    subtitle: 'Find available opportunities',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseInternshipsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.menu_book_outlined,
                    title: 'My Applications',
                    subtitle: 'Track your progress',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyApplicationsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    subtitle: 'Stay updated',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    subtitle: 'View and edit profile',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentProfilePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.edit_note_outlined,
                    title: 'Career Resources',
                    subtitle: 'Career guidance',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CareerResourcesPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B2B5A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BrowseInternshipsPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyApplicationsPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StudentProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Application',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94, // match the constraint width
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), // further reduced padding
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20), // even smaller icon
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color), // smaller font
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: color), // smaller font
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      ),
    );
  }
} 