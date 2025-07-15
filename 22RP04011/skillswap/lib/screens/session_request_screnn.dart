import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionRequestScreen extends StatefulWidget {
  final String skillId;
  final String skillName;
  final String receiverId;
  final String receiverName;

  const SessionRequestScreen({
    super.key,
    required this.skillId,
    required this.skillName,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<SessionRequestScreen> createState() => _SessionRequestScreenState();
}

class _SessionRequestScreenState extends State<SessionRequestScreen> {
  final TextEditingController _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request ${widget.skillName} Session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request a session with ${widget.receiverName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Tell them why you want to learn this skill...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : 'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectTime(context),
                      child: Text(
                        _selectedTime == null
                            ? 'Select Time'
                            : 'Time: ${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _sendRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Send Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser!;
    final firestore = FirebaseFirestore.instance;

    try {
      // Create session request
      final sessionDoc = await firestore.collection('sessions').add({
        'skillId': widget.skillId,
        'skillName': widget.skillName,
        'teacherId': widget.receiverId,
        'studentId': currentUser.uid,
        'message': _messageController.text,
        'proposedDate': Timestamp.fromDate(DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        )),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create notification for the receiver
      await firestore.collection('notifications').add({
        'userId': widget.receiverId,
        'title': 'New Session Request',
        'body':
            '${currentUser.displayName} wants to learn ${widget.skillName} from you',
        'type': 'session_request',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'relatedSessionId': sessionDoc.id,
      });

      // Send a message to start the conversation
      await firestore.collection('messages').add({
        'senderId': currentUser.uid,
        'receiverId': widget.receiverId,
        'content':
            'Hi! I requested a session to learn ${widget.skillName} from you. ${_messageController.text}',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'relatedSessionId': sessionDoc.id,
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session request sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending request: $e')),
      );
    }
  }
}
