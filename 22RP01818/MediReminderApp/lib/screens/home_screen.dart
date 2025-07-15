import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../app_state.dart';
import '../services/reminder_service.dart';
import 'snoozed_notifications_screen.dart';
// ...existing code...
import 'package:provider/provider.dart';
import '../app_state.dart';
// ...existing code...

class HomeScreen extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTab;
  const HomeScreen({super.key, this.selectedIndex = 0, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AppState>().isPremium;
    return Scaffold(
      appBar: AppBar(
        title: Text("MediRemind"),
        backgroundColor: Colors.blueAccent,
        actions: [
          // Notification icon in corner
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: ReminderService().getAllUpcomingReminders(),
            builder: (context, snapshot) {
              final snoozedUnread =
                  snapshot.hasData &&
                  snapshot.data!.any(
                    (reminder) =>
                        reminder['status'] == 'snoozed' && !reminder['read'],
                  );
              return IconButton(
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 24,
                    ),
                    if (snoozedUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SnoozedNotificationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          SizedBox(width: 8),
          // Logout button
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Perform logout
                          context.read<AppState>().logout();
                          Navigator.of(context).pop(); // Close dialog
                          // Navigate to welcome screen and clear navigation stack
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Text('Logout'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFFE6EDFF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF7EA6F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/pills.jpg',
                        width: 180,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'MediRemind',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Never Miss Your Medication Again',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Stay healthy and on track with your medication schedule. Set reminders, track your doses, and manage your prescriptions all in one place.',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    if (!isPremium)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                        child: Text('Go Premium'),
                      ),
                    if (isPremium)
                      Text(
                        'Premium features unlocked!',
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // AdMob is not supported on web, so we remove the AdMob widget for web compatibility
      bottomNavigationBar: null,
    );
  }
}

// AdMob widget removed for web compatibility

// ...existing code...

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Color(0xFF7EA6F6) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.blueAccent : Colors.transparent,
            width: 2,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.blueAccent),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
