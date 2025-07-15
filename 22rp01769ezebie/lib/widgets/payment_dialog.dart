import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../services/notification_service.dart';

class PaymentDialog extends StatefulWidget {
  final String planType;
  final Map<String, dynamic> planData;
  final String username;

  const PaymentDialog({
    Key? key,
    required this.planType,
    required this.planData,
    required this.username,
  }) : super(key: key);

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String selectedPaymentMethod = 'Credit Card';
  bool isProcessing = false;
  final _formKey = GlobalKey<FormState>();
  
  // Credit Card fields
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  
  // PayPal fields
  final _paypalEmailController = TextEditingController();
  final _paypalPasswordController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    _paypalEmailController.dispose();
    _paypalPasswordController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isProcessing = true;
    });

    try {
      Map<String, dynamic> paymentDetails = {};
      
      switch (selectedPaymentMethod) {
        case 'Credit Card':
          paymentDetails = {
            'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
            'expiryDate': _expiryDateController.text,
            'cvv': _cvvController.text,
            'cardholderName': _cardholderNameController.text,
          };
          break;
        case 'PayPal':
          paymentDetails = {
            'email': _paypalEmailController.text,
            'password': _paypalPasswordController.text,
          };
          break;
        case 'Apple Pay':
        case 'Google Pay':
          paymentDetails = {
            'method': selectedPaymentMethod,
            'token': 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          };
          break;
      }

      final result = await SubscriptionService.processPayment(
        username: widget.username,
        planType: widget.planType,
        paymentMethod: selectedPaymentMethod,
        paymentDetails: paymentDetails,
      );

      if (result['success']) {
        // Show success notification
        await NotificationService.showPremiumActivatedNotification();
        
        if (mounted) {
          Navigator.of(context).pop({
            'success': true,
            'planType': widget.planType,
            'message': result['message'],
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Widget _buildPaymentForm() {
    switch (selectedPaymentMethod) {
      case 'Credit Card':
        return Column(
          children: [
            TextFormField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter card number';
                }
                if (value.replaceAll(' ', '').length < 13) {
                  return 'Invalid card number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryDateController,
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      prefixIcon: Icon(Icons.security),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (value.length < 3) {
                        return 'Invalid CVV';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _cardholderNameController,
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter cardholder name';
                }
                return null;
              },
            ),
          ],
        );

      case 'PayPal':
        return Column(
          children: [
            TextFormField(
              controller: _paypalEmailController,
              decoration: InputDecoration(
                labelText: 'PayPal Email',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter PayPal email';
                }
                if (!value.contains('@')) {
                  return 'Please enter valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _paypalPasswordController,
              decoration: InputDecoration(
                labelText: 'PayPal Password',
                hintText: 'Enter your password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                return null;
              },
            ),
          ],
        );

      case 'Apple Pay':
      case 'Google Pay':
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                selectedPaymentMethod == 'Apple Pay' 
                  ? Icons.apple 
                  : Icons.android,
                size: 32,
                color: Colors.grey[600],
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'You will be redirected to ${selectedPaymentMethod} to complete the payment.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        );

      default:
        return Text('Select a payment method');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.payment, color: Colors.green),
          SizedBox(width: 8),
          Text('Complete Payment'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan summary
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.planData['title'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.planData['price'],
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              
              // Payment method selection
              Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedPaymentMethod,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: (widget.planData['payment_methods'] as List<String>).map<DropdownMenuItem<String>>((String method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Row(
                      children: [
                        Icon(
                          method == 'Credit Card' ? Icons.credit_card :
                          method == 'PayPal' ? Icons.payment :
                          method == 'Apple Pay' ? Icons.apple :
                          Icons.android,
                        ),
                        SizedBox(width: 8),
                        Text(method),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              
              // Payment form
              _buildPaymentForm(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: isProcessing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Processing...'),
                ],
              )
            : Text('Pay ${widget.planData['price']}'),
        ),
      ],
    );
  }
} 