import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  int totalUsers = 0;
  Map<String, int> categoryCounts = {};
  double completionRate = 0.0;
  bool isLoading = true;
  int totalStarted = 0;
  int totalCompleted = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() { isLoading = true; });
    // Total users
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    totalUsers = usersSnap.docs.length;

    // Popular categories
    final coursesSnap = await FirebaseFirestore.instance.collection('courses').get();
    categoryCounts.clear();
    for (var doc in coursesSnap.docs) {
      final cat = (doc['category'] ?? 'Unknown').toString();
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    // Courses started
    final startedSnap = await FirebaseFirestore.instance.collection('started_courses').get();
    totalStarted = startedSnap.docs.length;

    // Courses completed
    final completedSnap = await FirebaseFirestore.instance.collection('completed_courses').get();
    totalCompleted = completedSnap.docs.length;

    // Completion rate
    final totalCourses = coursesSnap.docs.length;
    completionRate = totalCourses > 0 ? (totalCompleted / totalCourses) : 0.0;

    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Icon(Icons.people, color: Colors.deepPurple, size: 36),
                      title: Text('Total Users', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      subtitle: Text('$totalUsers', style: GoogleFonts.poppins(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Most Popular Categories', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ..._buildCategoryList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Icon(Icons.play_circle_fill, color: Colors.blue, size: 36),
                      title: Text('Courses Started', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      subtitle: Text('$totalStarted', style: GoogleFonts.poppins(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green, size: 36),
                      title: Text('Courses Completed', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      subtitle: Text('$totalCompleted', style: GoogleFonts.poppins(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green, size: 36),
                      title: Text('Course Completion Rate', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      subtitle: Text('${(completionRate * 100).toStringAsFixed(1)}%', style: GoogleFonts.poppins(fontSize: 24)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildCategoryList() {
    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.label, color: Colors.deepPurple, size: 18),
          const SizedBox(width: 8),
          Text('${e.key}: ', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          Text('${e.value}', style: GoogleFonts.poppins()),
        ],
      ),
    )).toList();
  }
} 