import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/payment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/booking_provider.dart';
import '../../../models/booking.dart';
import '../../../models/property.dart';
import './bookings_management_screen.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  final PaymentService _paymentService = PaymentService();
  final BookingProvider _bookingProvider = BookingProvider();
  List<PaymentRecord> _payments = [];
  List<Booking> _bookings = [];
  bool _isLoading = true;
  double _totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    _loadPaymentsForLandlord();
  }

  Future<void> _loadPaymentsForLandlord() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      if (currentUser != null) {
        // Get all bookings for this landlord
        final bookings = await _bookingProvider.getBookingsByLandlord(currentUser.id);
        final bookingIds = bookings.map((b) => b.id).toList();
        // Get all payments for these bookings
        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('payments')
            .where('bookingId', whereIn: bookingIds.isEmpty ? ['none'] : bookingIds)
            .orderBy('createdAt', descending: true)
            .get();
        final payments = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return PaymentRecord.fromJson({
            'id': doc.id,
            ...data,
          });
        }).toList();
        double total = 0;
        for (final p in payments) {
          if (p.status == PaymentStatus.completed) {
            total += p.amount;
          }
        }
        setState(() {
          _bookings = bookings;
          _payments = payments;
          _totalEarnings = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading landlord payments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Booking? _findBooking(String bookingId) {
    for (final b in _bookings) {
      if (b is Booking && b.id == bookingId) {
        return b;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                      Icon(Icons.payments_outlined, size: 80, color: Colors.amber[700]),
                      const SizedBox(height: 24),
                      const Text(
                        'No payments found',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Once tenants pay for bookings, you’ll see all your payments here.',
                        style: TextStyle(fontSize: 16, color: Colors.black45),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Learn More'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('How Payments Work'),
                              content: const Text(
                                'When a tenant books your property and completes payment, the transaction will appear here. You can track all your earnings and payment statuses in this section.'
                                '\n\nFor more help, contact support@rentmate.com.'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
          ),
        ],
      ),
    );
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.book_online),
                        label: const Text('View Bookings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[800],
                          side: BorderSide(color: Colors.amber[800]!),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const BookingsManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary analytics
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('Total Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('RWF ${_totalEarnings.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, color: Colors.green)),
                            ],
                          ),
                Column(
                  children: [
                              const Text('Payments', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('${_payments.length}', style: const TextStyle(fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          final booking = _findBooking(payment.bookingId);
                          final propertyTitle = booking?.property.title ?? 'Unknown Property';
                          final tenantEmail = booking?.userId ?? 'Unknown';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(payment.status),
                                child: Icon(
                                  _getStatusIcon(payment.status),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(propertyTitle),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tenant: $tenantEmail'),
                                  Text('Amount: RWF ${payment.amount.toStringAsFixed(0)}'),
                                  Text('Method: ${payment.paymentMethod}'),
                                  Text('Date: ${_formatDate(payment.createdAt)}'),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(
                                  payment.status.toString().split('.').last.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                backgroundColor: _getStatusColor(payment.status),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check;
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
        return Icons.refresh;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 