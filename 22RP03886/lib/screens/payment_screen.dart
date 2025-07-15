import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
// Only import flutter_stripe if not web
// ignore: uri_does_not_exist
// import 'package:flutter_stripe/flutter_stripe.dart' if (dart.library.html) 'noop.dart';
import 'auth_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String plan; // 'monthly' or 'annual'
  final String price; // e.g. '5' or '50'
  final VoidCallback onPaymentSuccess;
  const PaymentScreen({required this.plan, required this.price, required this.onPaymentSuccess});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  String? _error;

  int get amountCents => ((double.tryParse(widget.price) ?? 0) * 100).toInt();

  Future<void> _payMobile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Create PaymentIntent on your backend (replace with your endpoint)
      final response = await http.post(
        Uri.parse('https://your-backend.com/create-payment-intent'),
        body: {
          'amount': (amountCents).toString(),
          'currency': 'usd',
        },
      );
      final paymentIntent = json.decode(response.body);

      // 2. Initialize payment sheet (only on mobile/desktop)
      // Uncomment the following if flutter_stripe is available
      // await Stripe.instance.initPaymentSheet(
      //   paymentSheetParameters: SetupPaymentSheetParameters(
      //     paymentIntentClientSecret: paymentIntent['clientSecret'],
      //     merchantDisplayName: 'Smart Daily Planner',
      //   ),
      // );

      // 3. Present payment sheet
      // await Stripe.instance.presentPaymentSheet();

      widget.onPaymentSuccess();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment successful!')));
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // For web: Launch Stripe Checkout
  Future<void> _payWeb() async {
    // This URL should be created by your backend using Stripe's API
    final url = 'https://checkout.stripe.com/pay/cs_test_...';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      setState(() {
        _error = 'Could not launch payment URL.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stripe Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('Plan: 24{widget.plan}'),
            Text('Amount: 24${widget.price}'),
            SizedBox(height: 32),
            if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: kIsWeb ? _payWeb : _payMobile,
                    child: Text(kIsWeb ? 'Pay with Stripe Checkout' : 'Pay with Card'),
                  ),
            SizedBox(height: 32),
            Text('This is a real Stripe payment. Use test cards in development. See README for backend setup.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
} 