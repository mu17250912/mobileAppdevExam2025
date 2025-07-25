import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';

class DeliveryConfirmationScreen extends StatefulWidget {
  final Request request;
  
  const DeliveryConfirmationScreen({
    super.key,
    required this.request,
  });

  @override
  State<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _confirmationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyConfirmed();
  }

  Future<void> _checkIfAlreadyConfirmed() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.request.id)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _isConfirmed = data['employeeConfirmed'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error checking confirmation status: $e');
    }
  }

  Future<void> _confirmDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the request in Firestore
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.request.id)
          .update({
        'employeeConfirmed': true,
        'employeeConfirmationDate': DateTime.now().toIso8601String(),
        'employeeConfirmationNotes': _notesController.text.trim(),
        'employeeConfirmationSignature': _confirmationController.text.trim(),
      });

      // Add to history
      final historyEntry = {
        'status': 'Delivery Confirmed by Employee',
        'actor': 'Employee',
        'comment': 'Employee confirmed receipt of delivery. Notes: ${_notesController.text.trim()}',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.request.id)
          .update({
        'history': FieldValue.arrayUnion([historyEntry]),
      });

      // Add notification for logistics
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Delivery Confirmed by Employee',
        'body': 'Employee ${widget.request.employeeName} has confirmed receipt of "${widget.request.subject}".',
        'type': 'delivery_confirmed',
        'targetRole': 'Logistics',
        'requestSubject': widget.request.subject,
        'timestamp': FieldValue.serverTimestamp(),
        'requestId': widget.request.id,
      });

      setState(() {
        _isConfirmed = true;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have confirmed receipt of this delivery!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming delivery: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Delivery'),
        actions: [
          if (_isConfirmed)
            const Icon(
              Icons.verified,
              color: Colors.green,
            ),
        ],
      ),
      body: _isConfirmed
          ? Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 64,
                          color: Colors.green,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Delivery Confirmed!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You have successfully confirmed receipt of this delivery.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                // Show full request history
                if (widget.request.history.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: Colors.grey[100],
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Request History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        ...widget.request.history.map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.history, size: 16, color: Colors.blueGrey),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${entry['status']} by ${entry['actor']}', style: TextStyle(fontWeight: FontWeight.bold)),
                                        if (entry['comment'] != null && entry['comment'].toString().isNotEmpty)
                                          Text(entry['comment'], style: TextStyle(color: Colors.black87)),
                                        if (entry['timestamp'] != null)
                                          Text(entry['timestamp'], style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ))
                      ],
                    ),
                  ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Delivery Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.title),
                              title: const Text('Item'),
                              subtitle: Text(widget.request.subject),
                            ),
                            ListTile(
                              leading: const Icon(Icons.confirmation_number),
                              title: const Text('Quantity'),
                              subtitle: Text(widget.request.quantity ?? 'Not specified'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: const Text('Employee'),
                              subtitle: Text(widget.request.employeeName),
                            ),
                            ListTile(
                              leading: const Icon(Icons.date_range),
                              title: const Text('Delivery Date'),
                              subtitle: Text(widget.request.date.toLocal().toString().split(' ')[0]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Confirmation Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmationController,
                              decoration: const InputDecoration(
                                labelText: 'Your Name (Signature) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                                hintText: 'Enter your full name as signature',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name as signature';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Additional Notes (Optional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note),
                                hintText: 'Any additional comments about the delivery',
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(_isLoading ? 'Confirming...' : 'I confirm that requested tools received by me'),
                        onPressed: _isLoading ? null : _confirmDelivery,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Important Notes:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('• Please verify that you have received the correct items'),
                            Text('• Check the quantity matches your request'),
                            Text('• Report any issues in the notes section'),
                            Text('• This confirmation cannot be undone'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 