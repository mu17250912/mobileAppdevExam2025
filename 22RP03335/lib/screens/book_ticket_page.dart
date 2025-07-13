import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:exam_mobile/screens/dashboard.dart' show notifications;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import '../utils/phone_validator.dart';

class BookTicketPage extends StatefulWidget {
  const BookTicketPage({super.key});

  @override
  State<BookTicketPage> createState() => _BookTicketPageState();
}

class _BookTicketPageState extends State<BookTicketPage> {
  int ticketCount = 1;
  bool booked = false;
  String bookingCode = '';
  final GlobalKey _ticketKey = GlobalKey();

  // Payment simulation
  String _selectedPayment = 'MTN';
  final List<String> _paymentMethods = ['MTN', 'Airtel', 'PayPal'];

  // Ticket type
  String _ticketType = 'Regular';
  final Map<String, int> _ticketPrices = {'Regular': 8000, 'VIP': 12000};
  final int _commissionPerTicket = 500;

  int get _ticketSubtotal => ticketCount * _ticketPrices[_ticketType]!;
  int get _commissionTotal => ticketCount * _commissionPerTicket;
  int get _totalAmount => _ticketSubtotal + _commissionTotal;

  /// Detects the provider from phone number and updates selected payment method
  void _detectProviderFromNumber(String phoneNumber) {
    String? provider = PhoneValidator.getProviderFromNumber(phoneNumber);
    if (provider != null && provider != _selectedPayment) {
      setState(() {
        _selectedPayment = provider;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Detected $provider number. Payment method updated to $provider.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _generateBookingCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rand.nextInt(chars.length))));
  }

  Future<void> _shareTicket() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing is only supported on Android and iOS. Please use the Download button and share the file manually.')),
      );
      return;
    }
    try {
      RenderRepaintBoundary boundary = _ticketKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer;
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/ticket.png').create();
      await file.writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      await Share.shareFiles([file.path], text: 'Here is my comedy event ticket!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to share ticket.')));
    }
  }

  Future<void> _downloadTicket() async {
    try {
      RenderRepaintBoundary boundary = _ticketKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer;
      if (kIsWeb) {
        // Web: Show message to user to take screenshot manually
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please take a screenshot of your ticket. Web download is not supported in this version.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Mobile/Desktop: Save to file system
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/ticket.png').create();
        await file.writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ticket image saved to ${file.path}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download ticket.')));
    }
  }

  Future<void> _showPaymentDialog() async {
    String input = '';
    String errorMessage = '';
    String label = _selectedPayment == 'PayPal' ? 'PayPal Email' : 'Phone Number';
    
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Pay with $_selectedPayment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ticket: $_ticketSubtotal RWF', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Commission: $_commissionTotal RWF', style: const TextStyle(color: Colors.deepPurple)),
                  const Divider(),
                  Text('Total: $_totalAmount RWF', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: _selectedPayment == 'PayPal' ? TextInputType.emailAddress : TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: label,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      errorText: errorMessage.isNotEmpty ? errorMessage : null,
                    ),
                    onChanged: (val) {
                      input = val;
                      // Clear error when user starts typing
                      if (errorMessage.isNotEmpty) {
                        setState(() {
                          errorMessage = '';
                        });
                      }
                      
                      // Detect provider if it's a phone number field
                      if (_selectedPayment == 'MTN') {
                        if (val.length >= 9) { // Minimum length for detection
                          // Only check for MTN numbers when MTN is selected
                          if (PhoneValidator.isValidMtnNumber(val)) {
                            // Number is valid MTN, keep current selection
                          } else if (PhoneValidator.isValidAirtelNumber(val)) {
                            // User entered Airtel number but MTN is selected - show error
                            setState(() {
                              errorMessage = 'This is an Airtel number. Please select Airtel as payment method or enter an MTN number (078/079).';
                            });
                          }
                        }
                      } else if (_selectedPayment == 'Airtel') {
                        if (val.length >= 9) { // Minimum length for detection
                          // Only check for Airtel numbers when Airtel is selected
                          if (PhoneValidator.isValidAirtelNumber(val)) {
                            // Number is valid Airtel, keep current selection
                          } else if (PhoneValidator.isValidMtnNumber(val)) {
                            // User entered MTN number but Airtel is selected - show error
                            setState(() {
                              errorMessage = 'This is an MTN number. Please select MTN as payment method or enter an Airtel number (072/073).';
                            });
                          }
                        }
                      }
                    },
                  ),
                  if (_selectedPayment == 'MTN' || _selectedPayment == 'Airtel') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Format: 07XXXXXXXX or +250XXXXXXXX',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate input based on payment method
                    if (input.isEmpty) {
                      setState(() {
                        errorMessage = 'Please enter your $label.';
                      });
                      return;
                    }
                    
                    if (_selectedPayment == 'PayPal') {
                      // Email validation with .com requirement
                      String emailValidationMessage = PhoneValidator.getEmailValidationMessage(input);
                      if (emailValidationMessage.isNotEmpty) {
                        setState(() {
                          errorMessage = emailValidationMessage;
                        });
                        return;
                      }
                    } else if (_selectedPayment == 'MTN') {
                      // Strict MTN validation - only accept 078/079
                      if (!PhoneValidator.isValidMtnNumber(input)) {
                        setState(() {
                          errorMessage = 'Invalid MTN number. Please enter a valid MTN Rwanda number starting with 078 or 079 (e.g., 0781234567)';
                        });
                        return;
                      }
                      // Format the phone number
                      input = PhoneValidator.formatPhoneNumber(input);
                    } else if (_selectedPayment == 'Airtel') {
                      // Strict Airtel validation - only accept 072/073
                      if (!PhoneValidator.isValidAirtelNumber(input)) {
                        setState(() {
                          errorMessage = 'Invalid Airtel number. Please enter a valid Airtel Rwanda number starting with 072 or 073 (e.g., 0721234567)';
                        });
                        return;
                      }
                      // Format the phone number
                      input = PhoneValidator.formatPhoneNumber(input);
                    }
                    
                    Navigator.pop(context);
                    _simulatePayment(input);
                  },
                  child: const Text('Pay'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _simulatePayment(String input) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Processing Payment'),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Please wait...'),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () async {
      Navigator.pop(context); // Close processing dialog
      setState(() {
        booked = true;
        bookingCode = _generateBookingCode();
      });
      // Add detailed notification to Firestore for the current user
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
          'ticketType': _ticketType,
          'ticketCount': ticketCount,
          'total': _totalAmount,
          'paymentMethod': _selectedPayment,
          'bookingCode': bookingCode,
          'email': _selectedPayment == 'PayPal' ? input : null,
          'phone': (_selectedPayment == 'MTN' || _selectedPayment == 'Airtel') ? input : null,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful! Booking confirmed.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Book Ticket', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F5BD5), Color(0xFF6A82FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: booked
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RepaintBoundary(
                        key: _ticketKey,
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.celebration, color: Colors.deepPurple, size: 60),
                                const SizedBox(height: 12),
                                Text(
                                  'Booking Confirmed!',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple[700]),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'You have booked $ticketCount $_ticketType ticket${ticketCount > 1 ? 's' : ''} for Comedy Event on 30th August at Kigali Convention Centre.',
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('Your booking code:', style: TextStyle(fontSize: 15, color: Colors.deepPurple)),
                                      const SizedBox(height: 4),
                                      Text(
                                        bookingCode,
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _downloadTicket,
                            icon: const Icon(Icons.download, color: Colors.deepPurple),
                            label: const Text('Download', style: TextStyle(color: Colors.deepPurple)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.deepPurple),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: _shareTicket,
                            icon: const Icon(Icons.share, color: Colors.deepPurple),
                            label: const Text('Share', style: TextStyle(color: Colors.deepPurple)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.deepPurple),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Back to Dashboard', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  )
                : Card(
                    margin: const EdgeInsets.all(24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 8,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event, color: Colors.deepPurple, size: 54),
                          const SizedBox(height: 12),
                          const Text(
                            'Comedy Event',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Date: 30th August\nVenue: Kigali Convention Centre',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          // Ticket type selection
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Select Ticket Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: _ticketPrices.keys.map((type) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: type,
                                    groupValue: _ticketType,
                                    onChanged: (val) {
                                      setState(() { _ticketType = val!; });
                                    },
                                    activeColor: Colors.deepPurple,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '$type (${_ticketPrices[type]} RWF)',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Tickets:', style: TextStyle(fontSize: 18, color: Colors.black87)),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.deepPurple),
                                      onPressed: ticketCount > 1
                                          ? () => setState(() => ticketCount--)
                                          : null,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text('$ticketCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
                                      onPressed: () => setState(() => ticketCount++),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Commission and total
                          Text('Ticket: $_ticketSubtotal RWF', style: const TextStyle(fontSize: 16)),
                          Text('Commission: $_commissionTotal RWF', style: const TextStyle(fontSize: 16, color: Colors.deepPurple)),
                          Text('Total: $_totalAmount RWF', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          const SizedBox(height: 16),
                          // Payment method selection
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Choose Payment Method:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: _paymentMethods.map((method) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: _selectedPayment == method 
                                    ? (method == 'MTN' ? Colors.orange.withOpacity(0.1) 
                                       : method == 'Airtel' ? Colors.red.withOpacity(0.1)
                                       : Colors.blue.withOpacity(0.1))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: _selectedPayment == method 
                                    ? Border.all(
                                        color: method == 'MTN' ? Colors.orange 
                                               : method == 'Airtel' ? Colors.red
                                               : Colors.blue,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: method,
                                    groupValue: _selectedPayment,
                                    onChanged: (val) {
                                      setState(() { _selectedPayment = val!; });
                                    },
                                    activeColor: method == 'MTN' ? Colors.orange 
                                               : method == 'Airtel' ? Colors.red
                                               : Colors.blue,
                                  ),
                                  Icon(
                                    method == 'MTN' ? Icons.phone_android 
                                    : method == 'Airtel' ? Icons.phone_iphone
                                    : Icons.payment,
                                    color: method == 'MTN' ? Colors.orange 
                                           : method == 'Airtel' ? Colors.red
                                           : Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      method,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: _selectedPayment == method ? FontWeight.bold : FontWeight.normal,
                                        color: method == 'MTN' ? Colors.orange 
                                               : method == 'Airtel' ? Colors.red
                                               : Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _showPaymentDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Pay for Ticket', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
} 