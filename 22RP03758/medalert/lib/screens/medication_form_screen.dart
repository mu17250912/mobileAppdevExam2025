import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class MedicationFormScreen extends StatefulWidget {
  final String? medicationId;
  final Map<String, dynamic>? medication;

  const MedicationFormScreen({
    super.key,
    this.medicationId,
    this.medication,
  });

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedFrequency = 'Once daily';
  List<TimeOfDay> _selectedTimes = [TimeOfDay.now()];
  bool _loading = false;

  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every 6 hours',
    'Every 8 hours',
    'Every 12 hours',
    'As needed',
    'Weekly',
    'Monthly',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!['name'] ?? '';
      _dosageController.text = widget.medication!['dosage'] ?? '';
      _notesController.text = widget.medication!['notes'] ?? '';
      _selectedFrequency = widget.medication!['frequency'] ?? 'Once daily';
      
      // Parse time strings to TimeOfDay list
      final timeString = widget.medication!['time'] ?? '';
      if (timeString.isNotEmpty) {
        final timeStrings = timeString.split(',');
        _selectedTimes = timeStrings.map((timeStr) {
          final parts = timeStr.trim().split(':');
          if (parts.length == 2) {
            return TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          return TimeOfDay.now();
        }).toList();
      }
      
      // Ensure we have the correct number of times for the frequency
      _updateTimesForFrequency(_selectedFrequency);
    }
  }

  void _updateTimesForFrequency(String frequency) {
    int requiredTimes = 1;
    switch (frequency) {
      case 'Once daily':
        requiredTimes = 1;
        break;
      case 'Twice daily':
        requiredTimes = 2;
        break;
      case 'Three times daily':
        requiredTimes = 3;
        break;
      case 'Four times daily':
        requiredTimes = 4;
        break;
      case 'Every 6 hours':
        requiredTimes = 4;
        break;
      case 'Every 8 hours':
        requiredTimes = 3;
        break;
      case 'Every 12 hours':
        requiredTimes = 2;
        break;
      default:
        requiredTimes = 1;
    }
    
    // Adjust the times list to match the required number
    if (_selectedTimes.length < requiredTimes) {
      // Add more times if needed
      while (_selectedTimes.length < requiredTimes) {
        _selectedTimes.add(TimeOfDay.now());
      }
    } else if (_selectedTimes.length > requiredTimes) {
      // Remove extra times if needed
      _selectedTimes = _selectedTimes.take(requiredTimes).toList();
    }
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (picked != null && picked != _selectedTimes[index]) {
      setState(() {
        _selectedTimes[index] = picked;
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final medicationData = {
        'name': _nameController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'frequency': _selectedFrequency,
        'time': _selectedTimes.map((time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}').join(', '),
        'notes': _notesController.text.trim(),
        'patientId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.medicationId == null) {
        // Adding new medication
        medicationData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('medications')
            .add(medicationData);
      } else {
        // Updating existing medication
        await FirebaseFirestore.instance
            .collection('medications')
            .doc(widget.medicationId)
            .update(medicationData);
      }

      if (!mounted) return;
      
      // Schedule reminders for the medication
      try {
        await NotificationService().scheduleMedicationReminders();
      } catch (e) {
        debugPrint('Error scheduling reminders: $e');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.medicationId == null 
                ? 'Medication added successfully!' 
                : 'Medication updated successfully!'
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicationId != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Medication' : 'Add Medication'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
              Color(0xFF90CAF9),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _loading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Saving medication...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // App Logo/Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                isEditing ? Icons.edit : Icons.add,
                                size: 48,
                                color: Colors.blue,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Title
                            Text(
                              isEditing ? 'Edit Medication' : 'Add New Medication',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              isEditing 
                                  ? 'Update your medication information'
                                  : 'Enter your medication details',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Medication Name
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Medication Name',
                                hintText: 'Enter medication name',
                                prefixIcon: const Icon(Icons.medication, color: Colors.blue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter medication name';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Dosage
                            TextFormField(
                              controller: _dosageController,
                              decoration: InputDecoration(
                                labelText: 'Dosage',
                                hintText: 'e.g., 500mg, 1 tablet, 10ml',
                                prefixIcon: const Icon(Icons.science, color: Colors.blue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter dosage';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Frequency
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Frequency',
                                prefixIcon: const Icon(Icons.schedule, color: Colors.blue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              value: _selectedFrequency,
                              items: _frequencies
                                  .map((frequency) => DropdownMenuItem(
                                        value: frequency,
                                        child: Text(frequency),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedFrequency = value;
                                    _updateTimesForFrequency(value);
                                  });
                                }
                              },
                              validator: (value) => value == null ? 'Please select frequency' : null,
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Times Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Medication Times',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(_selectedTimes.length, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () => _selectTime(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.grey.shade50,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.access_time, color: Colors.blue),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Time ${index + 1}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  Text(
                                                    _selectedTimes[index].format(context),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Notes
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Notes (Optional)',
                                hintText: 'Add any additional notes or instructions',
                                prefixIcon: const Icon(Icons.note, color: Colors.blue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Save Button
                            ElevatedButton(
                              onPressed: _saveMedication,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                isEditing ? 'Update Medication' : 'Add Medication',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }
} 