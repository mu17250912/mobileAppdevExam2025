import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/payment_service.dart';
import '../services/error_service.dart';
import '../services/auth_service.dart';
import '../widgets/error_message.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String description;
  final String? rideId;
  final String? bookingId;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    this.rideId,
    this.bookingId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardNameController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  final ErrorService _errorService = ErrorService();

  String _selectedPaymentMethod = 'mtn_mobile_money';
  bool _isLoading = false;
  String? _error;
  bool _showCardDetails = false;
  bool _isProcessing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Get current user ID
      final currentUser = await AuthService().getCurrentUserModel();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Prepare metadata based on payment method
      final metadata = <String, dynamic>{
        'ride_id': widget.rideId,
        'booking_id': widget.bookingId,
        'user_id': currentUser.id,
        'user_name': currentUser.name,
        'user_email': currentUser.email,
      };

      if (_selectedPaymentMethod.contains('mobile_money') ||
          _selectedPaymentMethod.contains('money')) {
        metadata['phone_number'] = _phoneController.text.trim();
      } else if (_selectedPaymentMethod == 'card') {
        metadata['card_last4'] = _cardNumberController.text
            .substring(_cardNumberController.text.length - 4);
        metadata['card_holder'] = _cardNameController.text.trim();
      }

      final result = await _paymentService.processPayment(
        userId: currentUser.id,
        amount: widget.amount,
        currency: 'FRW',
        paymentMethod: _selectedPaymentMethod,
        description: widget.description,
        metadata: metadata,
      );

      if (result['success'] == true) {
        if (!mounted) return;

        // Show success animation
        _showSuccessDialog(result['transactionId'] ?? 'Unknown');
      } else {
        setState(() {
          _error = result['error'] ?? 'Payment failed';
        });
      }
    } catch (e) {
      _errorService.logError('Payment processing error', e);
      setState(() {
        _error = _errorService.getUserFriendlyErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSuccessDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Successful!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction ID: $transactionId',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your payment has been processed successfully. You will receive a confirmation shortly.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return '${amount.toStringAsFixed(0)} FRW (\$${(amount / 1000).toStringAsFixed(2)} USD)';
  }

  String _formatCardNumber(String text) {
    if (text.isEmpty) return text;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String text) {
    if (text.isEmpty) return text;
    if (text.length == 2 && !text.contains('/')) {
      return '$text/';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isProcessing,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPaymentSummary(),
                    const SizedBox(height: 24),
                    _buildPaymentMethods(),
                    const SizedBox(height: 24),
                    _buildPaymentDetails(),
                    const SizedBox(height: 24),
                    _buildErrorSection(),
                    const SizedBox(height: 24),
                    _buildPaymentButton(),
                    const SizedBox(height: 16),
                    _buildPaymentInstructions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade50,
              Colors.deepPurple.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.payment,
                    color: Colors.deepPurple.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSummaryRow('Amount', _formatAmount(widget.amount), true),
            const SizedBox(height: 8),
            _buildSummaryRow('Description', widget.description, false),
            const SizedBox(height: 8),
            _buildSummaryRow('Payment Method',
                _getPaymentMethodName(_selectedPaymentMethod), false),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isAmount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.deepPurple.shade600,
                fontWeight: FontWeight.w500,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
                  color: isAmount
                      ? Colors.deepPurple.shade700
                      : Colors.deepPurple.shade600,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodCard(
          'mtn_mobile_money',
          'MTN Mobile Money',
          'Pay with MTN Mobile Money',
          Icons.phone_android,
          Colors.orange,
          'Fast and secure mobile payments',
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodCard(
          'airtel_money',
          'Airtel Money',
          'Pay with Airtel Money',
          Icons.phone_android,
          Colors.red,
          'Convenient mobile money transfer',
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodCard(
          'mpesa',
          'M-Pesa',
          'Pay with M-Pesa',
          Icons.phone_android,
          Colors.green,
          'Kenya\'s leading mobile money',
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodCard(
          'card',
          'Credit/Debit Card',
          'Pay with card',
          Icons.credit_card,
          Colors.blue,
          'Visa, Mastercard, and more',
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    String value,
    String title,
    String subtitle,
    IconData icon,
    MaterialColor color,
    String description,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color.shade400 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Text(subtitle),
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (newValue) {
          setState(() {
            _selectedPaymentMethod = newValue!;
            _showCardDetails = newValue == 'card';
          });
        },
        activeColor: color.shade600,
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_selectedPaymentMethod.contains('mobile_money') ||
            _selectedPaymentMethod.contains('money') ||
            _selectedPaymentMethod == 'mpesa') ...[
          CustomTextField(
            controller: _phoneController,
            labelText: 'Phone Number',
            hintText: 'e.g., 0781234567',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.length < 9) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
        ] else if (_selectedPaymentMethod == 'card') ...[
          CustomTextField(
            controller: _cardNameController,
            labelText: 'Cardholder Name',
            hintText: 'Enter cardholder name',
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter cardholder name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _cardNumberController,
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            prefixIcon: Icons.credit_card,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter card number';
              }
              if (value.length < 16) {
                return 'Please enter a valid card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _expiryController,
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  prefixIcon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (value.length < 4) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _cvvController,
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon: Icons.security,
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
      ],
    );
  }

  Widget _buildErrorSection() {
    return ErrorMessage(
      error: _error,
      onRetry: _error != null
          ? () {
              setState(() {
                _error = null;
              });
            }
          : null,
    );
  }

  Widget _buildPaymentButton() {
    return CustomButton(
      text: 'Pay ${_formatAmount(widget.amount)}',
      onPressed: _isProcessing ? null : _processPayment,
      isLoading: _isProcessing,
      backgroundColor: Colors.deepPurple.shade600,
      textColor: Colors.white,
    );
  }

  Widget _buildPaymentInstructions() {
    final instructions = _getPaymentInstructions();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Instructions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            instructions,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'mtn_mobile_money':
        return 'MTN Mobile Money';
      case 'airtel_money':
        return 'Airtel Money';
      case 'mpesa':
        return 'M-Pesa';
      case 'card':
        return 'Credit/Debit Card';
      default:
        return 'Unknown';
    }
  }

  String _getPaymentInstructions() {
    switch (_selectedPaymentMethod) {
      case 'mtn_mobile_money':
        return '1. Enter your MTN phone number\n'
            '2. Click "Pay" to proceed\n'
            '3. You will receive a USSD prompt\n'
            '4. Enter your MTN Mobile Money PIN\n'
            '5. Confirm the payment';
      case 'airtel_money':
        return '1. Enter your Airtel phone number\n'
            '2. Click "Pay" to proceed\n'
            '3. You will receive a USSD prompt\n'
            '4. Enter your Airtel Money PIN\n'
            '5. Confirm the payment';
      case 'mpesa':
        return '1. Enter your M-Pesa phone number\n'
            '2. Click "Pay" to proceed\n'
            '3. You will receive an M-Pesa prompt\n'
            '4. Enter your M-Pesa PIN\n'
            '5. Confirm the payment';
      case 'card':
        return '1. Enter your card details\n'
            '2. Ensure your card is enabled for online payments\n'
            '3. Click "Pay" to proceed\n'
            '4. Complete 3D Secure if prompted\n'
            '5. Wait for payment confirmation';
      default:
        return 'Please follow the instructions provided by your payment method.';
    }
  }
}
