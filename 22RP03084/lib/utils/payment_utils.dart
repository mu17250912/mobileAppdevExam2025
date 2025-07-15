import 'package:flutter/material.dart';

void showPaymentError(BuildContext context, String? message) {
  if (message != null && message.contains('CORRESPONDENT_TEMPORARILY_UNAVAILABLE')) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payment Service Unavailable'),
        content: Text(
          'The payment provider is temporarily unavailable. Please try again later or check the status at https://status.pawapay.cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Payment failed.')),
    );
  }
} 