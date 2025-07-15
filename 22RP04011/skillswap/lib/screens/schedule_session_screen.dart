import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/screen_wrapper.dart';

class ScheduleSessionScreen extends StatelessWidget {
  const ScheduleSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Schedule Session'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: const _ScheduleSessionScreenBody(),
      // Bottom navigation is handled by ScreenWrapper or main scaffold
    );
  }
}

class _ScheduleSessionScreenBody extends StatefulWidget {
  const _ScheduleSessionScreenBody();

  @override
  State<_ScheduleSessionScreenBody> createState() =>
      _ScheduleSessionScreenBodyState();
}

class _ScheduleSessionScreenBodyState
    extends State<_ScheduleSessionScreenBody> {
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
          'skillsOffered': data['skillsOffered'] ?? [],
          'skillsToLearn': data['skillsToLearn'] ?? [],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load partners: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      );
      if (picked != null) {
        setState(() => _selectedDate = picked);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to pick date: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickTime() async {
    try {
      final picked = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
      );
      if (picked != null) {
        setState(() => _selectedTime = picked);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to pick time: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedPartnerId == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedType == null) {
      setState(() => _error = 'Please fill all required fields.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields.'),
            backgroundColor: Colors.red),
      );
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
        'skillId': '',
        'skillName': '',
        'hostId': user?.uid,
        'hostName': user?.displayName ?? '',
        'hostPhotoUrl': null,
        'scheduledAt': sessionDateTime,
        'startedAt': null,
        'endedAt': null,
        'duration': 60,
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
        const SnackBar(
            content: Text('Session request sent!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Failed to send session request.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to send session request: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = _partners.firstWhere(
      (p) => p['uid'] == _selectedPartnerId,
      orElse: () => <String, dynamic>{},
    );
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (partner != null)
                      Card(
                        color: Colors.blue[50],
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: partner['photoUrl'] != null &&
                                  (partner['photoUrl'] as String).isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(partner['photoUrl']))
                              : const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(partner['fullName'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              (partner['skillsOffered'] as List).join(', ')),
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      value: _selectedPartnerId,
                      decoration: const InputDecoration(
                        labelText: 'Select Partner',
                        border: OutlineInputBorder(),
                      ),
                      items: _partners
                          .map<DropdownMenuItem<String>>(
                              (p) => DropdownMenuItem<String>(
                                    value: p['uid'] as String,
                                    child: Text(p['fullName']),
                                  ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPartnerId = v),
                      validator: (v) =>
                          v == null ? 'Please select a partner' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Select Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(_selectedDate == null
                                  ? 'Select Date'
                                  : DateFormat('MM/dd/yyyy')
                                      .format(_selectedDate!)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Select Time',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(_selectedTime == null
                                  ? 'Select Time'
                                  : _selectedTime!.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Session type',
                        border: OutlineInputBorder(),
                      ),
                      items: _sessionTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedType = v),
                      validator: (v) =>
                          v == null ? 'Please select session type' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        border: OutlineInputBorder(),
                        hintText: 'Any specific topics you’d like to focus on?',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Send Session Request'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
