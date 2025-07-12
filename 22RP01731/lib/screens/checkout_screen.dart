import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import 'order_confirmation_screen.dart';
import 'delivery_info_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedPaymentMethod;
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mobileNumberController.addListener(() {
      if (_selectedPaymentMethod == 'Mobile Money') {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _mobileNumberController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  bool get _isMobileNumberValid {
    final text = _mobileNumberController.text.trim();
    return RegExp(r'^\d{10}').hasMatch(text);
  }

  bool get _isCardNumberValid {
    final text = _cardNumberController.text.replaceAll(' ', '');
    return RegExp(r'^\d{16}').hasMatch(text);
  }

  bool get _isExpiryValid {
    final text = _cardExpiryController.text.trim();
    return RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})').hasMatch(text);
  }

  bool get _isCvvValid {
    final text = _cardCvvController.text.trim();
    return RegExp(r'^\d{3}').hasMatch(text);
  }

  bool get _canPlaceOrder {
    if (_selectedPaymentMethod == 'Mobile Money') {
      return _isMobileNumberValid;
    } else if (_selectedPaymentMethod == 'Credit Card') {
      return _isCardNumberValid && _isExpiryValid && _isCvvValid;
    }
    return _selectedPaymentMethod != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Consumer<CartService>(
        builder: (context, cart, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...cart.items.values.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.product.name} x${item.quantity}'),
                      Text(' \$${item.totalPrice.toStringAsFixed(2)}'),
                    ],
                  ),
                )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' \$${cart.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  title: const Text('Credit Card'),
                  value: 'Credit Card',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Mobile Money'),
                  value: 'Mobile Money',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Cash on Delivery'),
                  value: 'Cash on Delivery',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                ),
                if (_selectedPaymentMethod == 'Mobile Money') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mobileNumberController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      border: const OutlineInputBorder(),
                      errorText: _mobileNumberController.text.isNotEmpty && !_isMobileNumberValid
                          ? 'Enter a valid 10-digit number'
                          : null,
                    ),
                  ),
                ],
                if (_selectedPaymentMethod == 'Credit Card') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    decoration: InputDecoration(
                      labelText: 'Card Number',
                      border: const OutlineInputBorder(),
                      errorText: _cardNumberController.text.isNotEmpty && !_isCardNumberValid
                          ? 'Enter a valid 16-digit card number'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cardExpiryController,
                          keyboardType: TextInputType.datetime,
                          maxLength: 5,
                          decoration: InputDecoration(
                            labelText: 'Expiry (MM/YY)',
                            border: const OutlineInputBorder(),
                            errorText: _cardExpiryController.text.isNotEmpty && !_isExpiryValid
                                ? 'MM/YY format'
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _cardCvvController,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          decoration: InputDecoration(
                            labelText: 'CVV',
                            border: const OutlineInputBorder(),
                            errorText: _cardCvvController.text.isNotEmpty && !_isCvvValid
                                ? '3 digits'
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canPlaceOrder
                        ? () async {
                            await FirebaseAnalytics.instance.logEvent(
                              name: 'place_order',
                              parameters: {
                                'payment_method': _selectedPaymentMethod ?? 'unknown',
                              },
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const DeliveryInfoScreen()),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canPlaceOrder ? Colors.green.shade600 : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  final String paymentMethod;
  const OrderConfirmationScreen({super.key, required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Thank you for your order. We\'ll deliver your groceries soon!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'Payment Method: $paymentMethod',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
