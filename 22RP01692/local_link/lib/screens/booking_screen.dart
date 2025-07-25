import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDateTime;
  bool _processing = false;
  Map<String, dynamic>? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _service = args;
    }
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
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _payWithStripe() async {
    setState(() { _processing = true; });
    try {
      // This is a placeholder for Stripe payment logic.
      // In a real app, you would call your backend to create a PaymentIntent and confirm it here.
      await Future.delayed(const Duration(seconds: 2));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment successful! (mock)')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      setState(() { _processing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
      ),
      body: service == null
          ? const Center(child: Text('No service selected.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service['name'] ?? 'Service', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(service['description'] ?? ''),
                  const SizedBox(height: 24),
                  const Text('Select Date & Time:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_selectedDateTime == null
                            ? 'No date/time selected'
                            : DateFormat('yyyy-MM-dd – kk:mm').format(_selectedDateTime!)),
                      ),
                      ElevatedButton(
                        onPressed: _pickDateTime,
                        child: const Text('Pick'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: _processing ? const CircularProgressIndicator(color: Colors.white) : const Text('Pay & Book'),
                      onPressed: _selectedDateTime == null || _processing ? null : _payWithStripe,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
