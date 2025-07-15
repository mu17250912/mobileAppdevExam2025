import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/user_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'Pay on Delivery';
  bool _isPlacingOrder = false;
  String? _error;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'Pay on Delivery',
      'name': 'Pay on Delivery',
      'description': 'Pay when you receive your order',
      'icon': Icons.delivery_dining,
      'color': const Color(0xFF145A32),
    },
    {
      'id': 'Mobile Money',
      'name': 'Mobile Money',
      'description': 'Pay with MTN or Airtel Money',
      'icon': Icons.phone_android,
      'color': const Color(0xFF1ABC9C),
    },
    {
      'id': 'PayPal',
      'name': 'PayPal',
      'description': 'Pay with your PayPal account',
      'icon': Icons.payment,
      'color': const Color(0xFF0070BA),
    },
    {
      'id': 'Visa',
      'name': 'Visa',
      'description': 'Pay with Visa card',
      'icon': Icons.credit_card,
      'color': const Color(0xFF1A1F71),
    },
    {
      'id': 'American Express',
      'name': 'American Express',
      'description': 'Pay with American Express',
      'icon': Icons.credit_card,
      'color': const Color(0xFF006FCF),
    },
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _proceedToPayment() async {
    setState(() {
      _isPlacingOrder = true;
      _error = null;
    });

    // Check if user is logged in using UserService
    if (!UserService.isLoggedIn) {
      setState(() {
        _isPlacingOrder = false;
        _error = 'You must be logged in to place an order.';
      });
      return;
    }

    final cartService = CartService();
    final cartItems = cartService.cartItems;
    if (cartItems.isEmpty) {
      setState(() {
        _isPlacingOrder = false;
        _error = 'Your cart is empty.';
      });
      return;
    }

    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() {
        _isPlacingOrder = false;
        _error = 'Delivery address is required.';
      });
      return;
    }

    // Navigate to payment screen based on selected method
      if (mounted) {
      Navigator.of(context).push(
          MaterialPageRoute(
          builder: (_) => PaymentScreen(
            paymentMethod: _paymentMethod,
            cartItems: cartItems,
            totalAmount: cartService.totalAmount,
            deliveryAddress: address,
            notes: _notesController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();
    final cartItems = cartService.cartItems;
    final totalAmount = cartService.formattedTotalAmount;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF145A32),
        elevation: 0,
        title: const Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF145A32))),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Enter your delivery address',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.location_on, color: Color(0xFF145A32)),
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF145A32))),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: _paymentMethods.map((method) {
                  final isSelected = _paymentMethod == method['id'];
                  return InkWell(
                    onTap: () => setState(() => _paymentMethod = method['id']),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? method['color'].withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? method['color'] : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: method['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              method['icon'],
                              color: method['color'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected ? method['color'] : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  method['description'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: method['color'],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                  ),
                ),
              ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Order Notes (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF145A32))),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add any delivery notes... (e.g. call on arrival)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.note_alt_outlined, color: Color(0xFF145A32)),
              ),
              minLines: 1,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF145A32))),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = cartItems[i];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.product.image, width: 48, height: 48, fit: BoxFit.cover),
                    ),
                    title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('x${item.quantity}  •  ${item.product.formattedPrice}'),
                    trailing: Text('${(item.product.price * item.quantity).toStringAsFixed(0)} RWF', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(totalAmount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF145A32))),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF145A32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isPlacingOrder ? null : _proceedToPayment,
                child: _isPlacingOrder
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Proceed to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final String paymentMethod;
  final List<dynamic> cartItems;
  final double totalAmount;
  final String deliveryAddress;
  final String notes;

  const PaymentScreen({
    super.key,
    required this.paymentMethod,
    required this.cartItems,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.notes,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  String? _error;

  void _processPayment() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      final items = widget.cartItems.map((item) => {
        'productId': item.product.id,
        'name': item.product.name,
        'qty': item.quantity,
        'price': item.product.price,
        'image': item.product.image,
        'category': item.product.category,
      }).toList();

      final orderId = await OrderService().placeOrder(
        userId: UserService.userId!,
        items: items,
        totalAmount: widget.totalAmount,
        deliveryAddress: widget.deliveryAddress,
        paymentMethod: widget.paymentMethod,
        paymentStatus: widget.paymentMethod == 'Pay on Delivery' ? 'pending' : 'paid',
      );

      // Clear cart after successful order
      CartService().clearCart();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(orderId: orderId),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = 'Payment failed: $e';
      });
    }
  }

  Widget _buildPaymentForm() {
    switch (widget.paymentMethod) {
      case 'Pay on Delivery':
        return _buildPayOnDeliveryForm();
      case 'Mobile Money':
        return _buildMobileMoneyForm();
      case 'PayPal':
        return _buildPayPalForm();
      case 'Visa':
      case 'American Express':
        return _buildCreditCardForm();
      default:
        return _buildPayOnDeliveryForm();
    }
  }

  Widget _buildPayOnDeliveryForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF145A32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF145A32)),
      ),
      child: Column(
        children: [
          const Icon(Icons.delivery_dining, color: Color(0xFF145A32), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Pay on Delivery',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF145A32)),
          ),
          const SizedBox(height: 8),
          const Text(
            'You will pay when you receive your order. No payment required now.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMoneyForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1ABC9C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1ABC9C)),
      ),
      child: Column(
        children: [
          const Icon(Icons.phone_android, color: Color(0xFF1ABC9C), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Mobile Money Payment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1ABC9C)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {},
                  child: const Text('MTN Money'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {},
                  child: const Text('Airtel Money'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayPalForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0070BA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0070BA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.payment, color: Color(0xFF0070BA), size: 48),
          const SizedBox(height: 16),
          const Text(
            'PayPal Payment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0070BA)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'PayPal Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'PayPal Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F71).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1F71)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.credit_card,
            color: widget.paymentMethod == 'Visa' ? const Color(0xFF1A1F71) : const Color(0xFF006FCF),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.paymentMethod} Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.paymentMethod == 'Visa' ? const Color(0xFF1A1F71) : const Color(0xFF006FCF),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Card Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    border: OutlineInputBorder(),
                    hintText: 'MM/YY',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF145A32),
        elevation: 0,
        title: Text('${widget.paymentMethod} Payment', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF145A32))),
            const SizedBox(height: 16),
            _buildPaymentForm(),
            const SizedBox(height: 24),
            const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF145A32))),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.cartItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = widget.cartItems[i];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.product.image, width: 48, height: 48, fit: BoxFit.cover),
                    ),
                    title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('x${item.quantity}  •  ${item.product.formattedPrice}'),
                    trailing: Text('${(item.product.price * item.quantity).toStringAsFixed(0)} RWF', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('${widget.totalAmount.toStringAsFixed(0)} RWF', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF145A32))),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF145A32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isProcessing ? null : _processPayment,
                child: _isProcessing
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Complete Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF145A32),
        elevation: 0,
        title: const Text('Order Placed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF145A32), size: 80),
              const SizedBox(height: 24),
              const Text('Thank you for your order!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF145A32))),
              const SizedBox(height: 12),
              const Text('Your order has been placed successfully. You can track your order status in the Orders section.',
                style: TextStyle(color: Colors.black54, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF145A32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Navigate directly to home screen
                    context.go('/home');
                  },
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 