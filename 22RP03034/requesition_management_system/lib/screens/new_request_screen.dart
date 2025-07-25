import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request_model.dart';

class NewRequestScreen extends StatefulWidget {
  final Request? request;
  
  const NewRequestScreen({super.key, this.request});

  @override
  State<NewRequestScreen> createState() => NewRequestScreenState();
}

class NewRequestScreenState extends State<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _postNameController = TextEditingController();
  
  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';
  String _postName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (widget.request != null) {
      _loadRequestData();
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _postNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _userName = userData['name'] ?? '';
            _userEmail = userData['email'] ?? '';
            _postName = userData['postName'] ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  void _loadRequestData() {
    final request = widget.request!;
    _subjectController.text = request.subject;
    _descriptionController.text = request.description;
    _quantityController.text = request.quantity ?? '';
    _postNameController.text = request.postName ?? '';
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Removed daily request limit check
      final requestData = {
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'employeeName': _userName,
        'employeeEmail': _userEmail,
        'status': 'Pending',
        'date': DateTime.now(),
        'quantity': _quantityController.text.trim().isEmpty ? null : _quantityController.text.trim(),
        'postName': _postName.isEmpty ? null : _postName,
        'history': [
          {
            'status': 'Pending',
            'actor': _userName,
            'comment': 'Request submitted',
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
      };

      if (widget.request != null) {
        // Update existing request
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.request!.id)
            .update(requestData);
      } else {
        // Create new request
        final docRef = await FirebaseFirestore.instance
            .collection('requests')
            .add(requestData);
        
        // Send notification to logistics about new request
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New Request Submitted',
          'body': 'Employee $_userName has submitted a new request: "${_subjectController.text.trim()}"',
          'type': 'new_request',
          'targetRole': 'Logistics',
          'requestSubject': _subjectController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'requestId': docRef.id,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.request != null ? 'Request updated successfully' : 'Request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
      );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.request != null ? 'Edit Request' : 'New Request'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
              ),
                    const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
              ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.request != null ? 'Update Request' : 'Submit Request',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 