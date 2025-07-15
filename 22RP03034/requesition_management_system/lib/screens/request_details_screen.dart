import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestDetailsScreen extends StatefulWidget {
  final Request request;
  final int index;
  final String userRole; // 'employee', 'logistics', 'approver'
  const RequestDetailsScreen({super.key, required this.request, required this.index, this.userRole = 'employee'});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  List<Request> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final snapshot = await FirebaseFirestore.instance.collection('requests').get();
    setState(() {
      _requests = snapshot.docs.map((doc) => Request.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  void _deleteRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text('Are you sure you want to delete this request? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (!mounted) return;
    if (confirm == true) {
      try {
        // Delete from Firestore
        await FirebaseFirestore.instance.collection('requests').doc(widget.request.id).delete();
        
        // Add notification
        NotificationStore.add(
          'Request Deleted', 
          'Request "${widget.request.subject}" has been deleted successfully.',
          type: 'request_deleted',
          targetRole: 'Employee',
          targetUser: widget.request.employeeName,
          requestSubject: widget.request.subject,
        );
        
        if (!mounted) return;
        Navigator.pop(context, true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editRequest() async {
    final edited = await Navigator.push<Request>(
      context,
      MaterialPageRoute(
        builder: (context) => EditRequestScreen(
          request: widget.request,
          index: widget.index,
        ),
      ),
    );
    if (!mounted) return;
    if (edited != null) {
      // Refresh the requests list
      await _fetchRequests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the request exists in the list
    if (widget.index >= _requests.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Details')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Request not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('The request may have been deleted or moved.'),
            ],
          ),
        ),
      );
    }
    
    final req = _requests[widget.index];
    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.title),
              title: Text('Subject'),
              subtitle: Text(req.subject),
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_number),
              title: Text('Quantity/Quality'),
              subtitle: Text(req.quantity ?? 'Not specified'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Employee Name'),
              subtitle: Text(req.employeeName),
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: Text('Post Name'),
              subtitle: Text(req.postName ?? 'Not specified'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: Text('Date'),
              subtitle: Text(req.date.toLocal().toString().split(' ')[0]),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text('Status'),
              subtitle: Text(req.status),
            ),
            if (req.logisticsComment?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.comment),
                title: Text('Logistics Comment'),
                subtitle: Text(req.logisticsComment!),
              ),
            if (req.approverComment?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.verified),
                title: Text('Approver Justification'),
                subtitle: Text(req.approverComment!),
              ),
            if (req.history.isNotEmpty) ...[
              const Divider(),
              const Text('Request History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...req.history.map((h) {
                Color color;
                IconData icon;
                switch (h['status'] as String) {
                  case 'Pending': color = Colors.orange; icon = Icons.hourglass_empty; break;
                  case 'For Approval': color = Colors.blue; icon = Icons.forward; break;
                  case 'Approved': color = Colors.green; icon = Icons.check_circle; break;
                  case 'Rejected': color = Colors.red; icon = Icons.cancel; break;
                  case 'Delivered': color = Colors.purple; icon = Icons.local_shipping; break;
                  default: color = Colors.grey; icon = Icons.info;
                }
                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(h['status'] as String, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  subtitle: Text('${h['actor'] as String} • ${DateTime.parse(h['timestamp'] as String).toLocal().toString().split('.')[0]}\n${h['comment'] as String? ?? ''}'),
                );
              }),
            ],
            if (req.status == 'Pending') ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: _editRequest,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: _deleteRequest,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EditRequestScreen extends StatefulWidget {
  final Request request;
  final int index;
  const EditRequestScreen({super.key, required this.request, required this.index});

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  late TextEditingController _subjectController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.request.subject);
    _quantityController = TextEditingController(text: widget.request.quantity);
  }

  void _save() async {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a subject'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final updated = Request(
        id: widget.request.id,
        subject: _subjectController.text.trim(),
        description: widget.request.description,
        employeeName: widget.request.employeeName,
        status: widget.request.status,
        date: widget.request.date,
        quantity: _quantityController.text.trim(),
        postName: widget.request.postName,
        logisticsComment: widget.request.logisticsComment,
        approverComment: widget.request.approverComment,
        availableQuantity: widget.request.availableQuantity,
        employeeConfirmed: widget.request.employeeConfirmed,
        history: widget.request.history,
      );
      
      // Update in Firestore
      await FirebaseFirestore.instance.collection('requests').doc(widget.request.id).update(updated.toMap());
      
      // Add notification
      NotificationStore.add(
        'Request Updated', 
        'Request "${updated.subject}" has been updated successfully.',
        type: 'request_updated',
        targetRole: 'Employee',
        targetUser: updated.employeeName,
        requestSubject: updated.subject,
      );
      
      Navigator.pop(context, updated);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Request'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity/Quality',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 