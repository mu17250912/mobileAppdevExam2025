import 'package:flutter/material.dart';
import 'session_manager.dart';
import 'user_dashboard_screen.dart';
import 'products_screen.dart';
import 'services/firebase_service.dart'; // Add Firebase service import

class PaymentScreen extends StatefulWidget {
  final String orderId;

  const PaymentScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'Mobile Money';
  String selectedMobileMoney = 'MTN Mobile Money';
  String phoneNumber = '';
  bool isLoading = false;
  Map<String, dynamic>? orderDetails;
  List<Map<String, dynamic>> orderItems = [];
  double calculatedTotal = 0.0;
  double paymentAmount = 0.0;
  bool useCustomAmount = false;
  final TextEditingController _amountController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  final List<String> paymentMethods = [
    'Mobile Money',
    'Airtel Money',
    'Bank Transfer',
    'Cash on Delivery',
  ];

  final List<String> mobileMoneyProviders = [
    'MTN Mobile Money',
    'Airtel Money',
    'M-Pesa',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final order = await _firebaseService.getOrder(widget.orderId);
      if (order != null) {
        setState(() {
          orderDetails = order;
          orderItems = List<Map<String, dynamic>>.from(order['items'] ?? []);
          calculatedTotal = (order['total'] ?? 0.0).toDouble();
          paymentAmount = calculatedTotal;
          _amountController.text = calculatedTotal.toStringAsFixed(0);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order not found')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading order details: $e')),
      );
    }
  }

  void _updatePaymentAmount(String value) {
    if (value.isEmpty) {
      setState(() {
        paymentAmount = 0.0;
      });
      return;
    }
    
    final amount = double.tryParse(value);
    if (amount != null) {
      setState(() {
        paymentAmount = amount;
      });
    }
  }

  void _toggleAmountType() {
    setState(() {
      useCustomAmount = !useCustomAmount;
      if (!useCustomAmount) {
        paymentAmount = calculatedTotal;
        _amountController.text = calculatedTotal.toStringAsFixed(0);
      }
    });
  }

  Future<void> _processPayment() async {
    if (paymentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount')),
      );
      return;
    }

    if (selectedPaymentMethod == 'Mobile Money' && phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Process payment using Firebase service
      final paymentData = {
        'amount': paymentAmount,
        'method': selectedPaymentMethod,
        'phone_number': phoneNumber.isNotEmpty ? phoneNumber : null,
        'mobile_money_provider': selectedPaymentMethod == 'Mobile Money' ? selectedMobileMoney : null,
      };

      await _firebaseService.processPayment(widget.orderId, paymentData);

      // Add payment success notification for the user
      final userId = SessionManager().userId;
      if (userId != null) {
        await _firebaseService.createNotification({
          'type': 'payment',
          'orderId': widget.orderId,
          'userId': userId.toString(),
          'message': 'Payment of RWF ${paymentAmount.toStringAsFixed(0)} successful for order #${widget.orderId}',
        });

        // Add admin notification
        await _firebaseService.createNotification({
          'type': 'payment_received',
          'orderId': widget.orderId,
          'userId': userId.toString(),
          'message': 'Payment received: RWF ${paymentAmount.toStringAsFixed(0)} for order #${widget.orderId}',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of RWF ${paymentAmount.toStringAsFixed(0)} processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Thank You screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ThankYouScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (orderDetails == null) {
      return const Scaffold(
        body: Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.dashboard),
            tooltip: 'Back to Dashboard',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
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

                    // Order items
                    ...orderItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['name'] ?? 'Unknown Product',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '${item['quantity']} x RWF ${(item['price'] ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    )),

                    const Divider(),

                    // Calculated Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Calculated Total:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'RWF ${calculatedTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Amount Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: useCustomAmount,
                          onChanged: (value) => _toggleAmountType(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      useCustomAmount ? 'Enter Custom Amount' : 'Use Calculated Total',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (useCustomAmount) ...[
                      TextField(
                        controller: _amountController,
                        onChanged: _updatePaymentAmount,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Enter Amount (RWF)',
                          hintText: 'Enter payment amount',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_money, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              'RWF ${calculatedTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Final Payment Amount Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1976D2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Final Payment Amount:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'RWF ${paymentAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment method selection
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...paymentMethods.map((method) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(
                      _getPaymentIcon(method),
                      color: const Color(0xFF1976D2),
                    ),
                    const SizedBox(width: 12),
                    Text(method),
                  ],
                ),
                value: method,
                groupValue: selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                  });
                },
              ),
            )),

            const SizedBox(height: 24),

            // Payment details
            if (selectedPaymentMethod == 'Mobile Money') ...[
              const Text(
                'Mobile Money Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Mobile money provider selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Provider',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...mobileMoneyProviders.map((provider) => RadioListTile<String>(
                        title: Text(provider),
                        value: provider,
                        groupValue: selectedMobileMoney,
                        onChanged: (value) {
                          setState(() {
                            selectedMobileMoney = value!;
                          });
                        },
                      )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Phone number input
              TextField(
                onChanged: (value) {
                  setState(() {
                    phoneNumber = value;
                  });
                },
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
            ],

            if (selectedPaymentMethod == 'Bank Transfer') ...[
              const Text(
                'Bank Transfer Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bank: Farmer Pay Bank',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Account Number: 1234567890'),
                      const SizedBox(height: 8),
                      const Text('Account Name: Farmer Pay Ltd'),
                      const SizedBox(height: 8),
                      Text('Reference: Order #${widget.orderId}'),
                      const SizedBox(height: 8),
                      Text('Amount: RWF ${paymentAmount.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              ),
            ],

            if (selectedPaymentMethod == 'Cash on Delivery') ...[
              const Text(
                'Cash on Delivery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pay with cash when your order is delivered.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Amount to pay: RWF ${paymentAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Our delivery team will contact you to arrange delivery.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        'Pay RWF ${paymentAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Mobile Money':
        return Icons.phone_android;
      case 'Airtel Money':
        return Icons.phone_android;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'Cash on Delivery':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }
}

class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thank You!'),
        backgroundColor: const Color(0xFF1976D2),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.dashboard),
            tooltip: 'Back to Dashboard',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thank you for your purchase. Your order has been placed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.dashboard),
                label: const Text('Return to Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const ProductsScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Browse More Products'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 