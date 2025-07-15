import 'package:flutter/material.dart';
import '../models/job.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AddJobScreen extends StatefulWidget {
  const AddJobScreen({Key? key}) : super(key: key);

  @override
  _AddJobScreenState createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String company = '';
  String location = '';
  String description = '';
  String requirements = '';
  String salary = '';
  String jobType = 'Full-time';
  String experienceLevel = 'Entry';
  String? deadline;
  bool isLoading = false;

  Future<void> _pickDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        deadline = picked.toIso8601String();
      });
    }
  }

  Future<bool> _simulatePayment(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Required'),
        content: Text('Pay 10,000 RWF to post this job. (Simulated)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Pay & Post'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Job')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Enter job title' : null,
                onChanged: (value) => title = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Company'),
                validator: (value) => value!.isEmpty ? 'Enter company' : null,
                onChanged: (value) => company = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) => value!.isEmpty ? 'Enter location' : null,
                onChanged: (value) => location = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Enter description' : null,
                onChanged: (value) => description = value,
                maxLines: 2,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Requirements (comma separated)'),
                validator: (value) => value!.isEmpty ? 'Enter requirements' : null,
                onChanged: (value) => requirements = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Salary'),
                validator: (value) => value!.isEmpty ? 'Enter salary' : null,
                onChanged: (value) => salary = value,
              ),
              DropdownButtonFormField<String>(
                value: jobType,
                decoration: const InputDecoration(labelText: 'Job Type'),
                items: ['Full-time', 'Part-time', 'Contract']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => jobType = value!),
              ),
              DropdownButtonFormField<String>(
                value: experienceLevel,
                decoration: const InputDecoration(labelText: 'Experience Level'),
                items: ['Entry', 'Mid', 'Senior']
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (value) => setState(() => experienceLevel = value!),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(deadline == null
                        ? 'No deadline chosen'
                        : 'Deadline: ${DateTime.parse(deadline!).toLocal().toString().split(' ')[0]}'),
                  ),
                  TextButton(
                    onPressed: () => _pickDeadline(context),
                    child: const Text('Pick Deadline'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: Icon(Icons.payment),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (deadline == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please pick a deadline.'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          final paid = await _simulatePayment(context);
                          if (!paid) return;
                          setState(() { isLoading = true; });
                          final jobData = {
                            'title': title,
                            'company': company,
                            'location': location,
                            'description': description,
                            'requirements': requirements.split(',').map((e) => e.trim()).toList(),
                            'salary': salary,
                            'jobType': jobType,
                            'experienceLevel': experienceLevel,
                            'deadline': deadline!,
                            'applicants': [],
                            'paid': true,
                          };
                          try {
                            await FirebaseFirestore.instance.collection('jobs').add(jobData);
                            await FirebaseAnalytics.instance.logEvent(
                              name: 'job_posted',
                              parameters: {'title': title, 'company': company},
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Job posted successfully!'), backgroundColor: Colors.green),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to post job: $e'), backgroundColor: Colors.red),
                            );
                          } finally {
                            setState(() { isLoading = false; });
                          }
                        }
                      },
                      label: Text('Pay & Post Job'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 