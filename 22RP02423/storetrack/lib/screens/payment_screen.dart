import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sales_service.dart';
import '../services/auth_service.dart';
import '../models/sale_model.dart';
import '../widgets/common_widgets.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  
  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;
  double _amountReceived = 0.0;
  double _change = 0.0;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'name': 'Cash', 'icon': Icons.money},
    {'id': 'card', 'name': 'Card', 'icon': Icons.credit_card},
    {'id': 'mobile_money', 'name': 'Mobile Money', 'icon': Icons.phone_android},
    {'id': 'bank_transfer', 'name': 'Bank Transfer', 'icon': Icons.account_balance},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateChange();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final salesService = Provider.of<SalesService>(context, listen: false);
    _change = _amountReceived - salesService.cartTotal;
    setState(() {});
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final salesService = Provider.of<SalesService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Create sale object
      final sale = SaleModel(
        id: '',
        items: salesService.currentCart,
        total: salesService.cartTotal,
        tax: salesService.cartTax,
        subtotal: salesService.cartSubtotal,
        cashierName: authService.currentUser?.name ?? 'Unknown',
        cashierId: authService.currentUser?.id ?? '',
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        customerEmail: _customerEmailController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
        amountReceived: _amountReceived,
        change: _change,
        createdAt: DateTime.now(),
      );

      final success = await salesService.completeSale(sale);

      if (success && mounted) {
        // Show success dialog
        await _showSuccessDialog();
        
        // Navigate back to sales interface
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacementNamed(context, '/sales-interface');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process payment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    final salesService = Provider.of<SalesService>(context, listen: false);
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: \$${salesService.cartTotal.toStringAsFixed(2)}'),
            Text('Payment Method: ${_paymentMethods.firstWhere((m) => m['id'] == _selectedPaymentMethod)['name']}'),
            if (_selectedPaymentMethod == 'cash') ...[
              Text('Amount Received: \$${_amountReceived.toStringAsFixed(2)}'),
              Text('Change: \$${_change.toStringAsFixed(2)}'),
            ],
            const SizedBox(height: 16),
            const Text('Receipt has been generated and saved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SalesService>(
        builder: (context, salesService, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  _buildOrderSummary(salesService),
                  
                  const SizedBox(height: 24),
                  
                  // Customer Information
                  _buildCustomerSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Payment Method
                  _buildPaymentMethodSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Amount Received (for cash payments)
                  if (_selectedPaymentMethod == 'cash') ...[
                    _buildAmountReceivedSection(salesService),
                    const SizedBox(height: 24),
                  ],
                  
                  // Complete Payment Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00b894),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Complete Payment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(SalesService salesService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...salesService.currentCart.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName} x${item.quantity}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text('\$${salesService.cartSubtotal.toStringAsFixed(2)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax (10%):'),
                Text('\$${salesService.cartTax.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '\$${salesService.cartTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF667eea),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Customer Name',
              hint: 'Enter customer name',
              controller: _customerNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Phone Number',
              hint: 'Enter phone number',
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email (Optional)',
              hint: 'Enter email address',
              controller: _customerEmailController,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._paymentMethods.map((method) => RadioListTile<String>(
              title: Row(
                children: [
                  Icon(method['icon']),
                  const SizedBox(width: 12),
                  Text(method['name']),
                ],
              ),
              value: method['id'],
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                  if (value != 'cash') {
                    _amountReceived = 0.0;
                    _change = 0.0;
                  }
                });
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountReceivedSection(SalesService salesService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cash Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Amount Received',
              hint: '0.00',
              controller: TextEditingController(
                text: _amountReceived > 0 ? _amountReceived.toString() : '',
              ),
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.attach_money),
              onChanged: (value) {
                setState(() {
                  _amountReceived = double.tryParse(value) ?? 0.0;
                  _calculateChange();
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount received';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < salesService.cartTotal) {
                  return 'Amount must be at least \$${salesService.cartTotal.toStringAsFixed(2)}';
                }
                return null;
              },
            ),
            if (_change >= 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Change:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${_change.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 