import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderActionScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  const OrderActionScreen({Key? key, required this.orderData}) : super(key: key);

  @override
  State<OrderActionScreen> createState() => _OrderActionScreenState();
}

class _OrderActionScreenState extends State<OrderActionScreen> {
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _saveOrder() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final orderData = Map<String, dynamic>.from(widget.orderData);
      orderData['timestamp'] = FieldValue.serverTimestamp();
      if (user != null) {
        orderData['user'] = {
          'uid': user.uid,
          'email': user.email,
        };
      }
      await FirebaseFirestore.instance.collection('orders').add(orderData);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/order-confirmation', arguments: widget.orderData);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save order. Please try again.';
        _isSaving = false;
      });
    }
  }

  void _printOrder() {
    // Placeholder for print logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print'),
        content: const Text('Printing order report (placeholder).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Actions'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'What would you like to do with your order?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text('Save'),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _printOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text('Print'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 