import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/payment_service.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _paymentService.getPaymentStats();
    setState(() {
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Statistics
            _buildPaymentStats(),
            const SizedBox(height: 24),

            // Payment History
            _buildPaymentHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStats() {
    final totalAmount = _stats['totalAmount'] ?? 0.0;
    final totalPayments = _stats['totalPayments'] ?? 0;
    final paymentMethods = _stats['paymentMethods'] ?? <String, int>{};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Spent',
                    '${totalAmount.toInt()} FRW',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total Payments',
                    totalPayments.toString(),
                    Icons.payment,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            if (paymentMethods.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Payment Methods Used',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...paymentMethods.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text('${entry.value} times'),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder(
          stream: _paymentService.getPaymentHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No payment history',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your payment transactions will appear here',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final payments = snapshot.data!.docs;

            return Column(
              children: payments.map((doc) {
                final payment = doc.data() as Map<String, dynamic>;
                final amount = payment['amount'] ?? 0.0;
                final description = payment['description'] ?? '';
                final paymentMethod = payment['paymentMethod'] ?? '';
                final transactionId = payment['transactionId'] ?? '';
                final timestamp = payment['timestamp'] as Timestamp?;
                final phoneNumber = payment['phoneNumber'];
                final cardLastDigits = payment['cardLastDigits'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getPaymentMethodColor(paymentMethod),
                      child: Icon(
                        _getPaymentMethodIcon(paymentMethod),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(description),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(paymentMethod),
                        if (phoneNumber != null) Text('Phone: $phoneNumber'),
                        if (cardLastDigits != null) Text('Card: ****$cardLastDigits'),
                        if (timestamp != null) Text(DateFormat('MMM dd, yyyy HH:mm').format(timestamp.toDate())),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${amount.toInt()} FRW',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          transactionId,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () => _showPaymentDetails(payment),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'MTN Mobile Money':
        return Colors.orange;
      case 'Airtel Money':
        return Colors.red;
      case 'Credit/Debit Card':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'MTN Mobile Money':
      case 'Airtel Money':
        return Icons.phone_android;
      case 'Credit/Debit Card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    final amount = payment['amount'] ?? 0.0;
    final description = payment['description'] ?? '';
    final paymentMethod = payment['paymentMethod'] ?? '';
    final transactionId = payment['transactionId'] ?? '';
    final timestamp = payment['timestamp'] as Timestamp?;
    final phoneNumber = payment['phoneNumber'];
    final cardLastDigits = payment['cardLastDigits'];
    final status = payment['status'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '${amount.toInt()} FRW'),
            _buildDetailRow('Description', description),
            _buildDetailRow('Payment Method', paymentMethod),
            _buildDetailRow('Transaction ID', transactionId),
            _buildDetailRow('Status', status.toUpperCase()),
            if (phoneNumber != null) _buildDetailRow('Phone Number', phoneNumber),
            if (cardLastDigits != null) _buildDetailRow('Card', '****$cardLastDigits'),
            if (timestamp != null) _buildDetailRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(timestamp.toDate())),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 