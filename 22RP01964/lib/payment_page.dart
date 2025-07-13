import 'package:flutter/material.dart';
import 'payment_service.dart';
import 'theme.dart'; // Use the app-wide kPrimaryColor

class PaymentPage extends StatefulWidget {
  final String? initialPhone;
  final String? initialAmount;
  final Function(String txRef)? onPaymentSuccess;
  const PaymentPage({
    this.initialPhone,
    this.initialAmount,
    this.onPaymentSuccess,
    Key? key,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _telController;
  late TextEditingController _amountController;

  String _statusMessage = '';
  bool _isLoading = false;
  String? _txRef;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _telController = TextEditingController(text: widget.initialPhone ?? '');
    _amountController = TextEditingController(text: widget.initialAmount ?? '');
  }

  @override
  void dispose() {
    _telController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _startPayment() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _isPolling = false;
    });
    final result = await PaymentService.initiatePayment(
      tel: _telController.text.trim(),
      amount: _amountController.text.trim(),
    );
    setState(() {
      _isLoading = false;
      _statusMessage = result['message'] ?? '';
      _txRef = result['tx_ref'];
    });
    if (result['success'] == true && _txRef != null) {
      setState(() {
        _isPolling = true;
      });
      PaymentService.pollPaymentStatus(
        _txRef!,
        onStatus: (status) {
          setState(() {
            if (status == 'paid') {
              _statusMessage = '✅ Payment successful!';
              _isPolling = false;
              if (widget.onPaymentSuccess != null)
                widget.onPaymentSuccess!(_txRef!);
            } else if (status == 'failed') {
              _statusMessage = '❌ Payment failed or cancelled.';
              _isPolling = false;
            } else {
              _statusMessage = 'Please confirm payment on your phone...';
            }
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: kPrimaryColor),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You are paying with MTN MoMo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kPrimaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _telController,
                decoration: InputDecoration(labelText: 'Phone number'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter phone number' : null,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                enabled: false, // Make amount read-only
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPolling
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _startPayment();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1.1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('Pay Now'),
                      ),
                    ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
