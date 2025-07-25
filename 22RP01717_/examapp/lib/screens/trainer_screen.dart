import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/progress_service.dart';
import 'question_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class TrainerScreen extends StatefulWidget {
  @override
  State<TrainerScreen> createState() => _TrainerScreenState();
}

class _TrainerScreenState extends State<TrainerScreen> {
  Map<String, dynamic> progress = {};
  bool loading = true;
  List<String> weakCategories = [];
  List<String> assignedQuestions = [];
  bool loadingAssigned = true;

  final Map<String, IconData> categoryIcons = {
    'biology': Icons.biotech,
    'chemistry': Icons.science,
    'physics': Icons.flash_on,
    'mathematics': Icons.calculate,
    'math': Icons.calculate,
    'english': Icons.menu_book,
    'kinyarwanda': Icons.language,
    'history': Icons.history_edu,
    'geography': Icons.public,
    'literature': Icons.menu_book,
    'sports': Icons.sports_soccer,
    'general knowledge': Icons.lightbulb,
  };

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadAssignedQuestions();
  }

  Future<void> _loadProgress() async {
    setState(() { loading = true; });
    final prog = await ProgressService().loadProgress();
    setState(() {
      progress = prog;
      weakCategories = _findWeakCategories(prog);
      loading = false;
    });
  }

  Future<void> _loadAssignedQuestions() async {
    setState(() { loadingAssigned = true; });
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('assignedQuestions')) {
        assignedQuestions = List<String>.from(doc['assignedQuestions'] ?? []);
      }
    }
    setState(() { loadingAssigned = false; });
  }

  List<String> _findWeakCategories(Map<String, dynamic> prog) {
    final List<Map<String, dynamic>> stats = [];
    prog.forEach((cat, data) {
      final attempted = data['attempted'] ?? 0;
      final correct = data['correct'] ?? 0;
      if (attempted > 0) {
        final accuracy = correct / attempted;
        stats.add({'category': cat, 'accuracy': accuracy, 'attempted': attempted});
      }
    });
    stats.sort((a, b) => a['accuracy'].compareTo(b['accuracy']));
    return stats.take(2).map((e) => e['category'] as String).toList();
  }

  void _startPersonalizedQuiz() {
    if (weakCategories.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionScreen(
            category: weakCategories.first,
            numQuestions: 10,
          ),
        ),
      );
    }
  }

  void _startAssignedQuiz() async {
    if (assignedQuestions.isNotEmpty) {
      // Fetch assigned question data
      final questionDocs = await FirebaseFirestore.instance.collection('questions').where(FieldPath.documentId, whereIn: assignedQuestions).get();
      final assignedQs = questionDocs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionScreen(
            category: 'Assigned',
            numQuestions: assignedQs.length,
            questions: assignedQs,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    if (user?.userType == 'admin') {
      // Redirect admins to HomeScreen
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      });
      return SizedBox.shrink();
    }
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
          title: Text('Personal Trainer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: loading || loadingAssigned
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Personalized Modules', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                    SizedBox(height: 16),
                    if (assignedQuestions.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('You have assigned questions from your trainer!', style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _startAssignedQuiz,
                            icon: Icon(Icons.assignment_turned_in),
                            label: Text('Start Assigned Quiz'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    if (weakCategories.isEmpty)
                      Text('No weak areas detected yet. Practice more to get recommendations!', style: GoogleFonts.poppins(color: Colors.white)),
                    if (weakCategories.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: weakCategories.length,
                          itemBuilder: (context, index) {
                            final cat = weakCategories[index];
                            final attempted = progress[cat]['attempted'] ?? 0;
                            final correct = progress[cat]['correct'] ?? 0;
                            final accuracy = attempted > 0 ? (correct / attempted * 100).toStringAsFixed(1) : '0';
                            return Card(
                              color: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: Icon(categoryIcons[cat.toLowerCase()] ?? Icons.star, color: Colors.indigo),
                                title: Text('Weak Area: ${cat[0].toUpperCase() + cat.substring(1)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                subtitle: Text('Accuracy: $accuracy%  |  Attempted: $attempted', style: GoogleFonts.poppins()),
                              ),
                            );
                          },
                        ),
                      ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: weakCategories.isNotEmpty ? _startPersonalizedQuiz : null,
                      icon: Icon(Icons.quiz),
                      label: Text('Start Personalized Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
} 