import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeaturedTasksScreen extends StatelessWidget {
  const FeaturedTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A20),
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.greenAccent.shade400, size: 32),
            const SizedBox(width: 10),
            const Text(
              'Tasks',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('View All', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: \\${snapshot.error}', style: TextStyle(color: Colors.white)));
            }
            final tasks = snapshot.data?.docs ?? [];
            if (tasks.isEmpty) {
              return const Center(child: Text('No featured tasks available.', style: TextStyle(color: Colors.white70)));
            }
            return SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final task = tasks[index].data() as Map<String, dynamic>;
                  final title = (task['title'] ?? '').toString().replaceAll('"', '');
                  final reward = task['reward_per_task']?.toString() ?? '';
                  final imageUrl = task['imageUrl'] as String?;
                  return Container(
                    width: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF23263A),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(imageUrl, height: 110, width: 180, fit: BoxFit.cover)
                              : Container(
                                  height: 110,
                                  width: 180,
                                  color: Colors.greenAccent.shade400.withOpacity(0.15),
                                  child: const Icon(Icons.task_alt, size: 48, color: Colors.greenAccent),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Task',
                                style: TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'RWF $reward',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
} 