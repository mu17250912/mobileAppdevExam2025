import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import '../services/subscription_service.dart';

class PaymentScreen extends StatefulWidget {
  final VoidCallback onPaymentSuccess;
  
  const PaymentScreen({super.key, required this.onPaymentSuccess});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with TickerProviderStateMixin {
  // Add missing fields
  final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
  final Color accentColor = const Color(0xFFFF6B35); // Orange
  final Color successColor = const Color(0xFF4CAF50); // Green

  late AnimationController _animationController;
  late AnimationController _successController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isProcessing = false;
  bool _isSuccess = false;
  String _selectedPaymentMethod = 'card';

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildSuccessView() {
    return AnimatedBuilder(
      animation: _successController,
      builder: (context, child) {
        return Container(
          color: successColor.withOpacity(0.1),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 0.5 + (_successController.value * 0.5),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: successColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '${AppLocalizations.of(context)!.paymentSuccessful} 🎉',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${AppLocalizations.of(context)!.paymentSuccessful}\n${AppLocalizations.of(context)!.reportsAccessGranted}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacementNamed(
                      context,
                      '/reports',
                      arguments: {'initialTabIndex': 2, 'forcePremium': true}, // 2 = Stock tab, force premium
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(AppLocalizations.of(context)!.viewReports),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processPayment() async {
    setState(() {
      _isProcessing = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });
    _successController.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      widget.onPaymentSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reportsPayment),
        backgroundColor: mainColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 420),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _isSuccess ? _buildSuccessView() : _buildPaymentForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [mainColor, accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.star, size: 48, color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Unlock Premium Reports & Analytics',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Pay 5,000 RWF to access advanced business insights, analytics, and premium features.',
                          style: TextStyle(fontSize: 15, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Only 5,000 RWF',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Choose Payment Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentOption(
                          'card',
                          'Credit/Debit Card',
                          Icons.credit_card,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildPaymentOption(
                          'mobile_money',
                          'Mobile Money',
                          Icons.phone_android,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  if (_selectedPaymentMethod == 'card') ...[
                    _buildTextField(
                      controller: _nameController,
                      label: 'Cardholder Name',
                      icon: Icons.person,
                      hint: 'e.g. Shallon',
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _cardNumberController,
                      label: 'Card Number',
                      icon: Icons.credit_card,
                      hint: '4242 4242 4242 4242',
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _expiryController,
                            label: 'Expiry (MM/YY)',
                            icon: Icons.calendar_today,
                            hint: '12/25',
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _cvvController,
                            label: 'CVV',
                            icon: Icons.security,
                            hint: '123',
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildTextField(
                      controller: _nameController,
                      label: 'Account Holder Name',
                      icon: Icons.person,
                      hint: 'e.g. Shallon',
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      hint: '07XXXXXXXX',
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This is a mobile money simulation. Use any 10-digit Rwandan phone number.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Processing...'),
                              ],
                            )
                          : Text(
                              'Pay 5,000 RWF',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'By proceeding, you agree to our Terms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? mainColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? mainColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: mainColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mainColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}