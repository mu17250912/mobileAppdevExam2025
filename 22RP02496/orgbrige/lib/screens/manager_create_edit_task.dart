import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManagerCreateEditTask extends StatefulWidget {
  const ManagerCreateEditTask({Key? key}) : super(key: key);

  @override
  State<ManagerCreateEditTask> createState() => _ManagerCreateEditTaskState();
}

class _ManagerCreateEditTaskState extends State<ManagerCreateEditTask> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _deadline;
  String _priority = 'Normal';
  String? _assignedEmployeeId;
  bool _isLoading = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _employees = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    final managerId = FirebaseAuth.instance.currentUser?.uid;
    final snap = await FirebaseFirestore.instance.collection('employees').where('managerId', isEqualTo: managerId).get();
    setState(() { _employees = snap.docs; });
  }

  Future<void> _addTask() async {
    if (!_formKey.currentState!.validate() || _assignedEmployeeId == null || _deadline == null) return;
    setState(() { _isLoading = true; });
    try {
      final managerId = FirebaseAuth.instance.currentUser?.uid;
      if (managerId == null) throw Exception('Manager not logged in');
      final taskRef = await FirebaseFirestore.instance.collection('tasks').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'deadline': _deadline,
        'priority': _priority,
        'employeeId': _assignedEmployeeId,
        'managerId': managerId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Create notification for employee
      await FirebaseFirestore.instance.collection('notifications').add({
        'employeeId': _assignedEmployeeId,
        'type': 'task_assigned',
        'title': 'New Task Assigned',
        'message': 'You have been assigned a new task: ${_titleController.text.trim()}',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'closable': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create task: $e')),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Task'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_deadline == null ? 'Select Deadline' : 'Deadline: ${_deadline!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() { _deadline = picked; });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                items: const [
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                ],
                onChanged: (value) {
                  setState(() { _priority = value!; });
                },
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _assignedEmployeeId,
                items: _employees.map((e) => DropdownMenuItem(
                  value: e.id,
                  child: Text(e['name'] ?? ''),
                )).toList(),
                onChanged: (value) {
                  setState(() { _assignedEmployeeId = value; });
                },
                decoration: const InputDecoration(labelText: 'Assign to Employee'),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create Task', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 