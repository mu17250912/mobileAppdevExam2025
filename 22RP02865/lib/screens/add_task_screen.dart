import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_storage.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;
  const AddTaskScreen({Key? key, this.task}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  late final TextEditingController _subjectController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _duration;
  late TaskPriority _priority;
  late bool _hasReminder;
  late int _reminderMinutes;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.task?.subject ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');
    _selectedDate = widget.task?.dateTime ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(widget.task?.dateTime ?? DateTime.now());
    _duration = widget.task?.duration ?? 60;
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _hasReminder = widget.task?.hasReminder ?? true;
    _reminderMinutes = widget.task?.reminderMinutes ?? 15;
  }

  void _saveTask() async {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a subject for the task'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // Combine date and time
    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (widget.task != null) {
      // Edit existing task
      widget.task!.subject = _subjectController.text.trim();
      widget.task!.notes = _notesController.text.trim();
      widget.task!.dateTime = combinedDateTime;
      widget.task!.duration = _duration;
      widget.task!.priority = _priority;
      widget.task!.hasReminder = _hasReminder;
      widget.task!.reminderMinutes = _reminderMinutes;
      await taskProvider.updateTask(widget.task!);
    } else {
      // Add new task
      final newTask = Task(
        subject: _subjectController.text.trim(),
        notes: _notesController.text.trim(),
        dateTime: combinedDateTime,
        duration: _duration,
        priority: _priority,
        hasReminder: _hasReminder,
        reminderMinutes: _reminderMinutes,
      );
      await taskProvider.addTask(newTask);
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(widget.task != null ? 'Edit Task' : 'Add Task'),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Field
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.book, color: Colors.blue[800]),
                    labelText: 'Subject *',
                    hintText: 'Enter task subject',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Notes Field
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.notes, color: Colors.blue[800]),
                    labelText: 'Notes',
                    hintText: 'Add additional notes (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Date and Time Section
                Text(
                  'Date & Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.calendar_today, color: Colors.blue[800]),
                        label: Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.blue[800]!),
                        ),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _selectedDate = date);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.access_time, color: Colors.blue[800]),
                        label: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.blue[800]!),
                        ),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (time != null) setState(() => _selectedTime = time);
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Duration and Priority Section
                Text(
                  'Duration & Priority',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _duration,
                        decoration: InputDecoration(
                          labelText: 'Duration',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        items: [15, 30, 45, 60, 90, 120, 180].map((value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value min'),
                        )).toList(),
                        onChanged: (value) => setState(() => _duration = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TaskPriority>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        items: TaskPriority.values.map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: priority.priorityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(priority.priorityText),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _priority = value!),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Reminder Section
                Text(
                  'Reminder Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 12),
                
                SwitchListTile(
                  title: Text('Enable Reminder'),
                  subtitle: Text('Get notified before the task'),
                  value: _hasReminder,
                  onChanged: (value) => setState(() => _hasReminder = value),
                  activeColor: Colors.blue[800],
                ),
                
                if (_hasReminder) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _reminderMinutes,
                    decoration: InputDecoration(
                      labelText: 'Reminder Time',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: [5, 10, 15, 30, 60].map((value) => DropdownMenuItem(
                      value: value,
                      child: Text('$value minutes before'),
                    )).toList(),
                    onChanged: (value) => setState(() => _reminderMinutes = value!),
                  ),
                ],
                
                const SizedBox(height: 28),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saveTask,
                    child: Text(
                      widget.task != null ? 'Update Task' : 'Create Task',
                      style: const TextStyle(fontSize: 18),
                    ),
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