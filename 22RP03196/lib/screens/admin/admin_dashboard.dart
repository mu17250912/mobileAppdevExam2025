import 'package:flutter/material.dart';
import 'manage_workouts_screen.dart';
import 'user_stats_screen.dart';
import 'manage_premium_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Stream<int> _userCountStream() => FirebaseFirestore.instance.collection('users').snapshots().map((s) => s.docs.length);
  Stream<int> _premiumUserCountStream() => FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'premium').snapshots().map((s) => s.docs.length);
  Stream<int> _workoutCountStream() => FirebaseFirestore.instance.collection('workouts').snapshots().map((s) => s.docs.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22A6F2),
        elevation: 0,
        title: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StreamBuilder<int>(
                  stream: _userCountStream(),
                  builder: (context, snapshot) {
                    return _StatCard(
                      label: 'Total Users',
                      value: snapshot.hasData ? snapshot.data.toString() : '...',
                      icon: Icons.people,
                    );
                  },
                ),
                StreamBuilder<int>(
                  stream: _premiumUserCountStream(),
                  builder: (context, snapshot) {
                    return _StatCard(
                      label: 'Pro-Adrvl',
                      value: snapshot.hasData ? snapshot.data.toString() : '...',
                      icon: Icons.star,
                    );
                  },
                ),
                StreamBuilder<int>(
                  stream: _workoutCountStream(),
                  builder: (context, snapshot) {
                    return _StatCard(
                      label: 'Planno lPaths',
                      value: snapshot.hasData ? snapshot.data.toString() : '...',
                      icon: Icons.fitness_center,
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 32),
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: Icon(Icons.fitness_center, color: const Color(0xFF22A6F2)),
                title: Text('Manage Workouts', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageWorkoutsScreen())),
              ),
            ),
            SizedBox(height: 18),
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: Icon(Icons.add_chart, color: const Color(0xFF22A6F2)),
                title: Text('View User Stats', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserStatsScreen())),
              ),
            ),
            SizedBox(height: 18),
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: Icon(Icons.lock, color: const Color(0xFF22A6F2)),
                title: Text('Manage Premium Content', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManagePremiumScreen())),
              ),
            ),
            SizedBox(height: 24),
            StreamBuilder<int>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'premium').snapshots().map((s) => s.docs.length),
              builder: (context, snapshot) {
                final premiumCount = snapshot.hasData ? snapshot.data.toString() : '...';
                return Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    leading: Icon(Icons.account_balance_wallet, color: const Color(0xFF22A6F2)),
                    title: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Premium Users: $premiumCount'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF22A6F2), size: 28),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF22A6F2))),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
} 