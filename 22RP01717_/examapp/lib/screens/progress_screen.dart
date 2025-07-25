import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressScreen extends StatefulWidget {
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressService progressService = ProgressService();
  Map<String, dynamic> progress = {};
  Map<String, List<int>> mockScores = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      progress = await progressService.loadProgress();
      mockScores = await progressService.loadMockTestScores();
    } catch (e) {
      progress = {};
      mockScores = {};
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F8FFF), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Progress', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: loading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: progress.isEmpty && mockScores.isEmpty
                    ? Center(
                        child: Text(
                          'No progress yet. Start practicing or take a mock test!',
                          style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        children: [
                          if (progress.isNotEmpty)
                            ...progress.keys.map((cat) {
                              final data = progress[cat];
                              final scores = mockScores[cat] ?? [];
                              return Card(
                                color: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: Icon(Icons.category, color: Colors.indigo),
                                  title: Text(cat, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Attempted: ${data['attempted']} | Correct: ${data['correct']}', style: GoogleFonts.poppins()),
                                      if (scores.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6.0),
                                          child: Text('Mock Test Scores: ${scores.join(', ')}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.deepPurple)),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          if (mockScores.isNotEmpty)
                            ...mockScores.keys.where((cat) => !progress.containsKey(cat)).map((cat) {
                              final scores = mockScores[cat] ?? [];
                              return Card(
                                color: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: Icon(Icons.bar_chart, color: Colors.amber[800]),
                                  title: Text(cat, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  subtitle: Text('Mock Test Scores: ${scores.join(', ')}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.deepPurple)),
                                ),
                              );
                            }).toList(),
                        ],
                      ),
              ),
      ),
    );
  }
} 