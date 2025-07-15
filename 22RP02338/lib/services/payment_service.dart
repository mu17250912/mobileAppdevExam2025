import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';

class PaymentService {
  static Future<String?> showPaymentMethodDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Payment Method'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'card'),
            child: Row(
              children: const [
                Icon(Icons.credit_card, color: Colors.blue),
                SizedBox(width: 8),
                Text('Card Payment'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'mtn'),
            child: Row(
              children: const [
                Icon(Icons.phone_android, color: Colors.orange),
                SizedBox(width: 8),
                Text('MTN Mobile Money'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool> startFlutterwavePayment({
    required BuildContext context,
    required String method, // 'card' or 'mtn'
    required String amount,
    required String userName,
    required String userEmail,
    required String userPhone,
    String currency = 'NGN',
  }) async {
    final Customer customer = Customer(
      name: userName,
      phoneNumber: userPhone,
      email: userEmail,
    );

    final flutterwave = Flutterwave(
      publicKey: "YOUR_FLUTTERWAVE_PUBLIC_KEY",
      currency: currency,
      redirectUrl: "https://your-redirect-url.com",
      txRef: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      customer: customer,
      paymentOptions: method == 'card' ? "card" : "mobilemoneyghana",
      customization: Customization(title: "Commissioner Payment"),
      isTestMode: true,
    );

    final result = await flutterwave.charge(context);

    if (result != null && result.status == "success") {
      return true;
    }
    return false;
  }
} 