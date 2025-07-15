import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyGigsScreen extends StatefulWidget {
  const MyGigsScreen({super.key});

  @override
  State<MyGigsScreen> createState() => _MyGigsScreenState();
}

class _MyGigsScreenState extends State<MyGigsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _myGigs = [];
  final List<String> _statuses = ['applied', 'in progress', 'completed'];

  @override
  void initState() {
    super.initState();
    _loadMyGigs();
  }

  Future<void> _loadMyGigs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final appsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('applications')
        .get();
    final List<Map<String, dynamic>> gigs = [];
    for (final doc in appsSnap.docs) {
      final data = doc.data();
      final jobId = data['jobId'];
      final status = data['status'];
      // Fetch job details
      final jobSnap = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
      if (jobSnap.exists) {
        final jobData = jobSnap.data()!;
        gigs.add({
          'applicationId': doc.id,
          'jobId': jobId,
          'status': status,
          'title': jobData['title'],
          'description': jobData['description'],
          'category': jobData['category'],
        });
      }
    }
    setState(() {
      _myGigs = gigs;
      _loading = false;
    });
  }

  Future<void> _updateStatus(String applicationId, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final Map<String, dynamic> updateData = {'status': newStatus};
    
    // If marking as completed, add completion timestamp and amount
    if (newStatus == 'completed') {
      updateData['completedAt'] = FieldValue.serverTimestamp();
      
      // Get the amount from the job details
      final appDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('applications')
          .doc(applicationId)
          .get();
      
      if (appDoc.exists) {
        final jobId = appDoc.data()?['jobId'];
        if (jobId != null) {
          final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
          if (jobDoc.exists) {
            final amount = jobDoc.data()?['pay'];
            if (amount != null) {
              updateData['amount'] = amount;
            }
          }
        }
      }
    }
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('applications')
        .doc(applicationId)
        .update(updateData);
    
    _loadMyGigs();
    
    // Show success message for completed gigs
    if (newStatus == 'completed') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gig marked as completed! Income has been updated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Gigs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myGigs.isEmpty
              ? const Center(child: Text('No gigs applied yet.'))
              : ListView.builder(
                  itemCount: _myGigs.length,
                  itemBuilder: (context, index) {
                    final gig = _myGigs[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(gig['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(gig['description'] ?? ''),
                            const SizedBox(height: 4),
                            Text('Category: ${gig['category'] ?? ''}'),
                            const SizedBox(height: 4),
                            DropdownButton<String>(
                              value: gig['status'],
                              items: _statuses.map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null && val != gig['status']) {
                                  _updateStatus(gig['applicationId'], val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 