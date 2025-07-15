import '../db/database_helper_stub.dart'
  if (dart.library.io) '../db/database_helper.dart'
  if (dart.library.html) '../db/database_helper_hive.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final dbHelper = DatabaseHelper();
      final users = await dbHelper.getUsers();
      if (users.isNotEmpty && users.first['premium'] == true) {
        setState(() {
          isPremium = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _setPremiumStatus() async {
    final dbHelper = DatabaseHelper();
    final users = await dbHelper.getUsers();
    if (users.isNotEmpty) {
      final user = users.first;
      user['premium'] = true;
      await dbHelper.updateUser(user);
      setState(() {
        isPremium = true;
      });
    }
  }

  void _showPayPalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.blue),
            SizedBox(width: 8),
            Text('Pay with PayPal'),
          ],
        ),
        content: Text('Simulate a PayPal payment to unlock premium features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              Navigator.pop(context);
              await _setPremiumStatus();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment successful! You are now premium.')),
              );
            },
            child: Text('Pay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.blueGrey[800]),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/signin');
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPremium)
                Chip(
                  avatar: Icon(Icons.star, color: Colors.white),
                  label: Text('Premium', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.amber[800],
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                )
              else
                ElevatedButton.icon(
                  onPressed: _showPayPalDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: Icon(Icons.payment),
                  label: Text('Go Premium', style: TextStyle(fontSize: 16)),
                ),
              SizedBox(height: 20),
              Text('Good Morning, Clement!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[800])),
              SizedBox(height: 8),
              Text('Ready to achieve your study goals today?',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800])),
              SizedBox(height: 24),

              /// STATISTICS
              Text('Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              StreamBuilder(
                stream: FirebaseFirestore.instance.collection('sessions').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  int sessionCount = 0;
                  int hoursThisWeek = 0;
                  int activePartners = 0;
                  int dayStreak = 0;
                  if (snapshot.hasData) {
                    final sessions = snapshot.data!.docs;
                    sessionCount = sessions.length;
                    // For demo: assume each session is 2 hours and each has 1 unique partner
                    hoursThisWeek = sessionCount * 2;
                    activePartners = sessionCount;
                    dayStreak = sessionCount > 0 ? 7 : 0; // For demo, 7 if any sessions
                  }
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statCard(dayStreak.toString(), 'Day Streak'),
                          _statCard(hoursThisWeek.toString(), 'Hours This Week'),
                          _statCard(activePartners.toString(), 'Active Partners'),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),

              /// ACTIONS
              Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _actionCard(context, 'Create Session', Icons.add, '/create-session'),
                          _actionCard(context, 'Find Partner', Icons.people, '/find-partner'),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          _actionCard(context, 'Joined Sessions', Icons.timer, '/joined-sessions'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              /// UPCOMING SESSION
              Text('Upcoming Session',
                  style: TextStyle(color: Colors.blue[700], fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 10),
              Card(
                color: Colors.blueGrey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Today 2:00 PM', style: TextStyle(fontSize: 20)),
                ),
              ),
              SizedBox(height: 24),

              /// SESSIONS
              Text('All Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              StreamBuilder(
                stream: FirebaseFirestore.instance.collection('sessions').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text('No sessions found.');
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final rawData = doc.data();
                      if (rawData == null) return SizedBox.shrink();
                      final data = rawData as Map<String, dynamic>;
                      final title = data['title'] ?? 'No Title';
                      final description = data['description'] ?? '';
                      final type = data['type'] ?? '';
                      final sessionDate = data['date'] != null ? DateTime.tryParse(data['date']) : null;
                      final sessionDateStr = sessionDate != null ? DateFormat('EEE, MMM d, yyyy h:mm a').format(sessionDate) : '';
                      final participantsList = (data['participants'] as List?)?.cast<String>() ?? [];
                      final participants = participantsList.join(', ');
                      final createdAt = data['createdAt'] != null && data['createdAt'] is Timestamp
                        ? (data['createdAt'] as Timestamp).toDate()
                        : null;
                      final formattedTime = createdAt != null
                        ? DateFormat('EEE, MMM d, yyyy h:mm a').format(createdAt)
                        : '';
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              participantsList.isNotEmpty
                                ? participantsList.first[0].toUpperCase()
                                : '?',
                            ),
                          ),
                          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (description.isNotEmpty) Text(description),
                              if (type.isNotEmpty) Text('Type: $type'),
                              if (sessionDateStr.isNotEmpty) Text('Session: $sessionDateStr'),
                              if (participants.isNotEmpty) Text('Participants: $participants'),
                              if (formattedTime.isNotEmpty) Text('Created: $formattedTime'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on Home
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/find-partner');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/update-profile');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/joined-sessions');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/notification');
              break;
          }
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Partner'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Session'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notification'),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context, String title, IconData icon, String route) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 6),
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: Colors.blueGrey),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionRow(List<Widget> actions) {
    return Row(
      children: actions,
    );
  }
}
