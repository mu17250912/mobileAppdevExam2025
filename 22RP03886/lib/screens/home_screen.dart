import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final userName = userProvider.userProfile?.displayName ?? 'User';
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Good Morning, $userName!'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: true,
            // Remove profile icon from actions
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Color(0xFF3975F6),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Color(0xFF3975F6)),
                      ),
                      SizedBox(height: 12),
                      Text(userName, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ListTile(
              leading: Icon(Icons.check_box),
              title: Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tasks');
              },
            ),
            ListTile(
              leading: Icon(Icons.sticky_note_2),
              title: Text('Notes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notes');
              },
            ),
            ListTile(
              leading: Icon(Icons.subscriptions),
              title: Text('Subscription'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/subscription');
              },
            ),
            ListTile(
              leading: Icon(Icons.manage_accounts),
              title: Text('Manage Subscription'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/subscription-management');
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics),
              title: Text('Analytics Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/analytics-dashboard');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/logout');
              },
            ),
            // You can add more menu items here
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/tasks');
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFFFFE3A3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_box, color: Color(0xFFF9A825), size: 32),
                    SizedBox(width: 16),
                    Text('Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/notes');
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFFD6D6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sticky_note_2, color: Color(0xFF6D8BFF), size: 32),
                    SizedBox(width: 16),
                    Text('Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
} 