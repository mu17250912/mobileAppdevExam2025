import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/payment_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:another_flushbar/flushbar.dart';

class BookingFormScreen extends StatefulWidget {
  final Map<String, dynamic> talentData;
  const BookingFormScreen({Key? key, required this.talentData})
    : super(key: key);

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _eventDetailsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  double? _commission;
  double? _payout;
  String? _paymentStatus;
  String? _txRef;
  int _step = 0;
  // Add a flag to track if the widget is mounted
  bool _isMounted = true;

  @override
  void dispose() {
    _isMounted = false;
    _dateController.dispose();
    _timeController.dispose();
    _eventDetailsController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool success = true}) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      backgroundColor: success ? Colors.green : Colors.red,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      icon: Icon(
        success ? Icons.check_circle : Icons.error,
        color: Colors.white,
      ),
    ).show(context);
  }

  Future<void> _submitBookingStep() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 1);
  }

  Future<void> _submitPaymentStep() async {
    if (!_paymentFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _paymentStatus = "Please confirm payment on your phone...";
      _commission = null;
      _payout = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final price = double.tryParse(widget.talentData['price'].toString()) ?? 0;
      final paymentResult = await PaymentService.initiatePayment(
        tel: _phoneController.text.trim(),
        amount: price.toStringAsFixed(0),
      );
      if (!_isMounted) return;
      if (paymentResult['success'] != true) {
        if (_isMounted) {
          setState(() {
            _isLoading = false;
            _paymentStatus = paymentResult['message'];
          });
          _showToast(
            paymentResult['message'] ?? 'Payment failed',
            success: false,
          );
        }
        return;
      }
      _txRef = paymentResult['tx_ref'];
      if (_isMounted) {
        setState(() {
          _paymentStatus = paymentResult['message'];
        });
      }
      await PaymentService.pollPaymentStatus(
        _txRef!,
        onStatus: (status) async {
          if (!_isMounted) return;
          if (_isMounted) {
            setState(() {
              _paymentStatus = status == 'paid'
                  ? 'Payment successful!'
                  : status == 'failed'
                  ? 'Payment failed or cancelled.'
                  : 'Please confirm payment on your phone...';
            });
          }
          if (status == 'paid') {
            _commission = price * 0.10;
            _payout = price - _commission!;
            // Save booking
            final bookingRef = await FirebaseFirestore.instance
                .collection('bookings')
                .add({
                  'clientId': user.uid,
                  'clientEmail': user.email,
                  'talentId': widget.talentData['uid'],
                  'talentName': widget.talentData['name'],
                  'talentType': widget.talentData['talentType'],
                  'price': price,
                  'commission': _commission,
                  'payout': _payout,
                  'date': _dateController.text.trim(),
                  'time': _timeController.text.trim(),
                  'eventDetails': _eventDetailsController.text.trim(),
                  'status': 'completed',
                  'paymentStatus': 'paid',
                  'txRef': _txRef,
                  'createdAt': FieldValue.serverTimestamp(),
                });
            // Add notifications for both client and talent
            final now = DateTime.now();
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': user.uid,
              'title': 'Booking Confirmed',
              'body':
                  'You have successfully booked ${widget.talentData['name']} for ${_dateController.text.trim()} at ${_timeController.text.trim()}.',
              'timestamp': now,
              'read': false,
              'bookingId': bookingRef.id,
            });
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': widget.talentData['uid'],
              'title': 'New Booking',
              'body':
                  'You have a new booking from ${user.email ?? ''} for ${_dateController.text.trim()} at ${_timeController.text.trim()}.',
              'timestamp': now,
              'read': false,
              'bookingId': bookingRef.id,
            });
            if (_isMounted) {
              setState(() {
                _isLoading = false;
                _step = 2;
              });
              _showToast('Booking & Payment successful!', success: true);
            }
          } else if (status == 'failed') {
            if (_isMounted) {
              setState(() {
                _isLoading = false;
              });
              _showToast('Payment failed or cancelled.', success: false);
            }
          }
        },
      );
    } catch (e) {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred. Please try again.';
        });
        _showToast('An error occurred. Please try again.', success: false);
      }
    }
  }

  Widget _buildBookingStep() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                _dateController.text =
                    '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Select the date';
                  // Correct regex for yyyy-MM-dd
                  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!regex.hasMatch(value)) return 'Invalid date format';
                  try {
                    final parts = value.split('-');
                    final year = int.parse(parts[0]);
                    final month = int.parse(parts[1]);
                    final day = int.parse(parts[2]);
                    final dt = DateTime(year, month, day);
                    if (dt.year != year || dt.month != month || dt.day != day) {
                      return 'Invalid date';
                    }
                  } catch (_) {
                    return 'Invalid date';
                  }
                  return null;
                },
                readOnly: true,
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                _timeController.text = picked.format(context);
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.access_time),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Select the time' : null,
                readOnly: true,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _eventDetailsController,
            decoration: InputDecoration(
              labelText: 'Event Details',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              prefixIcon: const Icon(Icons.event_note),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter event details' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitBookingStep,
              child: _isLoading
                  ? const SpinKitPouringHourGlassRefined(
                      color: Colors.deepPurple,
                      size: 32,
                    )
                  : const Text('Continue to Payment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    final price = double.tryParse(widget.talentData['price'].toString()) ?? 0;
    return Form(
      key: _paymentFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add bold warning message
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Please enter your real mobile number. Otherwise, the payment prompt will NOT appear on your phone.',
                    style: const TextStyle(
                      color: Color(0xFF7A5C00),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Image.network(
            'https://momo.mtn.com/wp-content/uploads/sites/15/2022/07/Group-360.png?w=360',
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number (MTN MoMo)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              prefixIcon: const Icon(Icons.phone),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.phone,
            validator: (value) => value == null || value.isEmpty
                ? 'Enter your phone number'
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Amount to Pay: ${price.toStringAsFixed(0)} RWF',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPaymentStep,
              child: _isLoading
                  ? const SpinKitPouringHourGlassRefined(
                      color: Colors.deepPurple,
                      size: 32,
                    )
                  : const Text('Pay Now'),
            ),
          ),
          if (_paymentStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _paymentStatus!,
                style: TextStyle(
                  color: _paymentStatus!.contains('success')
                      ? Colors.green
                      : Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    final price = double.tryParse(widget.talentData['price'].toString()) ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.celebration, color: Colors.deepPurple, size: 64),
        const SizedBox(height: 18),
        Text(
          'Booking Confirmed!',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Total: ${price.toStringAsFixed(0)} RWF',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Commission (10%): ${_commission?.toStringAsFixed(0) ?? ''} RWF',
              ),
              Text('Talent Receives: ${_payout?.toStringAsFixed(0) ?? ''} RWF'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        title: Text(
          'Book ${widget.talentData['name']}',
          style: GoogleFonts.poppins(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _step == 0
                  ? _buildBookingStep()
                  : _step == 1
                  ? _buildPaymentStep()
                  : _buildConfirmationStep(),
            ),
          ),
        ),
      ),
    );
  }
}
