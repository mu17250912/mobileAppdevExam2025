import 'package:flutter/material.dart';
import 'services/simulated_payment_service.dart';
import 'services/analytics_service.dart';
import 'payment_success_screen.dart';
import 'models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'services/cart_service.dart';
import 'services/auth_service.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final List<Map<String, dynamic>> items;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.items,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'mobile_money';
  String? _errorMessage;
  bool _phoneFieldTouched = false;

  @override
  void initState() {
    super.initState();
    // Track payment screen view
    AnalyticsService.trackScreenView('payment_screen');
    // Pre-fill with demo number for testing
    _phoneController.text = '+250700000001';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.feedback_outlined),
            tooltip: 'Send Feedback',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Send Feedback'),
                  content: const Text('Please email your feedback to: support@yourapp.com'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4CAF50),
              const Color(0xFF2E7D32),
              const Color(0xFF1B5E20),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  _buildOrderSummary(),
                  const SizedBox(height: 24),
                  // Payment Method Selection
                  _buildPaymentMethodSelection(),
                  const SizedBox(height: 24),
                  // Mobile Money Form
                  if (_selectedPaymentMethod == 'mobile_money') _buildMobileMoneyForm(),
                  // Error Message
                  if (_errorMessage != null) _buildErrorMessage(),
                  const SizedBox(height: 24),
                  // Pay Button
                  _buildPayButton(),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Privacy Policy'),
                            content: const Text('Read our privacy policy at: https://yourapp.com/privacy'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Privacy Policy'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        backgroundBlendMode: BlendMode.overlay,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          ...widget.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item['name']} x${item['quantity']}',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                Text(
                  'RWF ${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          )),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'RWF ${widget.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Commission (5%):',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              Text(
                'RWF ${(widget.totalAmount * 0.05).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
              ),
              Text(
                'RWF ${(widget.totalAmount * 1.05).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        backgroundBlendMode: BlendMode.overlay,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          RadioListTile<String>(
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_android, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(width: 12),
                const Text('Mobile Money', style: TextStyle(color: Colors.white)),
              ],
            ),
            subtitle: const Text('Pay securely with MTN or Airtel Mobile Money', style: TextStyle(color: Colors.white70)),
            value: 'mobile_money',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
            activeColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMoneyForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        backgroundBlendMode: BlendMode.overlay,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mobile Money Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: '+2507XXXXXXXX',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              if (!_isValidRwandaPhone(value.trim())) {
                return 'Please enter a valid Rwanda phone number (e.g., +250783554935 or 0783554935)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _onPayPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processing Payment...'),
                ],
              )
            : Text(
                'Pay RWF ${(widget.totalAmount * 1.05).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _onPayPressed() async {
    if (!_formKey.currentState!.validate()) {
      setState(() { _phoneFieldTouched = true; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number.'), backgroundColor: Colors.red),
      );
      return;
    }
    final phoneNumber = _phoneController.text.replaceAll(RegExp(r'\s+'), '');
    final totalAmount = widget.totalAmount * 1.05;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Pay RWF ${totalAmount.toStringAsFixed(0)} to $phoneNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _processPayment();
    }
  }

  bool _isValidRwandaPhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    // Accepts +2507XXXXXXXX or 07XXXXXXXX
    return RegExp(r'^(\+2507\d{8}|07\d{8})$').hasMatch(cleaned);
  }

  Future<void> _processPayment() async {
    setState(() {
      _phoneFieldTouched = true;
      _isProcessing = true;
      _errorMessage = null;
    });
    print('Starting payment process...');
    try {
      final phoneNumber = _phoneController.text.replaceAll(RegExp(r'\s+'), '');
      final totalAmount = widget.totalAmount * 1.05;
      final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
      print('Simulating payment for $phoneNumber, amount: $totalAmount, orderId: $orderId');
      await Future.delayed(const Duration(seconds: 2));
      final paymentSuccess = true;
      print('Payment success: $paymentSuccess');
      if (paymentSuccess) {
        await _createOrder(orderId);
        print('Order created');
        context.read<CartService>().clearCart();
        print('Cart cleared');
        await AnalyticsService.trackPaymentSuccess(
          orderId: orderId,
          amount: totalAmount,
          paymentMethod: 'mobile_money',
          referenceId: orderId,
        );
        print('Analytics tracked');
        if (mounted) {
          print('Showing success dialog');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Payment Successful'),
              content: Text('Your payment of RWF ${totalAmount.toStringAsFixed(0)} was successful!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentSuccessScreen(
                          orderId: orderId,
                          amount: totalAmount,
                          referenceId: orderId,
                        ),
                      ),
                    );
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Payment request failed');
      }
    } catch (e) {
      print('Payment error: $e');
      setState(() {
        _errorMessage = 'Payment failed: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}'), backgroundColor: Colors.red),
      );
      await AnalyticsService.trackPaymentFailure(
        orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
        amount: widget.totalAmount * 1.05,
        paymentMethod: 'mobile_money',
        errorMessage: e.toString(),
      );
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Error'),
            content: Text('Something went wrong: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        print('Payment process finished. isProcessing set to false.');
      }
    }
  }

  Future<void> _createOrder(String referenceId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      print('🔵 Creating order. currentUser: $currentUser');
      print('🔵 Items: ${widget.items}');
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final orderData = {
        'productId': widget.items.first['id'] ?? widget.items.first['product_id'] ?? '',
        'productName': widget.items.first['name'] ?? '',
        'price': widget.totalAmount * 1.05,
        'imageUrl': widget.items.first['imageUrl'] ?? widget.items.first['image_url'] ?? '',
        'buyerId': currentUser,
        'buyerUsername': currentUser,
        'dealer': widget.items.first['dealer'] ?? '',
        'status': 'pending',
        'orderDate': Timestamp.now(),
        'paymentReference': referenceId,
        'paymentMethod': 'mobile_money',
        'items': widget.items,
        'totalAmount': widget.totalAmount * 1.05,
        'quantity': widget.items.map((item) => (item['quantity'] ?? 1) as int).fold(0, (sum, quantity) => sum + quantity),
      };

      print('🔵 Writing order to Firestore: $orderData');
      final orderDoc = await FirebaseFirestore.instance.collection('orders').add(orderData);
      print('✅ Order written to Firestore');
      
      // Track order placement
      await AnalyticsService.trackOrderPlaced(
        orderId: orderDoc.id,
        buyerId: currentUser,
        amount: widget.totalAmount * 1.05,
      );
      
      // Also create a payment record
      await FirebaseFirestore.instance.collection('payments').add({
        'orderId': referenceId,
        'buyerId': currentUser,
        'amount': widget.totalAmount * 1.05,
        'paymentMethod': 'mobile_money',
        'status': 'completed',
        'paymentDate': Timestamp.now(),
        'referenceId': referenceId,
        'phoneNumber': _phoneController.text.trim(),
      });
      print('✅ Payment written to Firestore');
    } catch (e) {
      // Handle order creation error
      print('❌ Error creating order: $e');
      rethrow;
    }
  }
} 