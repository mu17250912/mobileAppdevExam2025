import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'trainer_screen.dart';
import 'settings_screen.dart';
import '../services/progress_service.dart';
import 'question_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'assign_questions_screen.dart';
import 'review_user_progress_screen.dart';
import '../services/auth_service.dart'; // Added import for AuthService
import 'login_screen.dart'; // Added import for LoginScreen

class TrainerDashboardScreen extends StatelessWidget {
  final String? displayName;
  final String? email;
  const TrainerDashboardScreen({this.displayName, this.email, Key? key}) : super(key: key);

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
          title: Text('Trainer Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F8FFF), Color(0xFF6C63FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.fitness_center, color: Colors.white, size: 40),
                    SizedBox(height: 12),
                    Text(displayName ?? 'Trainer', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    SizedBox(height: 4),
                    Text(email ?? '', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout', style: GoogleFonts.poppins()),
                onTap: () async {
                  // Sign out logic
                  await AuthService().signOut();
                  Provider.of<UserProvider>(context, listen: false).clearUser();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
        body: _TrainerDashboardBody(displayName: displayName, email: email),
      ),
    );
  }
}

class _TrainerDashboardBody extends StatefulWidget {
  final String? displayName;
  final String? email;
  const _TrainerDashboardBody({this.displayName, this.email});

  @override
  State<_TrainerDashboardBody> createState() => _TrainerDashboardBodyState();
}

class _TrainerDashboardBodyState extends State<_TrainerDashboardBody> {
  Map<String, dynamic> progress = {};
  bool loading = true;
  List<String> weakCategories = [];

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.indigo[100],
                child: Icon(Icons.fitness_center, color: Colors.indigo, size: 36),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${widget.displayName ?? 'Trainer'}!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
                  if (widget.email != null)
                    Text(widget.email!, style: GoogleFonts.poppins(color: Colors.white70)),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Text('Your Weak Areas', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          SizedBox(height: 16),
          loading
              ? Center(child: CircularProgressIndicator())
              : weakCategories.isEmpty
                  ? Text('No weak areas detected yet. Practice more to get recommendations!', style: GoogleFonts.poppins(color: Colors.white))
                  : Column(
                      children: [
                        ...weakCategories.map((cat) {
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
                        }).toList(),
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
          SizedBox(height: 16),
          Text('Your Modules', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          SizedBox(height: 16),
          Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.star, color: Colors.indigo),
              title: Text('Personal Trainer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text('Access your smart assistant and track your progress.', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrainerScreen()),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AssignQuestionsScreen()),
              );
            },
            icon: Icon(Icons.assignment_ind),
            label: Text('Assign Questions to User'),
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReviewUserProgressScreen()),
              );
            },
            icon: Icon(Icons.bar_chart),
            label: Text('Review User Progress'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
          Spacer(),
          Center(
            child: Text('Thank you for supporting learners!', style: GoogleFonts.poppins(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
} 