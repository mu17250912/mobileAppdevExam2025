import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const int _homeIndex = 0;
  static const int _reportIndex = 1;
  static const int _profileIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Neighborhood Alerts'),
            Text(
              'Welcome NeighborhoodAlert',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.contact_phone),
            tooltip: 'Emergency Contacts',
            onPressed: () {
              Navigator.pushNamed(context, '/emergency-contacts');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No alerts found.'));
          }
          final alerts = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final data = alerts[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getAlertIcon(data['type'] ?? ''),
                            color: _getAlertColor(data['type'] ?? ''),
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            data['type'] ?? 'Alert',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _getAlertColor(data['type'] ?? ''),
                            ),
                          ),
                          const Spacer(),
                          Chip(
                            label: Text((data['status'] ?? 'Active').toString().capitalize()),
                            backgroundColor: _getStatusColor(data['status'] ?? ''),
                            labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['description'] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            data['location'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Spacer(),
                          if (data['timestamp'] != null)
                            Text(
                              _formatTimeAgo(data['timestamp']),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.payment),
            label: Text('Simulate Payment'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => SimulatedPaymentDialog(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'emergency',
            onPressed: () {
              Navigator.pushNamed(context, '/emergency-contacts');
            },
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.contact_phone),
            tooltip: 'Emergency Contacts',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'report',
            onPressed: () {
              Navigator.pushNamed(context, '/report-alert');
            },
            child: const Icon(Icons.add),
            tooltip: 'Report Alert',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _homeIndex, // Home
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_alert), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == _homeIndex) return; // Already on Home
          if (index == _reportIndex) {
            Navigator.pushReplacementNamed(context, '/report-alert');
          } else if (index == _profileIndex) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

extension StringCasingExtension on String {
  String capitalize() => this.isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

Future<void> launchStripeCheckout() async {
  final url = Uri.parse('https://buy.stripe.com/test_...'); // Paste your new, real Stripe payment link here
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch Stripe checkout URL';
  }
}

class SimulatedPaymentDialog extends StatefulWidget {
  @override
  _SimulatedPaymentDialogState createState() => _SimulatedPaymentDialogState();
}

class _SimulatedPaymentDialogState extends State<SimulatedPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  String _amount = '';
  String _method = 'Stripe';
  bool _isPaying = false;
  bool _paid = false;
  double? _commission;
  double? _providerAmount;
  String? _email;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _email = user?.email;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown';
    return AlertDialog(
      title: Text('Simulated Payment (Demo)'),
      content: _paid
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment successful! (Simulated)\nThank you for supporting the community.'),
                SizedBox(height: 12),
                Text('Email: $email', style: TextStyle(fontSize: 14, color: Colors.black54)),
                if (_commission != null && _providerAmount != null) ...[
                  SizedBox(height: 8),
                  Text('Commission (10%):  \$${_commission!.toStringAsFixed(2)}'),
                  Text('Provider Receives: \$${_providerAmount!.toStringAsFixed(2)}'),
                ],
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Email: $email', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Amount (USD)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _amount = value,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter an amount' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _method,
                    items: [
                      DropdownMenuItem(value: 'Stripe', child: Text('Stripe')),
                      DropdownMenuItem(value: 'PayPal', child: Text('PayPal')),
                      DropdownMenuItem(value: 'Flutterwave', child: Text('Flutterwave')),
                      DropdownMenuItem(value: 'MTN', child: Text('MTN Mobile Money')),
                    ],
                    onChanged: (value) => setState(() => _method = value ?? 'Stripe'),
                    decoration: InputDecoration(labelText: 'Payment Method'),
                  ),
                ],
              ),
            ),
      actions: [
        if (!_paid)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        if (!_paid)
          ElevatedButton(
            onPressed: _isPaying
                ? null
                : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() => _isPaying = true);
                      // Simulate payment delay
                      await Future.delayed(Duration(seconds: 2));
                      final user = FirebaseAuth.instance.currentUser;
                      final email = user?.email;
                      final amount = double.tryParse(_amount) ?? 0;
                      final commission = double.parse((amount * 0.10).toStringAsFixed(2));
                      final providerAmount = double.parse((amount - commission).toStringAsFixed(2));
                      // Save to Firestore for demo
                      await FirebaseFirestore.instance.collection('payments').add({
                        'userId': user?.uid,
                        'email': email,
                        'amount': amount,
                        'method': _method,
                        'commission': commission,
                        'providerAmount': providerAmount,
                        'timestamp': DateTime.now(),
                        'type': 'simulated_commission',
                      });
                      setState(() {
                        _isPaying = false;
                        _paid = true;
                        _commission = commission;
                        _providerAmount = providerAmount;
                      });
                      // Optionally close dialog after a delay
                      Future.delayed(Duration(seconds: 2), () {
                        Navigator.pop(context);
                      });
                    }
                  },
            child: _isPaying
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Pay'),
          ),
        if (_paid)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
      ],
    );
  }
}

IconData _getAlertIcon(String type) {
  switch (type.toLowerCase()) {
    case 'fire': return Icons.local_fire_department;
    case 'medical': return Icons.medical_services;
    case 'accident': return Icons.car_crash;
    case 'crime': return Icons.security;
    case 'disaster': return Icons.warning;
    default: return Icons.error_outline;
  }
}

Color _getAlertColor(String type) {
  switch (type.toLowerCase()) {
    case 'fire': return Colors.redAccent;
    case 'medical': return Colors.pinkAccent;
    case 'accident': return Colors.orangeAccent;
    case 'crime': return Colors.deepPurple;
    case 'disaster': return Colors.teal;
    default: return Colors.grey;
  }
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending': return Colors.orange;
    case 'approved': return Colors.green;
    case 'resolved': return Colors.blue;
    default: return Colors.grey;
  }
} 