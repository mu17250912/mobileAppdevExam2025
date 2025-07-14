import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'jobseeker_dashboard.dart';

class JobseekerApplicationsPage extends StatelessWidget {
  const JobseekerApplicationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Applications')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('jobseeker_id', isEqualTo: user.uid)
            .orderBy(FieldPath.documentId, descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load applications', style: TextStyle(color: Colors.red)),
            );
          }

          final applications = snapshot.data?.docs ?? [];

          if (applications.isEmpty) {
            return const Center(child: Text('No applications yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final app = applications[i].data() as Map<String, dynamic>;
              final docId = applications[i].id;
              final appliedAt = app['applied_at'] != null && app['applied_at'] is Timestamp
                  ? (app['applied_at'] as Timestamp).toDate()
                  : null;
              final status = app['status'] ?? 'Pending';
              Color statusColor;
              switch (status.toLowerCase()) {
                case 'accepted':
                  statusColor = Colors.green;
                  break;
                case 'rejected':
                  statusColor = Colors.red;
                  break;
                case 'under review':
                  statusColor = Colors.orange;
                  break;
                default:
                  statusColor = Colors.blue;
              }
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app['job_title'] ?? 'Unknown Job',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  app['company_name'] ?? 'Unknown Company',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            tooltip: 'Edit',
                            onPressed: () {
                              _showEditApplicationDialog(context, docId, app);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Application'),
                                  content: const Text('Are you sure you want to delete this application?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await FirebaseFirestore.instance.collection('applications').doc(docId).delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Application deleted.')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (appliedAt != null)
                        Text(
                          'Applied on ${appliedAt.day}/${appliedAt.month}/${appliedAt.year}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      if (app['cover_letter'] != null && app['cover_letter'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Cover Letter: ${app['cover_letter']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                      if (app['expected_salary'] != null && app['expected_salary'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Expected Salary: ${app['expected_salary']}',
                          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (app['additional_notes'] != null && app['additional_notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Notes: ${app['additional_notes']}',
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ],
                      if (app['preferred_start_date'] != null && app['preferred_start_date'] is Timestamp) ...[
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final startDate = (app['preferred_start_date'] as Timestamp).toDate();
                            return Text(
                              'Preferred Start: ${startDate.day}/${startDate.month}/${startDate.year}',
                              style: const TextStyle(fontSize: 12, color: Colors.deepPurple),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: JobseekerBottomNavBar(currentIndex: 3, context: context),
    );
  }
}

void _showEditApplicationDialog(BuildContext context, String docId, Map<String, dynamic> app) {
  final coverLetterController = TextEditingController(text: app['cover_letter'] ?? '');
  final expectedSalaryController = TextEditingController(text: app['expected_salary'] ?? '');
  final additionalNotesController = TextEditingController(text: app['additional_notes'] ?? '');
  DateTime? preferredStartDate = app['preferred_start_date'] is Timestamp
      ? (app['preferred_start_date'] as Timestamp).toDate()
      : null;
  final _formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) {
      return FutureBuilder<DocumentSnapshot>(
        future: app['job_id'] != null
            ? FirebaseFirestore.instance.collection('job_posts').doc(app['job_id']).get()
            : Future.value(null),
        builder: (context, snapshot) {
          String companyName = app['company_name'] ?? '';
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.data() != null) {
            final jobData = snapshot.data!.data() as Map<String, dynamic>;
            companyName = jobData['company_name'] ?? companyName;
          }
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Edit Application'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          initialValue: companyName,
                          decoration: const InputDecoration(
                            labelText: 'Company Name',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: coverLetterController,
                          decoration: const InputDecoration(
                            labelText: 'Cover Letter',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: preferredStartDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            );
                            if (picked != null) setState(() => preferredStartDate = picked);
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Preferred Start Date',
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              controller: TextEditingController(
                                text: preferredStartDate != null ? '${preferredStartDate!.year}-${preferredStartDate!.month.toString().padLeft(2, '0')}-${preferredStartDate!.day.toString().padLeft(2, '0')}' : '',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: expectedSalaryController,
                          decoration: const InputDecoration(
                            labelText: 'Expected Salary',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: additionalNotesController,
                          decoration: const InputDecoration(
                            labelText: 'Additional Notes',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      String? employerId;
                      if (app['job_id'] != null) {
                        final jobDoc = await FirebaseFirestore.instance.collection('job_posts').doc(app['job_id']).get();
                        if (jobDoc.exists) {
                          final jobData = jobDoc.data() as Map<String, dynamic>;
                          employerId = jobData['employer_id'];
                        }
                      }
                      await FirebaseFirestore.instance.collection('applications').doc(docId).update({
                        'cover_letter': coverLetterController.text.trim(),
                        'expected_salary': expectedSalaryController.text.trim(),
                        'additional_notes': additionalNotesController.text.trim(),
                        'preferred_start_date': preferredStartDate != null ? Timestamp.fromDate(preferredStartDate!) : null,
                        'company_name': companyName,
                        if (employerId != null) 'employer_id': employerId,
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Application updated!')),
                      );
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}
