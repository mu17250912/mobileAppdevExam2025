import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'premium_features_summary.dart';
import 'payment_verification_screen.dart';

enum MobileMoneyProvider {
  mtn,
  airtel,
}

class MobileMoneyPaymentScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final double amount;
  final String currency;

  const MobileMoneyPaymentScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.amount,
    required this.currency,
  });

  @override
  State<MobileMoneyPaymentScreen> createState() => _MobileMoneyPaymentScreenState();
}

class _MobileMoneyPaymentScreenState extends State<MobileMoneyPaymentScreen> {
  MobileMoneyProvider _selectedProvider = MobileMoneyProvider.mtn;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _getProviderName(MobileMoneyProvider provider) {
    switch (provider) {
      case MobileMoneyProvider.mtn:
        return 'MTN Mobile Money';
      case MobileMoneyProvider.airtel:
        return 'Airtel Money';
    }
  }

  String _getProviderShortName(MobileMoneyProvider provider) {
    switch (provider) {
      case MobileMoneyProvider.mtn:
        return 'MTN';
      case MobileMoneyProvider.airtel:
        return 'Airtel';
    }
  }

  Color _getProviderColor(MobileMoneyProvider provider) {
    switch (provider) {
      case MobileMoneyProvider.mtn:
        return const Color(0xFFFFC107); // MTN Yellow
      case MobileMoneyProvider.airtel:
        return const Color(0xFFE91E63); // Airtel Red
    }
  }

  String _getProviderPrefix(MobileMoneyProvider provider) {
    switch (provider) {
      case MobileMoneyProvider.mtn:
        return '+250'; // Rwanda MTN prefix
      case MobileMoneyProvider.airtel:
        return '+250'; // Rwanda Airtel prefix
    }
  }

  bool _isValidPhoneNumber(String phone) {
    // Remove any non-digit characters
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid Rwanda mobile number
    if (cleanPhone.startsWith('250')) {
      return cleanPhone.length == 12; // +250 + 9 digits
    } else if (cleanPhone.startsWith('0')) {
      return cleanPhone.length == 10; // 0 + 9 digits
    } else if (cleanPhone.length == 9) {
      return true; // 9 digits starting with 7 or 8
    }
    
    return false;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create payment record
      final paymentRef = await FirebaseFirestore.instance.collection('mobile_money_payments').add({
        'userId': user.uid,
        'productId': widget.productId,
        'productName': widget.productName,
        'amount': widget.amount,
        'currency': widget.currency,
        'provider': _selectedProvider.name,
        'phoneNumber': _phoneController.text.trim(),
        'customerName': _nameController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'paymentMethod': 'mobile_money',
      });

      // Show payment instructions
      if (mounted) {
        _showPaymentInstructions(paymentRef.id);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initiation failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _completePayment(String paymentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Processing your payment...',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ],
            ),
          );
        },
      );

      // Update payment status to completed
      await FirebaseFirestore.instance.collection('mobile_money_payments').doc(paymentId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'verifiedBy': user.uid,
      });

      // Grant premium access
      final premiumManager = PremiumFeaturesManager();
      await premiumManager.grantPremiumAccess('mobile_money', paymentId);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Payment Successful!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your payment of ${widget.amount.toStringAsFixed(0)} ${widget.currency} has been processed successfully!',
                    style: GoogleFonts.poppins(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You now have 30 days of premium access. Enjoy all the premium features!',
                    style: GoogleFonts.poppins(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close success dialog
                    Navigator.of(context).pop(); // Close payment screen
                    Navigator.of(context).pop(); // Close premium screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      }

    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing payment: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showPaymentInstructions(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.payment,
                color: _getProviderColor(_selectedProvider),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Payment Instructions',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To complete your payment via ${_getProviderName(_selectedProvider)}:',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 16),
              
              // Payment Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInstructionRow('Amount', '${widget.amount.toStringAsFixed(0)} ${widget.currency}'),
                    _buildInstructionRow('Product', widget.productName),
                    _buildInstructionRow('Phone', _phoneController.text.trim()),
                    _buildInstructionRow('Provider', _getProviderName(_selectedProvider)),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Follow these steps:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildStepItem('1', 'Dial *182*8*1# for MTN or *185*8*1# for Airtel'),
              _buildStepItem('2', 'Select "Send Money"'),
              _buildStepItem('3', 'Enter recipient number: ${_phoneController.text.trim()}'),
              _buildStepItem('4', 'Enter amount: ${widget.amount.toStringAsFixed(0)} ${widget.currency}'),
              _buildStepItem('5', 'Enter your PIN to confirm'),
              _buildStepItem('6', 'Wait for confirmation SMS'),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment will be verified within 5-10 minutes. You\'ll receive a confirmation email once processed.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close payment screen
              },
              child: Text(
                'I\'ll Pay Later',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showPaymentTracking(paymentId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getProviderColor(_selectedProvider),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'I\'ve Made Payment',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showVerificationOptions(String paymentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.verified_user,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Verify Payment',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How would you like to verify your payment?',
                style: GoogleFonts.poppins(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Option 1: With transaction details
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaymentVerificationScreen(
                          paymentId: paymentId,
                          productName: widget.productName,
                          amount: widget.amount,
                          currency: widget.currency,
                          provider: _selectedProvider.name,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.receipt),
                  label: Text(
                    'With Transaction Details',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Option 2: Direct completion
              Container(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _completePayment(paymentId);
                  },
                  icon: Icon(Icons.check_circle),
                  label: Text(
                    'Complete Directly',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentTracking(String paymentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.track_changes,
                color: Theme.of(context).colorScheme.secondary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Track Payment',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your payment is being processed. You can track the status in your payment history.',
                style: GoogleFonts.poppins(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Payment ID',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    Text(
                      paymentId,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close payment screen
              },
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showVerificationOptions(paymentId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'I\'ve Made Payment',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String step, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _getProviderColor(_selectedProvider),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Mobile Money Payment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Summary',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow('Product', widget.productName),
                          _buildSummaryRow('Amount', '${widget.amount.toStringAsFixed(0)} ${widget.currency}'),
                          _buildSummaryRow('Payment Method', 'Mobile Money'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Mobile Money Provider Selection
                    Text(
                      'Select Mobile Money Provider',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // MTN Mobile Money
                    _buildProviderCard(
                      MobileMoneyProvider.mtn,
                      'MTN Mobile Money',
                      'assets/mtn_logo.png', // You'll need to add this asset
                      'Fast and secure payments via MTN',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Airtel Money
                    _buildProviderCard(
                      MobileMoneyProvider.airtel,
                      'Airtel Money',
                      'assets/airtel_logo.png', // You'll need to add this asset
                      'Convenient payments via Airtel',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Phone Number Input
                    Text(
                      'Phone Number',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter your ${_getProviderShortName(_selectedProvider)} number',
                        prefixText: _getProviderPrefix(_selectedProvider) + ' ',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(
                          Icons.phone,
                          color: _getProviderColor(_selectedProvider),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (!_isValidPhoneNumber(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Customer Name Input
                    Text(
                      'Full Name',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(
                          Icons.person,
                          color: _getProviderColor(_selectedProvider),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Pay Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getProviderColor(_selectedProvider),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Pay ${widget.amount.toStringAsFixed(0)} ${widget.currency}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(
    MobileMoneyProvider provider,
    String title,
    String logoPath,
    String description,
  ) {
    final isSelected = _selectedProvider == provider;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProvider = provider;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? _getProviderColor(provider).withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? _getProviderColor(provider)
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getProviderColor(provider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getProviderShortName(provider),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: _getProviderColor(provider),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
} 