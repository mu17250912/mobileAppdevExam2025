import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../main.dart';

class GigDetailScreen extends StatelessWidget {
  const GigDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final gig = args['gig'] as Map<String, dynamic>;
    final jobId = args['jobId'] as String;
    final user = FirebaseAuth.instance.currentUser;
    final isPoster = gig['posterId'] == user?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(gig['title'] ?? 'Gig Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(gig['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(gig['description'] ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            if (gig['category'] != null)
              Chip(label: Text(gig['category'])),
            if (gig['timestamp'] != null)
              Text('Posted: ${DateFormat.yMMMd().format((gig['timestamp'] as Timestamp).toDate())}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: {
                        'gigId': jobId,
                        'posterId': gig['posterId'],
                        'gigTitle': gig['title'],
                      },
                    );
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.alarm),
                  label: const Text('Set Reminder'),
                  onPressed: () async {
                    final now = DateTime.now();
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 2),
                    );
                    if (pickedDate == null) return;
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime == null) return;
                    final scheduledDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    await scheduleGigReminderNotification(
                      jobId.hashCode,
                      'Gig Reminder',
                      'Reminder for gig: ${gig['title']}',
                      scheduledDateTime,
                    );
                    await FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('notifications').add({
                      'title': 'Gig Reminder Set',
                      'body': 'Reminder set for gig: ${gig['title']} at $scheduledDateTime',
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reminder set for ${scheduledDateTime.toString()}')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.bookmark),
              label: const Text('Bookmark'),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('bookmarks').doc(jobId).set(gig);
                await FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('notifications').add({
                  'title': 'Gig Bookmarked',
                  'body': 'You bookmarked gig: ${gig['title']}',
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gig bookmarked!')),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.work),
              label: const Text('Apply'),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('applications').doc(jobId).set({
                  'jobId': jobId,
                  'status': 'applied',
                });
                await FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('notifications').add({
                  'title': 'Gig Application',
                  'body': 'You applied for gig: ${gig['title']}',
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Applied for gig!')),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Recent Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance.collection('jobs').doc(jobId).collection('feedback').orderBy('timestamp', descending: true).limit(3).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No feedback yet.');
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data();
                    return ListTile(
                      leading: Icon(Icons.star, color: Colors.amber),
                      title: Text('Rating: ${data['rating'] ?? '-'}'),
                      subtitle: Text(data['comment'] ?? ''),
                    );
                  }).toList(),
                );
              },
            ),
            if (isPoster) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    onPressed: () async {
                      final titleController = TextEditingController(text: gig['title']);
                      final descController = TextEditingController(text: gig['description']);
                      String selectedCategory = gig['category'] ?? 'Other';
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Edit Gig'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(labelText: 'Title'),
                              ),
                              TextField(
                                controller: descController,
                                decoration: const InputDecoration(labelText: 'Description'),
                              ),
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                items: ['Design', 'Writing', 'Tutoring', 'Delivery', 'Other'].map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                )).toList(),
                                onChanged: (val) => selectedCategory = val!,
                                decoration: const InputDecoration(labelText: 'Category'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                      if (result == true && titleController.text.trim().isNotEmpty && descController.text.trim().isNotEmpty) {
                        await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
                          'title': titleController.text.trim(),
                          'description': descController.text.trim(),
                          'category': selectedCategory,
                        });
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gig updated!')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Gig'),
                          content: const Text('Are you sure you want to delete this gig?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gig deleted!')),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Applicants:', style: TextStyle(fontWeight: FontWeight.bold)),
              FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('applications').where('jobId', isEqualTo: jobId).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No applicants yet.');
                  }
                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data();
                      return ListTile(
                        title: Text('Applicant: ${data['userId'] ?? 'Unknown'}'),
                        subtitle: Text('Status: ${data['status'] ?? '-'}'),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
} 