import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'category_screen.dart';
import 'trainer_screen.dart';
import 'progress_screen.dart';
import 'package:exam_app/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'admin_panel_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_test_screen.dart'; // Added import for MockTestScreen
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'premium_screen.dart'; // Added import for PremiumScreen
import 'trainer_dashboard_screen.dart'; // Added import for TrainerDashboardScreen

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int shareCount = 0;
  bool hasShared = false;
  String userType = 'normal'; // or 'premium'

  void shareApp() async {
    await Share.share('Check out this awesome exam app!');
    setState(() {
      shareCount++;
      if (shareCount >= 2) {
        hasShared = true;
      }
    });
  }

  void goPremium() {
    setState(() {
      userType = 'premium';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final isAdmin = user?.userType == 'admin';
    final isTrainer = user?.userType == 'trainer';
    if (isTrainer) {
      // Redirect trainers to their dashboard
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrainerDashboardScreen(
              displayName: user?.displayName,
              email: user?.email,
            ),
          ),
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Icon(Icons.school, color: Colors.white, size: 32),
              SizedBox(width: 10),
              Text('Exam App', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.white)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              tooltip: 'Settings & Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      email: user?.email,
                      isPremium: user?.userType == 'premium',
                      displayName: user?.displayName,
                      avatarUrl: user?.avatarUrl,
                      uid: user?.uid,
                    ),
                  ),
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
                    Icon(Icons.school, color: Colors.white, size: 40),
                    SizedBox(height: 12),
                    Text(user?.displayName ?? 'User', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    SizedBox(height: 4),
                    Text(user?.email ?? '', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 8),
                    Text(user?.userType == 'premium' ? 'Premium User' : (isAdmin ? 'Admin' : 'Normal User'), style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              if (isAdmin)
                ListTile(
                  leading: Icon(Icons.admin_panel_settings),
                  title: Text('Admin Panel', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminPanelScreen()),
                    );
                  },
                ),
              if (isAdmin)
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout', style: GoogleFonts.poppins()),
                  onTap: () async {
                    await AuthService().signOut();
                    Provider.of<UserProvider>(context, listen: false).clearUser();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              if (!isAdmin && !isTrainer) ...[
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Home', style: GoogleFonts.poppins()),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(Icons.category),
                  title: Text('Categories', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryScreen(
                          userType: userType,
                          hasShared: hasShared,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.quiz),
                  title: Text('Mock Test', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MockTestScreen(category: 'Math'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.flag),
                  title: Text('Flagged Questions', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to Flagged Questions screen
                  },
                ),
                ListTile(
                  leading: Icon(Icons.fitness_center),
                  title: Text('Personal Trainer', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TrainerScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          email: user?.email,
                          isPremium: user?.userType == 'premium',
                          displayName: user?.displayName,
                          avatarUrl: user?.avatarUrl,
                          uid: user?.uid,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.workspace_premium),
                  title: Text('Go Premium', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Show premium dialog or screen
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout', style: GoogleFonts.poppins()),
                  onTap: () async {
                    await AuthService().signOut();
                    Provider.of<UserProvider>(context, listen: false).clearUser();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        body: isAdmin
            ? AdminPanelScreen()
            : Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 24),
                        Card(
                          color: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            leading: Icon(Icons.play_circle_fill, color: Colors.indigo, size: 36),
                            title: Text('Start Practicing', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryScreen(
                                    userType: userType,
                                    hasShared: hasShared,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        Card(
                          color: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            leading: Icon(Icons.fitness_center, color: Colors.deepPurple, size: 36),
                            title: Text('Personal Trainer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TrainerScreen()),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        Card(
                          color: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            leading: Icon(Icons.bar_chart, color: Colors.amber[800], size: 36),
                            title: Text('View Progress', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProgressScreen()),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        Card(
                          color: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            leading: Icon(Icons.share, color: Colors.pinkAccent, size: 36),
                            title: Text('Share App', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                            subtitle: Text('Shared on $shareCount platform(s)', style: GoogleFonts.poppins(fontSize: 13)),
                            onTap: shareApp,
                          ),
                        ),
                        SizedBox(height: 16),
                        Card(
                          color: userType == 'premium' ? Colors.green[50] : Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            leading: Icon(Icons.workspace_premium, color: Colors.orange, size: 36),
                            title: Text('Go Premium', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                            onTap: userType == 'premium' ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PremiumScreen()),
                              );
                            },
                            trailing: userType == 'premium'
                                ? Text('Premium', style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold))
                                : null,
                          ),
                        ),
                        if (user?.userType == 'admin')
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Card(
                              color: Colors.indigo[50],
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: ListTile(
                                leading: Icon(Icons.admin_panel_settings, color: Colors.indigo, size: 36),
                                title: Text('Admin Panel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AdminPanelScreen()),
                                  );
                                },
                              ),
                            ),
                          ),
                        SizedBox(height: 32),
                        Text('Developed by Anitha', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class DownloadedScreen extends StatefulWidget {
  @override
  State<DownloadedScreen> createState() => _DownloadedScreenState();
}

class _DownloadedScreenState extends State<DownloadedScreen> {
  List<String> downloaded = [];

  @override
  void initState() {
    super.initState();
    _loadDownloaded();
  }

  Future<void> _loadDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      downloaded = prefs.getStringList('downloadedQuestions') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Downloaded Questions')),
      body: downloaded.isEmpty
          ? Center(child: Text('No downloaded questions.'))
          : ListView.builder(
              itemCount: downloaded.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(downloaded[index]),
              ),
            ),
    );
  }
} 