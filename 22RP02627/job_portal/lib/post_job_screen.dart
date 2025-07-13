import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({Key? key}) : super(key: key);

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController();
  final TextEditingController _peopleController = TextEditingController();

  int get totalToPay {
    final reward = int.tryParse(_rewardController.text) ?? 0;
    final people = int.tryParse(_peopleController.text) ?? 0;
    return reward * people;
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('To activate your task, please pay:'),
            const SizedBox(height: 8),
            Text(
              '${totalToPay} RWF',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text('Send to:'),
            Row(
              children: [
                SelectableText('+250790184899', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy number',
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: '+250790184899'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phone number copied!')),
                    );
                  },
                ),
              ],
            ),
            const Text('Name: NIYOGISUBIZO Wilson'),
            const SizedBox(height: 16),
            const Text('After payment, your task will be reviewed by the admin and activated once payment is confirmed. Please wait for approval.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onCreateTask() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create a task.')),
      );
      return;
    }
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _rewardController.text.isEmpty ||
        _peopleController.text.isEmpty ||
        totalToPay <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields with valid values')),
      );
      return;
    }
    // Save to Firestore
    await FirebaseFirestore.instance.collection('tasks').add({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'reward_per_task': int.tryParse(_rewardController.text.trim()) ?? 0,
      'total_slots': int.tryParse(_peopleController.text.trim()) ?? 1,
      'slots_filled': 0,
      'postedAt': DateTime.now(),
      'is_active': false,
      'creator_id': user.email ?? '',
    });
    _showPaymentDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (what needs to be done)'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rewardController,
              decoration: const InputDecoration(labelText: 'Reward per click (RWF)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _peopleController,
              decoration: const InputDecoration(labelText: 'Number of people'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Text(
              'Total to pay: $totalToPay RWF',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _onCreateTask,
              child: const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }
} 