import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class JobsScreen extends StatefulWidget {
  final String userEmail;
  const JobsScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  List<Map<String, dynamic>> recommendedJobs = [];
  List<String> completedSkills = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendedJobs();
  }

  Future<void> _fetchRecommendedJobs() async {
    setState(() { isLoading = true; });
    // Fetch completed courses/skills
    final completedSnap = await FirebaseFirestore.instance
        .collection('completed_courses')
        .where('userEmail', isEqualTo: widget.userEmail)
        .get();
    completedSkills = completedSnap.docs.map((doc) => doc['courseTitle'] as String? ?? '').where((s) => s.isNotEmpty).toList();

    // Fetch jobs
    final jobsSnap = await FirebaseFirestore.instance.collection('jobs').get();
    recommendedJobs = jobsSnap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).where((job) {
      final requiredSkills = List<String>.from(job['requiredSkills'] ?? []);
      return requiredSkills.any((skill) => completedSkills.contains(skill));
    }).toList();
    setState(() { isLoading = false; });
  }

  Future<void> _applyToJob(Map<String, dynamic> job) async {
    await FirebaseFirestore.instance.collection('applications').add({
      'userEmail': widget.userEmail,
      'jobId': job['id'],
      'jobTitle': job['title'],
      'appliedAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Application sent for ${job['title']}!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommended Jobs', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recommendedJobs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No recommended jobs found.', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Complete more courses to unlock job opportunities!', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recommendedJobs.length,
                  itemBuilder: (context, index) {
                    final job = recommendedJobs[index];
                    final requiredSkills = List<String>.from(job['requiredSkills'] ?? []);
                    final matchedSkills = requiredSkills.where((s) => completedSkills.contains(s)).toList();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job['title'] ?? 'Job Title', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
                            const SizedBox(height: 4),
                            Text(job['company'] ?? 'Company', style: GoogleFonts.poppins(color: Colors.indigo, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(job['location'] ?? 'Location', style: GoogleFonts.poppins(color: Colors.grey[600])),
                            const SizedBox(height: 12),
                            Text(job['description'] ?? '', style: GoogleFonts.poppins()),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: requiredSkills.map((skill) => Chip(
                                label: Text(skill),
                                backgroundColor: matchedSkills.contains(skill) ? Colors.green[100] : Colors.grey[200],
                                labelStyle: GoogleFonts.poppins(color: matchedSkills.contains(skill) ? Colors.green[800] : Colors.grey[700]),
                              )).toList(),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.send),
                                label: const Text('Apply'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _applyToJob(job),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 