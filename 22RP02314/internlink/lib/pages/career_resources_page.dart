import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'skill_quiz_page.dart';

class CareerResourcesPage extends StatelessWidget {
  const CareerResourcesPage({Key? key}) : super(key: key);

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
              child: Icon(Icons.school, color: Color(0xFF0D3B24), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Career Resources',
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Career Development Resources',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enhance your skills and prepare for your career journey',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Resume Writing Tips'),
            subtitle: const Text('Craft a winning resume.'),
            onTap: () => _launchUrl('https://www.themuse.com/advice/how-to-make-a-resume-examples'),
          ),
          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Interview Preparation Video'),
            subtitle: const Text('Watch this video to prepare for interviews.'),
            onTap: () => _launchUrl('https://www.youtube.com/watch?v=2Yt6raj-S1M'),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download Resume Template'),
            onTap: () => _launchUrl('https://www.canva.com/resumes/templates/'),
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Take a Skill Assessment Quiz'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SkillQuizPage()),
              );
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('FAQs'),
            children: const [
              ListTile(
                title: Text('How do I find internships?'),
                subtitle: Text('Browse the internships section and apply to positions that match your interests.'),
              ),
              ListTile(
                title: Text('How do I improve my resume?'),
                subtitle: Text('Use our resume tips and templates to enhance your resume.'),
              ),
              ListTile(
                title: Text('How do I prepare for interviews?'),
                subtitle: Text('Check out our interview preparation resources and practice common questions.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 