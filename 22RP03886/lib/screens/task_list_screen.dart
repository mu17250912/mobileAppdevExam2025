import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'package:intl/intl.dart';

class TaskListScreen extends StatelessWidget {
  Color _chipColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.blueAccent;
      case 'personal':
        return Colors.orangeAccent;
      case 'urgent':
        return Colors.redAccent;
      case 'shopping':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F2F7),
      appBar: AppBar(
        title: Text('Task Task', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          final tasks = taskProvider.tasks;
          if (tasks.isEmpty) {
            return Center(child: Text('No tasks yet.'));
          }
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.07),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: Text(
                    task.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Row(
                    children: [
                      ..._buildChips(task),
                    ],
                  ),
                  trailing: Text(
                    _formatTime(task.time),
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  onTap: () {}, // Quick view, can add edit if needed
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildChips(Task task) {
    // You can customize this to show multiple chips if needed
    return [
      Container(
        margin: EdgeInsets.only(top: 6, right: 6),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _chipColor(task.category).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          task.category,
          style: TextStyle(
            color: _chipColor(task.category),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
      // Add more chips here if you want (e.g., status, priority)
    ];
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }
} 