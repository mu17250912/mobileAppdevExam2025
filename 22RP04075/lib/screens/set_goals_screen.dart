import 'package:flutter/material.dart';

class SetGoalsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Set Goals', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title & Description
            Text('Study Goals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Set your daily and weekly study targets to stay motivated and track your progress.',
                style: TextStyle(fontSize: 15, color: Colors.grey[800]),
              ),
            ),

            SizedBox(height: 24),

            /// Daily Goal
            Text('Daily Study Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('4', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 12),
                Text('hours / day', style: TextStyle(fontSize: 16)),
              ],
            ),

            SizedBox(height: 20),

            /// Preferred Time
            Text('Preferred Study Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 10),
            Row(
              children: [
                _timeBox('09:00 AM'),
                SizedBox(width: 12),
                _timeBox('05:00 PM'),
              ],
            ),

            SizedBox(height: 28),

            /// Weekly Goals
            Text('Weekly Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Row(
              children: [
                _goalBox('25\nHours / Week'),
                SizedBox(width: 12),
                _goalBox('5\nSessions / Week'),
              ],
            ),
          ],
        ),
      ),

      /// Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/find-partner');
              break;
            case 2:
              // Already on Profile
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/join-session');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Partner'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Session'),
        ],
      ),
    );
  }

  Widget _timeBox(String time) {
    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.blueGrey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(width: 6),
            Icon(Icons.access_time, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _goalBox(String label) {
    return Expanded(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.blueGrey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
