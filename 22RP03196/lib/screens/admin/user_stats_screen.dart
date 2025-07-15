import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';

class UserStatsScreen extends StatelessWidget {
  const UserStatsScreen({super.key});

  Stream<int> _activeUserCountStream() => FirebaseFirestore.instance.collection('users').snapshots().map((s) => s.docs.length);
  Stream<int> _premiumUserCountStream() => FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'premium').snapshots().map((s) => s.docs.length);
  Stream<int> _freeUserCountStream() => FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').snapshots().map((s) => s.docs.length);
  Stream<List<AppUser>> _allUsersStream() => FirebaseFirestore.instance.collection('users').snapshots().map((s) => s.docs.map((d) => AppUser.fromMap(d.data(), d.id)).toList());

  Widget _buildPaymentsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('payments').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        double total = 0;
        for (var doc in docs) {
          total += (doc['amount'] as num?)?.toDouble() ?? 0;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            Text('Premium Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Text('Total Balance: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(' 24${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final date = (doc['timestamp'] as Timestamp?)?.toDate();
                  return ListTile(
                    leading: Icon(Icons.payment, color: Colors.blue),
                    title: Text('User: ${doc['userId']}'),
                    subtitle: Text('Amount:  24${(doc['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                    trailing: Text(date != null ? DateFormat('yMMMd, h:mm a').format(date) : ''),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22A6F2),
        elevation: 0,
        title: Text('User Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<int>(
                    stream: _activeUserCountStream(),
                    builder: (context, snapshot) {
                      return _StatCard(label: 'Active Users', value: snapshot.hasData ? snapshot.data.toString() : '...', icon: Icons.people);
                    },
                  ),
                  StreamBuilder<int>(
                    stream: _premiumUserCountStream(),
                    builder: (context, snapshot) {
                      return _StatCard(label: 'Premium Subs', value: snapshot.hasData ? snapshot.data.toString() : '...', icon: Icons.star);
                    },
                  ),
                  StreamBuilder<int>(
                    stream: _freeUserCountStream(),
                    builder: (context, snapshot) {
                      return _StatCard(label: 'Free Users', value: snapshot.hasData ? snapshot.data.toString() : '...', icon: Icons.person_outline);
                    },
                  ),
                ],
              ),
              SizedBox(height: 32),
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: StreamBuilder<List<AppUser>>(
                  stream: _allUsersStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final users = snapshot.data!;
                    if (users.isEmpty) return Center(child: Text('No users found.'));
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => Divider(),
                      itemBuilder: (context, i) {
                        final user = users[i];
                        return ListTile(
                          leading: Icon(user.isPremium == true ? Icons.star : Icons.person, color: user.isPremium == true ? Colors.amber : Colors.blue),
                          title: Text(user.name ?? user.email),
                          subtitle: Text(user.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: user.isPremium == true,
                                onChanged: (v) async {
                                  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isPremium': v});
                                },
                                activeColor: Colors.orange,
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh, color: Colors.blue),
                                tooltip: 'Reset Progress',
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'completed': [], 'progress': {}});
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete User',
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildPaymentsSection(),
            ],
          ),
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