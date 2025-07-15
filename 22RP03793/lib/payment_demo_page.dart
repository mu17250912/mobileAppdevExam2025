import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DemoPaymentPage extends StatefulWidget {
  final String orderId;
  final double total;

  const DemoPaymentPage({Key? key, required this.orderId, required this.total}) : super(key: key);

  @override
  State<DemoPaymentPage> createState() => _DemoPaymentPageState();
}

class _DemoPaymentPageState extends State<DemoPaymentPage> {
  String paymentMethod = 'PayPal';
  final TextEditingController numberController = TextEditingController();
  bool isPaying = false;
  String? resultMessage;

  final List<String> paymentMethods = [
    'PayPal',
    'MTN Mobile Money',
    'Airtel Money',
  ];

  String get inputLabel {
    if (paymentMethod == 'PayPal') return 'PayPal Email';
    return 'Phone Number';
  }

  Future<void> simulatePayment() async {
    setState(() {
      isPaying = true;
      resultMessage = null;
    });

    await Future.delayed(const Duration(seconds: 2)); // Simulate payment processing

    // Simulate always success for demo
    await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
      'paymentStatus': 'paid',
      'paymentMethod': paymentMethod,
      'paymentNumber': numberController.text.trim(),
    });

    setState(() {
      isPaying = false;
      resultMessage = 'Payment successful! Your order is now marked as paid.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Order Total: FRW ${widget.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: paymentMethod,
              items: paymentMethods.map((method) => DropdownMenuItem(
                value: method,
                child: Text(method),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  paymentMethod = value!;
                  numberController.clear();
                });
              },
              decoration: const InputDecoration(labelText: 'Payment Method'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: numberController,
              keyboardType: paymentMethod == 'PayPal' ? TextInputType.emailAddress : TextInputType.phone,
              decoration: InputDecoration(
                labelText: inputLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            isPaying
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Pay Now'),
                    onPressed: () {
                      if (numberController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter your number or email')),
                        );
                        return;
                      }
                      simulatePayment();
                    },
                  ),
            if (resultMessage != null) ...[
              const SizedBox(height: 24),
              Text(resultMessage!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home'),
              ),
            ]
          ],
        ),
      ),
    );
  }
} 