import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manager_create_edit_task.dart';

class ManagerTaskList extends StatefulWidget {
  const ManagerTaskList({Key? key}) : super(key: key);

  @override
  State<ManagerTaskList> createState() => _ManagerTaskListState();
}

class _ManagerTaskListState extends State<ManagerTaskList> {
  Future<QuerySnapshot<Map<String, dynamic>>> _fetchTasks() async {
    final managerId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance.collection('tasks').where('managerId', isEqualTo: managerId).get();
  }

  Future<void> _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted.')));
    setState(() {}); // Refresh the list
  }

  void _editTask(BuildContext context, String taskId, Map<String, dynamic> taskData) {
    // For now, just show a snackbar. You can implement edit navigation here.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManagerCreateEditTask(/* pass taskId and taskData for editing if implemented */),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: _fetchTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No tasks found.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final task = doc.data();
              return ListTile(
                leading: Icon(Icons.assignment, color: Colors.deepPurple),
                title: Text(task['title'] ?? ''),
                subtitle: Text('Deadline: ${task['deadline'] != null ? (task['deadline'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : 'N/A'}\nPriority: ${task['priority']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      tooltip: 'Edit',
                      onPressed: () => _editTask(context, doc.id, task),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: const Text('Are you sure you want to delete this task?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _deleteTask(doc.id);
                        }
                      },
                    ),
                  ],
                ),
                onTap: () {}, // For future detail view
              );
            },
          );
        },
      ),
    );
  }
} 