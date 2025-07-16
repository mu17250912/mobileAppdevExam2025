import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/book.dart';
import 'payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../notifications/notification_screen.dart';
import 'dart:ui';

class PaymentPage extends StatefulWidget {
  final Book book;
  const PaymentPage({Key? key, required this.book}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _telController = TextEditingController();
  String _statusMessage = '';
  bool _isLoading = false;
  String? _txRef;
  bool _isPolling = false;
  String _userPrompt = '';
  bool _showRefresh = false;
  DateTime? _pollStartTime;
  bool _agreedToPhoneWarning = false;

  @override
  void initState() {
    super.initState();
    // Show the blur modal after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPhoneWarningModal();
    });
  }

  void _showPhoneWarningModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 56,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Please confirm!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You must use your real mobile number (the one you have in hand). Otherwise, the phone top-up will not appear and payment will fail.',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9CE800),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _agreedToPhoneWarning = true;
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'I Understand and Agree',
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
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _telController.dispose();
    super.dispose();
  }

  Future<void> _startPayment() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _isPolling = false;
    });
    final intAmount = widget.book.price.floor();
    final result = await PaymentService.initiatePayment(
      tel: _telController.text.trim(),
      amount: intAmount.toString(),
    );
    setState(() {
      _isLoading = false;
      _statusMessage = result['message'] ?? '';
      _txRef = result['tx_ref'];
    });
    if (result['success'] == true && _txRef != null) {
      setState(() {
        _isPolling = true;
      });
      String finalStatus = '';
      await PaymentService.pollPaymentStatus(
        _txRef!,
        onStatus: (status) {
          setState(() {
            if (status == 'paid') {
              _statusMessage = '✅ Payment successful!';
              _isPolling = false;
            } else if (status == 'failed') {
              _statusMessage = '❌ Payment failed or cancelled.';
              _isPolling = false;
            } else {
              _statusMessage = 'Please confirm payment on your phone...';
            }
          });
          finalStatus = status;
        },
      );
      // After polling is done, check status and update Firestore/navigate
      if (finalStatus == 'paid') {
        final commissionRate = 0.10;
        final commission = (intAmount * commissionRate).round();
        final sellerPayout = intAmount - commission;
        await FirebaseFirestore.instance
            .collection('books')
            .doc(widget.book.id)
            .update({
              'buyerId': PaymentService.currentUserId(),
              'status': 'sold',
              'commission': commission,
              'sellerPayout': sellerPayout,
              'soldAt': FieldValue.serverTimestamp(),
            });
        await FirebaseFirestore.instance.collection('commissions').add({
          'bookId': widget.book.id,
          'commission': commission,
          'sellerPayout': sellerPayout,
          'amount': intAmount,
          'buyerId': PaymentService.currentUserId(),
          'sellerId': widget.book.sellerId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        // Add notification for buyer
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': PaymentService.currentUserId(),
          'title': 'Purchase Successful',
          'message':
              'You have successfully purchased "${widget.book.title}". You can now download your book.',
          'timestamp': FieldValue.serverTimestamp(),
          'bookId': widget.book.id,
          'unread': true,
        });
        // Add notification for seller
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': widget.book.sellerId,
          'title': 'Book Sold',
          'message':
              'Your book "${widget.book.title}" has been sold! Check your sales for details.',
          'timestamp': FieldValue.serverTimestamp(),
          'bookId': widget.book.id,
          'unread': true,
        });
        Fluttertoast.showToast(
          msg: '✔ Payment successful! You can now download your book.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green[700],
          textColor: Colors.white,
          fontSize: 18.0,
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    }
  }

  Future<void> _pollPaymentWithTimeout(String txRef, int intAmount) async {
    const timeout = Duration(seconds: 60);
    bool timedOut = false;
    await PaymentService.pollPaymentStatus(
      txRef,
      onStatus: (status) async {
        if (_pollStartTime != null &&
            DateTime.now().difference(_pollStartTime!) > timeout) {
          timedOut = true;
          setState(() {
            _isPolling = false;
            _showRefresh = true;
            _userPrompt =
                'Polling timed out. Please tap Refresh to check payment status again.';
          });
          return;
        }
        setState(() {
          if (status == 'paid') {
            _statusMessage = '✅ Payment successful!';
            _isPolling = false;
            _userPrompt = '';
            _showRefresh = false;
          } else if (status == 'failed') {
            _statusMessage = '❌ Payment failed or cancelled.';
            _isPolling = false;
            _userPrompt = '';
            _showRefresh = false;
          } else {
            _statusMessage = 'Please confirm payment on your phone...';
            _userPrompt =
                'Waiting for payment confirmation. Please approve the payment on your phone.';
          }
        });
        if (status == 'paid') {
          // Commission calculation (e.g., 10% commission)
          final commissionRate = 0.10;
          final commission = (intAmount * commissionRate).round();
          final sellerPayout = intAmount - commission;
          // Update book in Firestore
          await FirebaseFirestore.instance
              .collection('books')
              .doc(widget.book.id)
              .update({
                'buyerId': PaymentService.currentUserId(),
                'status': 'sold',
                'commission': commission,
                'sellerPayout': sellerPayout,
                'soldAt': FieldValue.serverTimestamp(),
              });
          // Optionally, store commission in a separate collection for admin tracking
          await FirebaseFirestore.instance.collection('commissions').add({
            'bookId': widget.book.id,
            'commission': commission,
            'sellerPayout': sellerPayout,
            'amount': intAmount,
            'buyerId': PaymentService.currentUserId(),
            'sellerId': widget.book.sellerId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          // Show a toast for success
          Fluttertoast.showToast(
            msg: 'Payment successful! You can now download your book.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          // Navigate back to Book Details
          if (mounted) {
            Navigator.of(
              context,
            ).pop(true); // Pass true to indicate payment success
          }
        }
      },
    );
    if (timedOut) {
      setState(() {
        _isPolling = false;
        _showRefresh = true;
        _userPrompt =
            'Polling timed out. Please tap Refresh to check payment status again.';
      });
    }
  }

  void _refreshPaymentStatus() {
    if (_txRef != null) {
      setState(() {
        _isPolling = true;
        _showRefresh = false;
        _userPrompt = 'Refreshing payment status...';
        _pollStartTime = DateTime.now();
      });
      _pollPaymentWithTimeout(_txRef!, widget.book.price.floor());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_agreedToPhoneWarning) {
      // Prevent interaction with the rest of the screen until agreed
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => NotificationScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Book details
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: widget.book.imageUrl.isNotEmpty
                        ? Image.network(
                            widget.book.imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : const CircleAvatar(child: Icon(Icons.book)),
                    title: Text(
                      widget.book.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Price: ${widget.book.price.toStringAsFixed(2)}',
                    ),
                  ),
                ),
                // Warning
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.orange, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please enter your real mobile number (the one you have in hand). Otherwise, the phone top-up will not appear and payment will fail!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Payment method selection (MTN only for now)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {}, // For future extensibility
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.yellow[700]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.network(
                                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSqyayaUSKKtheoVq7qNfyRa0cfTYTtsg01jw&s',
                                width: 48,
                                height: 48,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'MTN Mobile Money',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextFormField(
                  controller: _telController,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter phone number' : null,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? Column(
                        children: [
                          const SpinKitWave(color: Colors.orange, size: 40),
                          const SizedBox(height: 16),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.orange,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 32,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Please confirm the payment on your phone using the top-up prompt. Do not leave this page until payment is complete.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      fontSize: 17,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_statusMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                _statusMessage,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: _isPolling
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _startPayment();
                                }
                              },
                        child: const Text('Pay Now'),
                      ),
                const SizedBox(height: 20),
                Text(
                  _statusMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
