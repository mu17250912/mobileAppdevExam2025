import 'package:flutter/material.dart';
import '../../widgets/custom_appbar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final DateTime dateTime;
  final String serviceType;
  final String paymentMethod;
  final String notes;
  final String location;
  
  const PaymentScreen({
    required this.service,
    required this.dateTime,
    required this.serviceType,
    required this.paymentMethod,
    required this.notes,
    required this.location,
    Key? key,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _processing = false;
  bool _paymentSuccess = false;

  // Mock pricing based on service type
  double get _price {
    switch (widget.serviceType) {
      case 'Basic Service':
        return 25.0;
      case 'Standard Service':
        return 45.0;
      case 'Premium Service':
        return 75.0;
      default:
        return 25.0;
    }
  }

  Future<void> _processPayment() async {
    setState(() { _processing = true; });
    
    try {
      // Simulate Stripe payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Save booking to Firestore
      await _saveBookingToFirestore();
      
      // Update provider availability
      await _updateProviderAvailability();
      
      // Send notifications
      await _sendNotifications();
      
      setState(() { 
        _processing = false;
        _paymentSuccess = true;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Booking confirmed.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to home
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.popUntil(context, (route) => route.isFirst);
      });
      
    } catch (e) {
      setState(() { _processing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveBookingToFirestore() async {
    final booking = {
      'userId': 'user123',
      'providerId': widget.service['id'],
      'providerName': widget.service['name'],
      'date': widget.dateTime.toIso8601String(),
      'serviceType': widget.serviceType,
      'status': 'confirmed',
      'paymentStatus': 'paid',
      'notes': widget.notes,
      'location': widget.location,
      'price': _price,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    // TODO: Call FirestoreService.saveBooking(booking)
    print('Booking saved to Firestore: $booking');
  }

  Future<void> _updateProviderAvailability() async {
    // TODO: Update provider's availability in Firestore
    print('Provider availability updated');
  }

  Future<void> _sendNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Send notification to provider
      await NotificationService.sendPaymentNotification(
        providerId: widget.service['id'],
        userId: user.uid,
        userName: 'User', // You can get actual user name from Firestore
        serviceType: widget.serviceType,
        amount: _price,
        paymentMethod: widget.paymentMethod,
      );
    } catch (e) {
      print('Error sending payment notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Payment'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Provider', widget.service['name']),
                    _buildSummaryRow('Service', widget.serviceType),
                    _buildSummaryRow('Date', DateFormat('MMM dd, yyyy').format(widget.dateTime)),
                    _buildSummaryRow('Time', DateFormat('hh:mm a').format(widget.dateTime)),
                    _buildSummaryRow('Location', widget.location),
                    if (widget.notes.isNotEmpty)
                      _buildSummaryRow('Notes', widget.notes),
                    const Divider(),
                    _buildSummaryRow('Total', '\$${_price.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Payment Method
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            if (widget.paymentMethod == 'Pay Now') ...[
              // Credit Card Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Credit Card Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Card Number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.credit_card),
                        ),
                        onChanged: (value) => _cardNumber = value,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Expiry Date (MM/YY)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (value) => _expiryDate = value,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'CVV',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (value) => _cvv = value,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Pay Later Option
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pay Later', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('You will be charged after the service is completed.'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _processing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : Text(
                        widget.paymentMethod == 'Pay Now' ? 'Pay \$${_price.toStringAsFixed(2)}' : 'Confirm Booking',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            if (_paymentSuccess) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.green.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'Booking Confirmed!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You will receive a confirmation email and push notification.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
} 