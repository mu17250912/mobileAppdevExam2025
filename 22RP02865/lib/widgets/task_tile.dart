import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/task_storage.dart';
import '../screens/add_task_screen.dart';
import '../screens/task_completion_screen.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback? onChanged;

  const TaskTile({Key? key, required this.task, this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskStorage = TaskStorage();
    final dateFormat = DateFormat('MMM d, y - h:mm a');

    return Dismissible(
      key: Key(task.id ?? task.hashCode.toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        await taskProvider.deleteTask(task);
        if (onChanged != null) onChanged!();
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Main task info
              Row(
                children: [
                  // Checkbox for quick completion
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: task.isCompleted,
                      activeColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (bool? value) async {
                        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                        task.isCompleted = value ?? false;
                        await taskProvider.updateTask(task);
                        if (onChanged != null) onChanged!();
                      },
                    ),
                  ),
                  
                  // Task details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.subject,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted ? Colors.grey : Colors.black,
                          ),
                        ),
                        if (task.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.notes,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.blue[800]),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(task.dateTime),
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.timer, size: 16, color: Colors.orange[800]),
                            const SizedBox(width: 4),
                            Text(
                              '${task.duration} min',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: task.priority.priorityColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task.priority.priorityText,
                                style: TextStyle(
                                  color: task.priority.priorityColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Column(
                    children: [
                      // Edit button
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue[800], size: 20),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTaskScreen(task: task),
                            ),
                          );
                          if (onChanged != null) onChanged!();
                        },
                        tooltip: 'Edit Task',
                      ),
                      
                      // Complete task button (only show if not completed)
                      if (!task.isCompleted)
                        IconButton(
                          icon: Icon(Icons.play_circle, color: Colors.green[600], size: 20),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskCompletionScreen(task: task),
                              ),
                            );
                            if (result == true && onChanged != null) {
                              onChanged!();
                            }
                          },
                          tooltip: 'Complete Task',
                        ),
                    ],
                  ),
                ],
              ),
              
              // Completion status and progress (if not completed)
              if (!task.isCompleted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap the play button to start completing this task',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Completion badge (if completed)
              if (task.isCompleted) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
