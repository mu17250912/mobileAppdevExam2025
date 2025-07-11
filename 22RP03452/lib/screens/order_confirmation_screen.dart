import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  void _printOrder(BuildContext context) async {
    final Map<String, dynamic> orderData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final List<dynamic>? items = orderData['items'] as List<dynamic>?;
    final double? total = orderData['total'] as double?;
    final fruit = orderData['fruit'];
    final quantity = orderData['quantity'];

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Order Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              if (items != null && items.isNotEmpty)
                ...[
                  pw.Text('Items:', style: pw.TextStyle(fontSize: 18)),
                  ...items.map((item) {
                    final fruit = item is Map<String, dynamic> ? item['fruit'] : item.fruit;
                    final quantity = item is Map<String, dynamic> ? item['quantity'] : item.quantity;
                    final price = item is Map<String, dynamic> ? (fruit != null ? fruit['price'] : '') : item.fruit.price;
                    final totalPrice = item is Map<String, dynamic>
                        ? (item['totalPrice'] ?? ((double.tryParse((fruit?['price'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) * (quantity ?? 1)))
                        : item.totalPrice;
                    return pw.Text(
                      '${fruit != null ? (fruit is Map ? fruit['name'] : fruit.name) : ''} x$quantity - $price (Total: ${totalPrice.toStringAsFixed(0)}rwf)'
                    );
                  }),
                  pw.Divider(),
                  pw.Text('Grand Total: ${total?.toStringAsFixed(0) ?? ''}rwf', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ]
              else if (fruit != null)
                pw.Text(
                  fruit is Map ?
                    '${fruit['name']} x${quantity ?? 1} - ${fruit['price']}' :
                    '${fruit.name} x${quantity ?? 1} - ${fruit.price}',
                  style: pw.TextStyle(fontSize: 18),
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _showPaymentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        int selectedIndex = 0;
        final paymentMethods = [
          {
            'name': 'MTN Momo',
            'logo': Icons.phone_android,
            'info': 'Pay with MTN Mobile Money. Fast and secure.'
          },
          {
            'name': 'Bank of Kigali',
            'logo': Icons.account_balance,
            'info': 'Pay using your Bank of Kigali account.'
          },
          {
            'name': 'PayPal',
            'logo': Icons.account_balance_wallet,
            'info': 'Pay easily with your PayPal account.'
          },
        ];
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Choose Payment Method',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(paymentMethods.length, (index) {
                    final method = paymentMethods[index];
                    return ListTile(
                      leading: Icon(method['logo'] as IconData, size: 36),
                      title: Text(method['name'] as String),
                      subtitle: selectedIndex == index ? Text(method['info'] as String) : null,
                      selected: selectedIndex == index,
                      onTap: () => setModalState(() => selectedIndex = index),
                      selectedTileColor: Colors.grey[200],
                    );
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Your payment is processed. Please wait to get your product.')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text('Pay'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> orderData = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    final List<dynamic>? items = orderData['items'] as List<dynamic>?;
    final double? total = orderData['total'] as double?;
    final fruit = orderData['fruit'];
    final quantity = orderData['quantity'];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              // Thank You Message
              const Text(
                'thank you for shopping with us',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 20),
              // Order Details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: items != null && items.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...items.map((item) {
                            final fruit = item.fruit;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: fruit.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: fruit.icon != null
                                        ? Icon(fruit.icon, color: fruit.color)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fruit.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                        Text(
                                          'Quantity: ${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          fruit.price,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF4CAF50),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Total: ${item.totalPrice.toStringAsFixed(0)}rwf',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              Text(
                                '${total?.toStringAsFixed(0) ?? ''}rwf',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : fruit != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: fruit['color']?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: fruit['image'] != null
                                        ? Icon(
                                            fruit['image'],
                                            size: 30,
                                            color: fruit['color'],
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fruit['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                        Text(
                                          'Quantity: ${quantity ?? 1}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          fruit['price'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF4CAF50),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const Text('No order data.'),
              ),
              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _showPaymentModal(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text('Pay'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _printOrder(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text('Print'),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Delivery Message
              const Text(
                'Your fruits are on way!!!!!!!!!!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 50),
              // Back to Home Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Back to home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

