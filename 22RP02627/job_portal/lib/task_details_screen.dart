import 'package:flutter/material.dart';

class TaskDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> task;
  const TaskDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(task['title'] ?? 'Task Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(task['description'] ?? ''),
            const SizedBox(height: 8),
            Text('Location: ${task['location']}'),
            const SizedBox(height: 8),
            Text('Reward: RWF ${task['reward_per_task']}'),
            const SizedBox(height: 8),
            Text('Posted: ${task['postedAt']}'),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Application submitted!')),
                  );
                },
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 