import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

class BookingsScreen extends StatefulWidget {
  final String? serviceType;
  const BookingsScreen({super.key, this.serviceType});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _formKey = GlobalKey<FormState>();

  String _serviceTier = 'Basic'; // Ensure this is always non-null
  String _contactName = '';
  String _contactPhone = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _location = '';
  String _notes = '';
  bool _submitting = false;

  final Map<String, int> _tierPrices = {
    'Basic': 4500,
    'Standard': 7000,
    'Premium': 10000,
  };

  String? _serviceType;
  final String _providerId = 'provider456';

  @override
  void initState() {
    super.initState();
    _serviceType = widget.serviceType ?? 'plumbing';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final DateTime dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final booking = {
        'contactname': _contactName,
        'contactphone': _contactPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'date': Timestamp.fromDate(dateTime),
        'location': _location,
        'notes': _notes,
        'paymentstatus': 'unpaid',
        'price': (_tierPrices[_serviceTier]! as num).toDouble(),
        'providerId': _providerId,
        'serviceType': _serviceType,
        'status': 'pending',
        'userId': user.uid,
      };
      await FirebaseFirestore.instance.collection('bookings').add(booking);
      
      // Send notification to provider using NotificationService
      await NotificationService.sendBookingNotification(
        providerId: _providerId,
        userId: user.uid,
        userName: _contactName,
        serviceType: _serviceType!,
        location: _location,
        dateTime: dateTime,
        price: (_tierPrices[_serviceTier]! as num).toDouble(),
        notes: _notes,
      );
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Booking Submitted'),
          content: const Text('Your booking has been submitted successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog only
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to bookings tab
              },
              child: const Text('Back to My Bookings'),
            ),
          ],
        ),
      );
      _formKey.currentState!.reset();
      setState(() {
        _serviceTier = 'Basic';
        _selectedDate = null;
        _selectedTime = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Service'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Type (pre-filled and read-only)
              if (_serviceType != null) ...[
                const Text('Service Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _serviceType,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Service Tier
              const Text('Which service tier do you want?', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _serviceTier,
                items: _tierPrices.entries.map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text('${e.key}  (${e.value}frw)'),
                )).toList(),
                onChanged: (val) => setState(() => _serviceTier = val!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              // Contact Name
              const Text("What's your name?", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your name',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
                onChanged: (val) => _contactName = val,
              ),
              const SizedBox(height: 20),

              // Contact Phone
              const Text("What's your phone number?", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your phone number',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter your phone number' : null,
                onChanged: (val) => _contactPhone = val,
              ),
              const SizedBox(height: 20),

              // Date
              const Text('What date do you need service?', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select date',
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select date'
                        : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time
              const Text('What time works best?', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select time',
                  ),
                  child: Text(
                    _selectedTime == null
                        ? 'Select time'
                        : _selectedTime!.format(context),
                    style: TextStyle(
                      color: _selectedTime == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Location
              const Text("What's your address?", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your address',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter your address' : null,
                onChanged: (val) => _location = val,
              ),
              const SizedBox(height: 20),

              // Service Details
              const Text('Please describe what needs to be fixed/installed', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describe your service needs',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please describe the service' : null,
                onChanged: (val) => _notes = val,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 