import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewUserProgressScreen extends StatefulWidget {
  @override
  _ReviewUserProgressScreenState createState() => _ReviewUserProgressScreenState();
}

class _ReviewUserProgressScreenState extends State<ReviewUserProgressScreen> {
  String? selectedUserId;
  List<Map<String, dynamic>> users = [];
  Map<String, dynamic>? userProgress;
  bool loadingUsers = true;
  bool loadingProgress = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() { loadingUsers = true; });
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    users = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).where((u) => u['userType'] != 'admin' && u['userType'] != 'trainer').toList();
    setState(() { loadingUsers = false; });
  }

  Future<void> fetchUserProgress(String userId) async {
    setState(() { loadingProgress = true; });
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('progress')) {
      userProgress = doc['progress'];
    } else {
      userProgress = null;
    }
    setState(() { loadingProgress = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review User Progress')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select User:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (loadingUsers)
              CircularProgressIndicator(),
            if (!loadingUsers)
              DropdownButton<String>(
                value: selectedUserId,
                items: users.map((u) => DropdownMenuItem<String>(
                  value: u['id'] as String,
                  child: Text((u['email'] ?? u['id']).toString()),
                )).toList(),
                onChanged: (val) async {
                  setState(() { selectedUserId = val; });
                  if (val != null) await fetchUserProgress(val);
                },
              ),
            SizedBox(height: 24),
            if (loadingProgress)
              CircularProgressIndicator(),
            if (!loadingProgress && userProgress == null && selectedUserId != null)
              Text('No progress found for this user.', style: TextStyle(color: Colors.red)),
            if (!loadingProgress && userProgress != null)
              Expanded(
                child: ListView(
                  children: [
                    Text('Progress by Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...userProgress!.entries.map((entry) {
                      final cat = entry.key;
                      final data = entry.value;
                      final attempted = data['attempted'] ?? 0;
                      final correct = data['correct'] ?? 0;
                      return ListTile(
                        title: Text(cat[0].toUpperCase() + cat.substring(1)),
                        subtitle: Text('Attempted: $attempted, Correct: $correct'),
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 