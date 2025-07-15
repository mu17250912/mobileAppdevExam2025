import 'package:flutter/material.dart';
import 'custom_top_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatefulWidget {
  final String? userEmail;
  const PaymentScreen({Key? key, this.userEmail}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController nameController = TextEditingController(
    text: 'Enter Name',
  );
  final TextEditingController amountController = TextEditingController();
  bool saveDetails = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  void _payNow() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    String cardNumber = cardNumberController.text.trim();
    String expiry = expiryController.text.trim();
    String cvv = cvvController.text.trim();
    String name = nameController.text.trim();
    String amount = amountController.text.trim();
    if (name.isEmpty || cardNumber.isEmpty || expiry.isEmpty || cvv.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    if (cardNumber.replaceAll(' ', '').length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card number must be 16 digits.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    // Store payment data in Firestore
    try {
      await FirebaseFirestore.instance.collection('payments').add({
        'cardholderName': name,
        'cardNumber': cardNumber,
        'expiry': expiry,
        'cvv': cvv,
        'amount': amount,
        'saveDetails': saveDetails,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await Future.delayed(const Duration(seconds: 3));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful and stored!')),
      );
      // Clear all fields and reset form
      cardNumberController.clear();
      expiryController.clear();
      cvvController.clear();
      nameController.clear();
      amountController.clear();
      setState(() {
        saveDetails = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to store payment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomTopBar(pageName: 'Payment', userEmail: widget.userEmail),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: 40,
              right: 60,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 5,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 40,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 4,
                  ),
                ),
              ),
            ),
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final isMobile = constraints.maxWidth < 400;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 8 : 32,
                      horizontal: isMobile ? 4 : 0,
                    ),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 700),
                      padding: const EdgeInsets.all(0),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: _buildCardPreview(isMobile: false),
                                ),
                                const SizedBox(width: 40),
                                Flexible(
                                  flex: 2,
                                  child: _buildPaymentForm(isMobile: false),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildCardPreview(isMobile: isMobile),
                                _buildPaymentForm(isMobile: isMobile),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview({bool isMobile = false}) {
    return Center(
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: isMobile ? 180 : 240,
          height: isMobile ? 100 : 140,
          margin: EdgeInsets.only(bottom: isMobile ? 16 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF36D1C4), Color(0xFF1EAAF1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 20,
                top: 20,
                child: Container(
                  width: isMobile ? 24 : 36,
                  height: isMobile ? 18 : 28,
                  decoration: BoxDecoration(
                    color: Colors.amber[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                top: 20,
                child: Text(
                  'Bank Cards',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 22,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: isMobile ? 28 : 40,
                child: Row(
                  children: List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '••••',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 12 : 18,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: isMobile ? 8 : 18,
                child: Text(
                  '01 / 04',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 10 : 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm({bool isMobile = false}) {
    return Form(
      key: _formKey,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: isMobile ? double.infinity : 420,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 32,
            vertical: isMobile ? 16 : 32,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Payment Details',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount to Pay'),
              ),
              SizedBox(height: isMobile ? 10 : 18),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Cardholder Name'),
              ),
              SizedBox(height: isMobile ? 10 : 18),
              TextField(
                controller: cardNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  suffixIcon: Icon(Icons.check_circle, color: Colors.green),
                ),
              ),
              SizedBox(height: isMobile ? 10 : 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: 'Expiration Date',
                        hintText: 'MM / YY',
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 16),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        suffixIcon: Icon(Icons.help_outline),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 18),
              Row(
                children: [
                  Checkbox(
                    value: saveDetails,
                    onChanged: (val) {
                      setState(() {
                        saveDetails = val ?? false;
                      });
                    },
                  ),
                  Flexible(
                    child: Text(
                      'Save my details for future payments',
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 16 : 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _payNow,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 18),
                    backgroundColor: Color(0xFF2575FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                  ),
                  icon: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Processing...' : 'Pay Now',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
}
