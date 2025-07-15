import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> job;
  const JobDetailsScreen({Key? key, required this.job}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(job['title'] ?? 'Job Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(job['description'] ?? ''),
            const SizedBox(height: 8),
            Text('Reward: RWF ${job['reward_per_task']}'),
            const SizedBox(height: 8),
            Text('Posted: ${job['postedAt']}'),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final TextEditingController proofController = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Submit Proof'),
                        content: TextField(
                          controller: proofController,
                          decoration: const InputDecoration(
                            labelText: 'Enter proof of completion',
                          ),
                          maxLines: 3,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null || proofController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter proof and make sure you are logged in.')),
                                );
                                return;
                              }
                              // Always use job['id'] for job_id
                              final String jobId = job['id']?.toString() ?? '';
                              print('Submitting proof for job_id: ' + jobId);
                              print('User: ' + (user.email ?? ''));
                              print('Proof: ' + proofController.text.trim());
                              try {
                                await FirebaseFirestore.instance.collection('task_submission').add({
                                  'job_id': jobId,
                                  'user_email': user.email ?? '',
                                  'proof_text': proofController.text.trim(),
                                  'submitted_at': DateTime.now(),
                                  'status': 'pending',
                                });
                                // Add notification for the user
                                await FirebaseFirestore.instance.collection('notifications').add({
                                  'user_email': user.email ?? '',
                                  'message': 'Your proof for "${job['title'] ?? 'a job'}" is under review.',
                                  'created_at': DateTime.now(),
                                  'read': false,
                                });
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Proof submitted and is under review!')),
                                );
                              } catch (e) {
                                print('Error submitting proof: ' + e.toString());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error submitting proof: ' + e.toString())),
                                );
                              }
                            },
                            child: const Text('Submit'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Start Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 