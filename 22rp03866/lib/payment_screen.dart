import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final double totalPrice;
  const PaymentScreen({super.key, required this.totalPrice});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = '';
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cardController = TextEditingController();

  Future<bool> _simulatePayment() async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Choose Payment Method',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payment, size: 48, color: theme.iconTheme.color),
                const SizedBox(height: 18),
                Text(
                  'Amount to Pay',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ' 4${widget.totalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                RadioListTile<String>(
                  value: 'mobile',
                  groupValue: _selectedMethod,
                  onChanged: (val) => setState(() => _selectedMethod = val!),
                  title: Text('Pay with Mobile Money', style: theme.textTheme.bodyMedium),
                  secondary: Icon(Icons.phone_android, color: theme.iconTheme.color),
                ),
                RadioListTile<String>(
                  value: 'card',
                  groupValue: _selectedMethod,
                  onChanged: (val) => setState(() => _selectedMethod = val!),
                  title: Text('Pay with Card', style: theme.textTheme.bodyMedium),
                  secondary: Icon(Icons.credit_card, color: theme.iconTheme.color),
                ),
                RadioListTile<String>(
                  value: 'paypal',
                  groupValue: _selectedMethod,
                  onChanged: (val) => setState(() => _selectedMethod = val!),
                  title: Text('Pay with PayPal', style: theme.textTheme.bodyMedium),
                  secondary: Icon(Icons.account_balance_wallet, color: Color(0xFF003087)),
                ),
                if (_selectedMethod == 'mobile') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'e.g. 07XXXXXXXX',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary),
                    ),
                  ),
                ],
                if (_selectedMethod == 'card') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cardController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Card Number',
                      hintText: 'e.g. 1234 5678 9012 3456',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.credit_card, color: theme.colorScheme.primary),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _selectedMethod.isEmpty
                      ? null
                      : () async {
                          bool paymentSuccess = await _simulatePayment();
                          if (paymentSuccess) {
                            Navigator.pop(context, true);
                          } else {
                            Navigator.pop(context, false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 2,
                  ),
                  child: Text(_selectedMethod.isEmpty ? 'Select Payment Method' : 'Pay'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 