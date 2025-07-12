import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/payment_service.dart';

class PaymentFormScreen extends StatefulWidget {
  final double amount;
  final String plan;

  const PaymentFormScreen({
    super.key,
    required this.amount,
    required this.plan,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  
  String _selectedPaymentMethod = 'Credit Card';
  List<String> _availablePaymentMethods = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _detectedCardType;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _cardNumberController.addListener(_onCardNumberChanged);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);
    final methods = await PaymentService.getAvailablePaymentMethods();
    setState(() {
      _availablePaymentMethods = methods;
      _isLoading = false;
    });
  }

  void _onCardNumberChanged() {
    final cardNumber = _cardNumberController.text;
    final cardType = PaymentService.detectCardType(cardNumber);
    setState(() => _detectedCardType = cardType);
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final result = await PaymentService.simulatePayment(
        amount: widget.amount,
        plan: widget.plan,
        paymentMethod: _selectedPaymentMethod,
        cardNumber: _cardNumberController.text,
      );

      if (result.success) {
        if (mounted) {
          _showSuccessDialog(result);
        }
      } else {
        if (mounted) {
          _showErrorDialog(result.errorMessage ?? 'Payment failed');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An unexpected error occurred');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(PaymentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: ${result.transactionId}'),
            SizedBox(height: 8),
            Text('Amount: \$${result.amount?.toStringAsFixed(2)}'),
            SizedBox(height: 8),
            Text('Method: ${result.paymentMethod}'),
            SizedBox(height: 8),
            Text('Date: ${result.timestamp?.toString().substring(0, 19)}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true); // Return success
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        ...(_availablePaymentMethods.map((method) => RadioListTile<String>(
          title: Row(
            children: [
              _getPaymentMethodIcon(method),
              SizedBox(width: 12),
              Text(method),
            ],
          ),
          value: method,
          groupValue: _selectedPaymentMethod,
          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
        ))),
      ],
    );
  }

  Widget _getPaymentMethodIcon(String method) {
    IconData iconData;
    Color color;
    
    switch (method) {
      case 'Credit Card':
      case 'Debit Card':
        iconData = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'PayPal':
        iconData = Icons.payment;
        color = Colors.indigo;
        break;
      case 'Apple Pay':
        iconData = Icons.apple;
        color = Colors.black;
        break;
      default:
        iconData = Icons.payment;
        color = Colors.grey;
    }
    
    return Icon(iconData, color: color, size: 24);
  }

  Widget _buildCardForm() {
    if (!_selectedPaymentMethod.contains('Card')) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Card Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cardholder name';
            }
            return null;
          },
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.credit_card),
            suffixIcon: _detectedCardType != null 
              ? Container(
                  padding: EdgeInsets.all(8),
                  child: Text(_detectedCardType!, style: TextStyle(fontSize: 12)),
                )
              : null,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            if (value.length < 13) {
              return 'Invalid card number';
            }
            return null;
          },
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length != 4) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length < 3) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment Summary
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Plan:'),
                          Text(widget.plan, style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Amount:'),
                          Text('\$${widget.amount.toStringAsFixed(2)}', 
                               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Payment Method Selection
              _buildPaymentMethodSelector(),
              SizedBox(height: 24),
              
              // Card Form (if card payment selected)
              _buildCardForm(),
              SizedBox(height: 32),
              
              // Process Payment Button
              _isProcessing
                ? Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing payment...'),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Pay \$${widget.amount.toStringAsFixed(2)}'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
} 