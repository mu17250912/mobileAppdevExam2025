import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManagerReportsViewer extends StatelessWidget {
  const ManagerReportsViewer({Key? key}) : super(key: key);

  Stream<QuerySnapshot<Map<String, dynamic>>> _reportsStream() async* {
    final managerId = FirebaseAuth.instance.currentUser?.uid;
    // Get all tasks for this manager
    final tasksSnap = await FirebaseFirestore.instance.collection('tasks').where('managerId', isEqualTo: managerId).get();
    final taskIds = tasksSnap.docs.map((doc) => doc.id).toList();
    if (taskIds.isEmpty) {
      // Return an empty stream
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance.collection('reports').where('taskId', whereIn: taskIds).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Viewer'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _reportsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No reports found.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final report = docs[i].data();
              return ListTile(
                leading: Icon(Icons.report, color: Colors.deepPurple),
                title: Text('Task: \\${report['taskTitle'] ?? report['taskId']}'),
                subtitle: Text('Employee: \\${report['employeeName'] ?? report['employeeId']}\nSubmitted: \\${report['submittedAt'] != null ? (report['submittedAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : 'N/A'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.deepPurple),
                      tooltip: 'View Report',
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => _ReportDialog(
                            report: report,
                            reportId: docs[i].id,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Report',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Report'),
                            content: const Text('Are you sure you want to delete this report?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance.collection('reports').doc(docs[i].id).delete();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted.')));
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Text((report['status'] ?? 'pending').toString()),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  final String reportId;
  const _ReportDialog({required this.report, required this.reportId});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  bool _loading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.report['status'] ?? 'pending';
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _loading = true);
    await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({'status': newStatus});
    // Send notification to employee
    final employeeId = widget.report['employeeId'];
    String notifTitle = newStatus == 'approved' ? 'Report Approved' : 'Report Rejected';
    String notifMsg = newStatus == 'approved'
      ? 'Your report for task "${widget.report['taskTitle']}" was approved.'
      : 'Your report for task "${widget.report['taskTitle']}" was rejected.';
    await FirebaseFirestore.instance.collection('notifications').add({
      'employeeId': employeeId,
      'type': newStatus == 'approved' ? 'report_approved' : 'report_rejected',
      'title': notifTitle,
      'message': notifMsg,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'closable': true,
    });
    setState(() {
      _status = newStatus;
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report marked as $newStatus.')));
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return AlertDialog(
      title: Text('Report for Task: \\${report['taskTitle'] ?? report['taskId']}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: \\${report['employeeName'] ?? report['employeeId']}'),
            const SizedBox(height: 8),
            Text('Submitted: \\${report['submittedAt'] != null ? (report['submittedAt'] as Timestamp).toDate().toLocal().toString() : 'N/A'}'),
            const SizedBox(height: 16),
            const Text('Report Content:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(report['report'] ?? 'No content'),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_status ?? 'pending', style: TextStyle(color: _status == 'approved' ? Colors.green : _status == 'rejected' ? Colors.red : Colors.orange)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (!_loading && _status != 'approved')
          TextButton(
            onPressed: () => _updateStatus('approved'),
            child: const Text('Approve', style: TextStyle(color: Colors.green)),
          ),
        if (!_loading && _status != 'rejected')
          TextButton(
            onPressed: () => _updateStatus('rejected'),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
} 