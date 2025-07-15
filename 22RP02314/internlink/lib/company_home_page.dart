import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/post_internship_page.dart';
import 'pages/company_applications_page.dart';
import 'pages/notifications_page.dart';
import 'pages/company_profile_page.dart';
import 'services/internship_service.dart';
import 'services/application_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/company_all_internships_page.dart';

class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({Key? key}) : super(key: key);

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  int _postedCount = 0;
  int _applicationsCount = 0;
  int _interviewsCount = 0;
  final InternshipService _internshipService = InternshipService();
  final ApplicationService _applicationService = ApplicationService();
  String? _companyName;
  bool isPremium = false; // TODO: Replace with real premium check

  @override
  void initState() {
    super.initState();
    _loadCompanyNameAndStats();
  }

  Future<void> _loadCompanyNameAndStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Fetch company name
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return;
    final data = userDoc.data();
    final companyName = data != null ? data['companyName'] as String? : null;
    setState(() {
      _companyName = companyName;
    });
    // Fetch internships and filter by companyName
    _internshipService.getCompanyInternships(user.uid).first.then((internships) {
      final filtered = companyName == null
        ? internships
        : internships.where((i) => i.companyName == companyName).toList();
      setState(() {
        _postedCount = filtered.length;
      });
    });
    // Applications and interviews
    _applicationService.getCompanyApplications(user.uid).first.then((applications) {
      setState(() {
        _applicationsCount = applications.length;
        _interviewsCount = applications.where((a) => a.status == 'approved').length;
      });
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
              child: Icon(Icons.business_center, color: Color(0xFF0D3B24), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Company Dashboard',
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
            // Premium warning banner
            if (!isPremium)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.amber[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Upgrade to premium to unlock all features, including posting internships.',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.amber[800],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () {
                          setState(() {
                            isPremium = true;
                          });
                        },
                        child: const Text('Upgrade Now'),
                      ),
                    ],
                  ),
                ),
              ),
            // Horizontal scrollable stats card
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _StatCard(
                    icon: Icons.work,
                    label: 'Posted',
                    value: _postedCount.toString(),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _StatCard(
                    icon: Icons.people,
                    label: 'Applications',
                    value: _applicationsCount.toString(),
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _StatCard(
                    icon: Icons.check_circle,
                    label: 'Interviews',
                    value: _interviewsCount.toString(),
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            // Company Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: Colors.white, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_companyName ?? 'Your Company',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          const Text('Manage your internships and applications',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
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
                    icon: Icons.add_box_outlined,
                    title: 'Post Internship',
                    subtitle: 'Create new opportunities',
                    color: Colors.blue,
                    onTap: () {
                      if (!isPremium) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Unlock Premium'),
                            content: const Text('Upgrade your company account to unlock the ability to post internships.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isPremium = true;
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text('Upgrade Now'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PostInternshipPage(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Applications',
                    subtitle: 'View all applications',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CompanyApplicationsPage(),
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
                    icon: Icons.business_outlined,
                    title: 'Company Profile',
                    subtitle: 'Manage your profile',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CompanyProfilePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.list_alt,
                    title: 'All Internships',
                    subtitle: 'View all posted internships',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyAllInternshipsPage(),
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
              MaterialPageRoute(builder: (context) => const PostInternshipPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CompanyApplicationsPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CompanyProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
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