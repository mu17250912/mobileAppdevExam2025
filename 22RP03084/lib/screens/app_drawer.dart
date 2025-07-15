import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_screen.dart';

Future<void> handleLogout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => LoginScreen(onRegisterTap: () {})),
    (route) => false,
  );
}

class AppDrawer extends StatelessWidget {
  final String userId;
  final bool isEmployer;
  const AppDrawer({Key? key, required this.userId, required this.isEmployer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: kGoldenBrown),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.account_circle, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text('TinderJob', style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(isEmployer ? '/employer_profile' : '/job_seeker_profile', arguments: userId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.subscriptions),
            title: const Text('Subscription'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/subscription');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Support'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/support');
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Rate & Feedback'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/feedback');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.of(context).pop();
              await handleLogout(context);
            },
          ),
        ],
      ),
    );
  }
}
