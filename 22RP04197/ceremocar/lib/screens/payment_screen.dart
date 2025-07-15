import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final double amount;

  const PaymentScreen({
    Key? key,
    required this.bookingData,
    required this.amount,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;
  bool _rememberCard = false;
  String? _cardError;
  String? _phoneError;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool get _isCardValid {
    return _cardNumberController.text.length == 16 &&
      RegExp(r'^[0-9]{16}\$').hasMatch(_cardNumberController.text) &&
      RegExp(r'^[0-9]{2}/[0-9]{2}\$').hasMatch(_expiryController.text) &&
      _cvvController.text.length == 3 &&
      RegExp(r'^[0-9]{3}\$').hasMatch(_cvvController.text);
  }
  bool get _isPhoneValid {
    final phone = _phoneController.text.trim();
    return phone.length == 10 && RegExp(r'^[0-9]{10}?$').hasMatch(phone);
  }
  bool get _canPay {
    if (_selectedPaymentMethod == 'card') return _isCardValid;
    if (_selectedPaymentMethod == 'mobile_money' || _selectedPaymentMethod == 'airtel_money') return _isPhoneValid;
    return true;
  }

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'color': Colors.blue,
    },
    {
      'id': 'paypal',
      'name': 'PayPal',
      'icon': Icons.payment,
      'color': Colors.indigo,
    },
    {
      'id': 'mobile_money',
      'name': 'Mobile Money',
      'icon': Icons.phone_android,
      'color': Colors.green,
    },
    {
      'id': 'airtel_money',
      'name': 'Airtel Money',
      'icon': Icons.phone_iphone,
      'color': Colors.redAccent,
    },
    {
      'id': 'bank_transfer',
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/available_cars_screen',
              (route) => false,
            );
          },
        ),
        title: const Text('Payment'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Summary',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _summaryRow('Car', widget.bookingData['carName'] ?? 'Unknown'),
                    _summaryRow('Date', widget.bookingData['date'] ?? 'Unknown'),
                    _summaryRow('Time', widget.bookingData['time'] ?? 'Unknown'),
                    _summaryRow('Duration', '${widget.bookingData['duration'] ?? 1} hour(s)'),
                    if (widget.bookingData['withDriver'] == true)
                      _summaryRow('Driver', 'Included'),
                    if (widget.bookingData['withDecoration'] == true)
                      _summaryRow('Decoration', 'Included'),
                    const Divider(),
                    _summaryRow(
                      'Total Amount',
                      'FRW${widget.amount.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Payment Method Selection
              Text(
                'Payment Method',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              ..._paymentMethods.map((method) => _paymentMethodTile(method, theme)),
              const SizedBox(height: 24),
              
              // Payment Form
              if (_selectedPaymentMethod == 'card') ...[
                Text(
                  'Card Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _cardForm(theme),
                if (_cardError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_cardError!, style: const TextStyle(color: Colors.red)),
                  ),
              ] else if (_selectedPaymentMethod == 'mobile_money') ...[
                Text(
                  'Mobile Money',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _mobileMoneyForm(theme),
                if (_phoneError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_phoneError!, style: const TextStyle(color: Colors.red)),
                  ),
              ] else if (_selectedPaymentMethod == 'airtel_money') ...[
                Text(
                  'Airtel Money',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Airtel Money Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You will receive a payment prompt on your Airtel Money number.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_phoneError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_phoneError!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: !_canPay || _isProcessing ? null : () async {
                  setState(() { _cardError = null; _phoneError = null; });
                  if (_selectedPaymentMethod == 'card' && !_isCardValid) {
                    setState(() { _cardError = 'Enter valid card details.'; });
                    return;
                  }
                  if ((_selectedPaymentMethod == 'mobile_money' || _selectedPaymentMethod == 'airtel_money') && !_isPhoneValid) {
                    setState(() { _phoneError = 'Enter a valid 10-digit phone number.'; });
                    return;
                  }
                  await _processPayment();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Text('Pay FRW${widget.amount.toStringAsFixed(2)}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodTile(Map<String, dynamic> method, ThemeData theme) {
    final isSelected = _selectedPaymentMethod == method['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? method['color'] : theme.colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          method['icon'],
          color: method['color'],
        ),
        title: Text(method['name']),
        trailing: Radio<String>(
          value: method['id'],
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
          activeColor: method['color'],
        ),
      ),
    );
  }

  Widget _cardForm(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Cardholder Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'MM/YY',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Remember this card for future payments'),
            value: _rememberCard,
            onChanged: (value) {
              setState(() {
                _rememberCard = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _mobileMoneyForm(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          Text(
            'You will receive a payment prompt on your mobile device.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    final theme = Theme.of(context);
    setState(() {
      _isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 3));

      // Create booking in Firestore
      final bookingRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add({
        'userId': user.uid,
        'carId': widget.bookingData['carId'],
        'carName': widget.bookingData['carName'],
        'date': widget.bookingData['date'],
        'time': widget.bookingData['time'],
        'duration': widget.bookingData['duration'],
        'withDriver': widget.bookingData['withDriver'],
        'withDecoration': widget.bookingData['withDecoration'],
        'specialRequest': widget.bookingData['specialRequest'],
        'amount': widget.amount,
        'paymentMethod': _selectedPaymentMethod,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            final theme = Theme.of(context);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: theme.colorScheme.surface,
              title: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 72),
                    const SizedBox(height: 16),
                    Text('Payment Successful!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Your booking has been confirmed and payment processed successfully.', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('Booking ID: ${bookingRef.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/my_bookings_screen',
                      (route) => false,
                    );
                  },
                  child: Text('View My Bookings', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      }

      // Add notification for admin
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': null, // notify all admins
        'title': 'New Booking Request',
        'message': 'A new booking for ${widget.bookingData['carName'] ?? 'a car'} has been made by a user.',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });
      // Add notification for user
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'title': 'Booking Created',
        'message': 'Your booking for ${widget.bookingData['carName'] ?? 'a car'} on ${widget.bookingData['date']} has been created and is pending.',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
} 