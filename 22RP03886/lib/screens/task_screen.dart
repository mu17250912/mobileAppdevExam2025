import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  void _showTaskForm({Task? task, int? index}) {
    final isEditing = task != null;
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    DateTime? selectedDate = task?.date;
    TimeOfDay? selectedTime = task?.time;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isEditing ? 'Edit Task' : 'Add Task', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setModalState(() => selectedDate = picked);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                selectedDate == null
                                    ? 'Date'
                                    : DateFormat('MMM d, yyyy').format(selectedDate!),
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) setModalState(() => selectedTime = picked);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                selectedTime == null
                                    ? 'Time'
                                    : selectedTime!.format(context),
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please enter a task title'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          if (selectedDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please select a date'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          if (selectedTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please select a time'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          final newTask = Task(
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            category: 'General',
                            date: selectedDate!,
                            time: selectedTime!,
                            isCompleted: false,
                            reminder: false,
                          );
                          final provider = Provider.of<TaskProvider>(context, listen: false);
                          if (isEditing && index != null) {
                            // Preserve docId for update
                            final updatedTask = newTask.copyWith(docId: task!.docId);
                            await provider.updateTask(updatedTask);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Task updated!'), backgroundColor: Colors.green),
                            );
                          } else {
                            await provider.addTask(newTask);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Task added!'), backgroundColor: Colors.green),
                            );
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3975F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(isEditing ? 'Update Task' : 'Save Task'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
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
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(task.time),
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showTaskForm(task: task, index: index),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Task'),
                              content: Text('Are you sure you want to delete this task?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await Provider.of<TaskProvider>(context, listen: false).deleteTask(task);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Task deleted!'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskForm(),
        backgroundColor: Color(0xFF3975F6),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Task',
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          // You can add navigation logic here if needed
        },
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: Color(0xFF3975F6),
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
} 