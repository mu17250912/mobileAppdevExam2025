import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../settings/upgrade_screen.dart';
import '../app/analytics_service.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  String _frequencyType = 'Daily';
  final _everyXHoursController = TextEditingController();
  final _weeklyDayController = TextEditingController();
  DateTime? _startDateTime;
  bool _loading = false;
  String? _error;
  int _activeMedCount = 0;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadUserMedCount();
  }

  Future<void> _loadUserMedCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    _isPremium = userDoc.data()?['isPremium'] ?? false;
    final meds = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('medications').where('isActive', isEqualTo: true).get();
    setState(() {
      _activeMedCount = meds.docs.length;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _startDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_isPremium && _activeMedCount >= 3) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upgrade to Premium'),
          content: const Text('Free users can only have 3 active medications. Upgrade to Premium for unlimited medications.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                );
              },
              child: const Text('Upgrade Now'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String frequency = _frequencyType;
      if (_frequencyType == 'Every X hours') {
        frequency = 'Every ${_everyXHoursController.text.trim()} hours';
      } else if (_frequencyType == 'Weekly') {
        frequency = 'Weekly on ${_weeklyDayController.text.trim()}';
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('medications').add({
        'name': _nameController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'frequency': frequency,
        'startTime': _startDateTime?.toIso8601String(),
        'notes': _notesController.text.trim(),
        'nextDose': '',
        'isActive': true,
        'lastTaken': null,
      });
      await AnalyticsService.logMedicationAdded(_nameController.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medication')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Medication Name'),
                  validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dosageController,
                  decoration: const InputDecoration(labelText: 'Dosage'),
                  validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _frequencyType,
                  items: const [
                    DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'Every X hours', child: Text('Every X hours')),
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                  ],
                  onChanged: (val) => setState(() => _frequencyType = val ?? 'Daily'),
                  decoration: const InputDecoration(labelText: 'Frequency'),
                ),
                if (_frequencyType == 'Every X hours') ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _everyXHoursController,
                    decoration: const InputDecoration(labelText: 'Every how many hours?'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                  ),
                ],
                if (_frequencyType == 'Weekly') ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _weeklyDayController,
                    decoration: const InputDecoration(labelText: 'Day of the week (e.g. Monday)'),
                    validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(_startDateTime == null
                          ? 'Start Date & Time: Not set'
                          : 'Start: ${DateFormat('yMMMd – h:mm a').format(_startDateTime!)}'),
                    ),
                    TextButton(
                      onPressed: _pickDateTime,
                      child: const Text('Pick'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) _submit();
                        },
                        child: const Text('Add Medication'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 