import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'success_screen.dart';
import 'booking_store.dart';
import 'package:provider/provider.dart';
import 'providers/subscription_provider.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const PaymentScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String paymentMethod = 'Cash';
  bool _isLoading = false;
  String paymentNumber = '';
  String? _paymentNumberError;
  final TextEditingController _paymentNumberController = TextEditingController();

  @override
  void dispose() {
    _paymentNumberController.dispose();
    super.dispose();
  }

  // Validate card number using Luhn algorithm
  bool _isValidCardNumber(String cardNumber) {
    // Remove spaces and dashes
    String cleanNumber = cardNumber.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Check if it's a valid length (13-19 digits)
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }
    
    // Check if it contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleanNumber)) {
      return false;
    }
    
    // Luhn algorithm
    int sum = 0;
    bool isEven = false;
    
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      
      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      
      sum += digit;
      isEven = !isEven;
    }
    
    return sum % 10 == 0;
  }

  // Validate mobile money number for Rwanda
  bool _isValidMobileMoneyNumber(String number) {
    // Remove spaces, dashes, and plus signs
    String cleanNumber = number.replaceAll(RegExp(r'[\s\-\+]'), '');
    
    // Check if it starts with country code or local format
    if (cleanNumber.startsWith('250')) {
      // Remove country code for validation
      cleanNumber = cleanNumber.substring(3);
    }
    
    // Rwandan mobile numbers should be 9 digits starting with 7
    if (cleanNumber.length != 9 || !cleanNumber.startsWith('7')) {
      return false;
    }
    
    // Check if it contains only digits
    return RegExp(r'^\d+$').hasMatch(cleanNumber);
  }

  // Format card number with spaces
  String _formatCardNumber(String input) {
    // Remove all non-digits
    String digits = input.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add spaces every 4 digits
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += digits[i];
    }
    
    return formatted;
  }

  // Format mobile number
  String _formatMobileNumber(String input) {
    // Remove all non-digits
    String digits = input.replaceAll(RegExp(r'[^\d]'), '');
    
    // If it starts with 250, format as international
    if (digits.startsWith('250') && digits.length >= 12) {
      return '+${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)} ${digits.substring(9)}';
    }
    
    // If it's 9 digits starting with 7, format as local
    if (digits.length == 9 && digits.startsWith('7')) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    
    return digits;
  }

  void _validatePaymentNumber(String value) {
    setState(() {
      paymentNumber = value;
      _paymentNumberError = null;
      
      if (value.isEmpty) {
        return;
      }
      
      if (paymentMethod == 'Card') {
        if (!_isValidCardNumber(value)) {
          _paymentNumberError = 'Please enter a valid card number';
        }
      } else if (paymentMethod == 'Mobile Money') {
        if (!_isValidMobileMoneyNumber(value)) {
          _paymentNumberError = 'Please enter a valid mobile number (e.g., 0781234567)';
        }
      }
    });
  }

  void _payNow() async {
    // Validate payment number if required
    if (paymentMethod == 'Card' || paymentMethod == 'Mobile Money') {
      if (paymentNumber.isEmpty) {
        setState(() {
          _paymentNumberError = 'Please enter your ${paymentMethod == 'Card' ? 'card' : 'mobile'} number';
        });
        return;
      }
      
      if (_paymentNumberError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_paymentNumberError!)),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    
    try {
      // Mock payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Update booking status to confirmed
      final booking = await BookingStore.getBookingById(widget.booking['id']);
      if (booking != null) {
        final updatedBooking = booking.copyWith(
          status: 'confirmed',
          paymentMethod: paymentMethod,
          paymentNumber: paymentNumber.isEmpty ? null : paymentNumber,
          updatedAt: DateTime.now(),
        );
        
        await BookingStore.updateBooking(updatedBooking);
      }
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessScreen(
            receipt: {
              ...widget.booking,
              'paymentMethod': paymentMethod,
              'paymentNumber': paymentNumber,
              'status': 'confirmed',
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final hasPremium = subscriptionProvider.isSubscribed;
    final discountPercentage = subscriptionProvider.discountPercentage;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Summary Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Summary',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Car:', '${widget.booking['carBrand']} ${widget.booking['carModel']}'),
                      _buildSummaryRow('Dates:', '${widget.booking['startDate']} to ${widget.booking['endDate']}'),
                      _buildSummaryRow('Pickup:', widget.booking['pickupLocation']),
                      _buildSummaryRow('Drop-off:', widget.booking['dropoffLocation']),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        hasPremium ? 'Total (${discountPercentage.toInt()}% off):' : 'Total:',
                        hasPremium
                            ? '${((widget.booking['totalPrice'] as num) * (1 - discountPercentage / 100)).toStringAsFixed(0)} RWF'
                            : '${widget.booking['totalPrice']} RWF',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (hasPremium)
                Card(
                  color: Colors.green[50],
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green[600]),
                    title: Text('Premium Discount Applied'),
                    subtitle: Text('You\'re saving ${discountPercentage.toInt()}% on this booking!'),
                  ),
                ),
              // Payment Method Selection
              const Text(
                'Choose Payment Method:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'Cash',
                      groupValue: paymentMethod,
                      onChanged: (v) => setState(() {
                        paymentMethod = v!;
                        paymentNumber = '';
                        _paymentNumberError = null;
                        _paymentNumberController.clear();
                      }),
                      title: const Text('Cash'),
                      subtitle: const Text('Pay with cash on pickup'),
                    ),
                    RadioListTile<String>(
                      value: 'Card',
                      groupValue: paymentMethod,
                      onChanged: (v) => setState(() {
                        paymentMethod = v!;
                        paymentNumber = '';
                        _paymentNumberError = null;
                        _paymentNumberController.clear();
                      }),
                      title: const Text('Card'),
                      subtitle: const Text('Credit or debit card'),
                    ),
                    RadioListTile<String>(
                      value: 'Mobile Money',
                      groupValue: paymentMethod,
                      onChanged: (v) => setState(() {
                        paymentMethod = v!;
                        paymentNumber = '';
                        _paymentNumberError = null;
                        _paymentNumberController.clear();
                      }),
                      title: const Text('Mobile Money'),
                      subtitle: const Text('MTN, Airtel, or other mobile money'),
                    ),
                  ],
                ),
              ),
              
              // Payment Number Input
              if (paymentMethod == 'Card' || paymentMethod == 'Mobile Money') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _paymentNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(paymentMethod == 'Card' ? 19 : 12),
                  ],
                  decoration: InputDecoration(
                    labelText: paymentMethod == 'Card' ? 'Card Number' : 'Mobile Number',
                    hintText: paymentMethod == 'Card' 
                        ? '1234 5678 9012 3456' 
                        : '078 123 4567',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _paymentNumberError,
                    prefixIcon: Icon(
                      paymentMethod == 'Card' ? Icons.credit_card : Icons.phone,
                    ),
                  ),
                  onChanged: (value) {
                    String formattedValue;
                    if (paymentMethod == 'Card') {
                      formattedValue = _formatCardNumber(value);
                    } else {
                      formattedValue = _formatMobileNumber(value);
                    }
                    
                    // Update controller if formatting changed the value
                    if (formattedValue != value) {
                      _paymentNumberController.value = TextEditingValue(
                        text: formattedValue,
                        selection: TextSelection.collapsed(offset: formattedValue.length),
                      );
                    }
                    
                    _validatePaymentNumber(formattedValue);
                  },
                ),
              ],
              
              SizedBox(height: 24),
              
              // Pay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _payNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Pay Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? const Color(0xFF667eea) : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 18 : 16,
                color: isTotal ? const Color(0xFF667eea) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 