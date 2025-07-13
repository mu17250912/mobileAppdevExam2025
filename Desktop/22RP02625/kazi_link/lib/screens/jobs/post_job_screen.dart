import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostJobScreen extends StatefulWidget {
  final Function(Map<String, String>) onJobPosted;
  const PostJobScreen({super.key, required this.onJobPosted});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  String category = '';
  String location = '';
  String budget = '';
  bool _isPosting = false;

  @override
  Widget build(BuildContext context) {
    final isPremium = Provider.of<UserProvider>(context, listen: false).isPremium;
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Job Title', prefixIcon: Icon(Icons.title)),
                  onSaved: (val) => title = val ?? '',
                  validator: (val) => val == null || val.isEmpty ? 'Enter job title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
                  maxLines: 3,
                  onSaved: (val) => description = val ?? '',
                  validator: (val) => val == null || val.isEmpty ? 'Enter job description' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
                  onSaved: (val) => category = val ?? '',
                  validator: (val) => val == null || val.isEmpty ? 'Enter category' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
                  onSaved: (val) => location = val ?? '',
                  validator: (val) => val == null || val.isEmpty ? 'Enter location' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Budget', prefixIcon: Icon(Icons.attach_money)),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => budget = val ?? '',
                  validator: (val) => val == null || val.isEmpty ? 'Enter budget' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPosting
                        ? null
                        : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              _formKey.currentState?.save();
                              final jobData = {
                                'title': title,
                                'description': description,
                                'category': category,
                                'location': location,
                                'budget': budget,
                                'poster': 'You', // Replace with userId if available
                                'premium': isPremium,
                                'createdAt': FieldValue.serverTimestamp(),
                              };
                              setState(() => _isPosting = true);
                              try {
                                await FirebaseFirestore.instance.collection('jobs').add(jobData);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Job posted successfully!')),
                                  );
                                }
                                Provider.of<NotificationProvider>(context, listen: false).addNotification(
                                  NotificationItem(
                                    id: '',
                                    icon: Icons.work,
                                    title: 'Job Posted',
                                    message: 'Your job "$title" has been posted!',
                                    time: 'Just now',
                                  ),
                                );
                                await NotificationProvider.notifyAllWorkers(
                                  NotificationItem(
                                    id: '',
                                    icon: Icons.work,
                                    title: 'New Job Posted',
                                    message: 'A new job "$title" is available. Check it out!',
                                    time: 'Just now',
                                  ),
                                );
                                // Show dialog to ask what to do next
                                if (mounted) {
                                  final action = await showDialog<String>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Job Posted!'),
                                      content: const Text('What would you like to do next?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, 'another'),
                                          child: const Text('Post Another'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, 'jobs'),
                                          child: const Text('Go to Job List'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (action == 'another') {
                                    _formKey.currentState?.reset();
                                    setState(() {
                                      title = '';
                                      description = '';
                                      category = '';
                                      location = '';
                                      budget = '';
                                    });
                                  } else if (action == 'jobs') {
                                    Navigator.pushNamedAndRemoveUntil(context, '/jobs', (route) => false);
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to post job: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isPosting = false);
                              }
                            }
                          },
                    child: _isPosting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Post Job'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 