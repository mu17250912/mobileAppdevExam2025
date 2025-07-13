import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ScheduleSessionScreen extends StatefulWidget {
  const ScheduleSessionScreen({super.key});

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedType;
  String? _selectedPartnerId;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  List<Map<String, dynamic>> _partners = [];

  final List<String> _sessionTypes = [
    'Virtual (Video Call)',
    'In Person',
    'Phone Call',
  ];

  @override
  void initState() {
    super.initState();
    _fetchPartners();
  }

  Future<void> _fetchPartners() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final users = await FirebaseFirestore.instance.collection('users').get();
      final List<Map<String, dynamic>> partners = [];
      for (var doc in users.docs) {
        if (doc.id == user?.uid) continue;
        final data = doc.data();
        partners.add({
          'uid': doc.id,
          'fullName': data['fullName'] ?? 'Unknown',
          'skillsOffered': data['skillsOffered'],
          'skillsToLearn': data['skillsToLearn'],
          'photoUrl': data['photoUrl'],
        });
      }
      setState(() {
        _partners = partners;
        if (_partners.isNotEmpty) {
          _selectedPartnerId ??= _partners.first['uid'];
        }
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to load partners.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedPartnerId == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedType == null) {
      setState(() => _error = 'Please fill all required fields.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final partner = _partners.firstWhere(
          (p) => p['uid'] == _selectedPartnerId,
          orElse: () => <String, dynamic>{});
      final sessionDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final now = DateTime.now();
      await FirebaseFirestore.instance.collection('sessions').add({
        'userA': user?.uid,
        'userB': _selectedPartnerId,
        'participants': [user?.uid, _selectedPartnerId],
        'participantDetails': [
          {'uid': user?.uid, 'role': 'requester'},
          if (partner.isNotEmpty) {'uid': partner['uid'], 'role': 'partner'},
        ],
        'requesterId': user?.uid,
        'partnerId': _selectedPartnerId,
        'title': 'Skill Swap Session',
        'description': _notesController.text.trim(),
        'skillId': '', // Add skill selection if needed
        'skillName': '', // Add skill selection if needed
        'hostId': user?.uid,
        'hostName': user?.displayName ?? '',
        'hostPhotoUrl': null,
        'scheduledAt': sessionDateTime,
        'startedAt': null,
        'endedAt': null,
        'duration': 60, // Default 60 minutes
        'status': 'pending',
        'type': (_selectedType ?? 'oneOnOne').replaceAll(' ', ''),
        'meetingUrl': null,
        'meetingId': null,
        'meetingPassword': null,
        'location': 'TBD',
        'price': null,
        'notes': _notesController.text.trim(),
        'metadata': {},
        'createdAt': now,
        'updatedAt': now,
        'isRecurring': false,
        'recurringPattern': null,
        'recurringDates': null,
      });

      // Send notification to the requested partner
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': _selectedPartnerId,
        'title': 'New Session Request',
        'message':
            '${user?.displayName ?? 'Someone'} has requested a session with you.',
        'type': 'session_request',
        'isRead': false,
        'createdAt': now,
        'senderId': user?.uid,
        'senderName': user?.displayName ?? '',
        'data': {},
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session request sent!')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Failed to send session request.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        centerTitle: true,
        title: const Text(
          'Schedule Session',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Partner Card
                    if (_partners.isNotEmpty)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.blue[100],
                                backgroundImage: _partners.firstWhere((p) =>
                                            p['uid'] ==
                                            _selectedPartnerId)['photoUrl'] !=
                                        null
                                    ? NetworkImage(_partners.firstWhere((p) =>
                                            p['uid'] ==
                                            _selectedPartnerId)['photoUrl'])
                                        as ImageProvider<Object>
                                    : null,
                                child: (_partners.firstWhere((p) =>
                                                    p['uid'] ==
                                                    _selectedPartnerId)[
                                                'photoUrl'] ==
                                            null ||
                                        _partners.firstWhere((p) =>
                                                    p['uid'] ==
                                                    _selectedPartnerId)[
                                                'photoUrl'] ==
                                            '')
                                    ? const Icon(Icons.person,
                                        size: 28, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _partners.firstWhere((p) =>
                                          p['uid'] ==
                                          _selectedPartnerId)['fullName'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Skills: ${(_partners.firstWhere((p) => p['uid'] == _selectedPartnerId)['skillsOffered'] as List).join(', ')}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_partners.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: DropdownButtonFormField<String>(
                          value: _selectedPartnerId,
                          items: _partners
                              .map<DropdownMenuItem<String>>(
                                  (p) => DropdownMenuItem<String>(
                                        value: p['uid'],
                                        child: Text(p['fullName']),
                                      ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedPartnerId = val),
                          decoration: const InputDecoration(
                            labelText: 'Select Partner',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text('Select Date',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('MM/dd/yyyy').format(_selectedDate!)
                              : 'Choose a date',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Time',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Choose a time',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: _sessionTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedType = val),
                      decoration: const InputDecoration(
                        labelText: 'Session type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.video_call),
                      ),
                      validator: (val) =>
                          val == null ? 'Please select a session type' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        hintText: 'Any specific topics you’d like to focus on?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Send Session Request',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
