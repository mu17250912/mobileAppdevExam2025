import 'package:flutter/material.dart';

import 'services/cart_service.dart';
import 'payment_success_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'dart:math';

class CheckoutScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double totalCost;

  const CheckoutScreen({super.key, required this.items, required this.totalCost});

  Future<void> _processOrder(BuildContext context) async {
    final ordersCollection = FirebaseFirestore.instance.collection('orders');
    final cartService = Provider.of<CartService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Get the actual logged-in user
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to complete your order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Generate a unique order ID
    final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final referenceId = 'REF_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Create an order for each item in the cart
      for (var item in items) {
        await ordersCollection.add({
          'orderId': orderId,
          'productId': item['id'] ?? '',
          'productName': item['name'] ?? '',
          'price': item['price'] ?? 0.0,
          'imageUrl': item['imageUrl'] ?? '',
          'quantity': item['quantity'] ?? 1,
          'buyerId': currentUser,
          'buyerUsername': currentUser,
          'dealer': item['dealer'] ?? '',
          'status': 'Pending',
          'orderDate': Timestamp.now(),
          'referenceId': referenceId,
          'totalAmount': totalCost,
        });
      }

      // Clear the cart
      cartService.clearCart();

      // Navigate to success screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            orderId: orderId,
            amount: totalCost,
            referenceId: referenceId,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Order Summary', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          ...items.map((item) {
            final price = (item['price'] ?? 0.0).toDouble();
            final quantity = (item['quantity'] ?? 1).toInt();
            final totalPrice = price * quantity;
            return ListTile(
              title: Text('${item['name'] ?? 'Product'} (x$quantity)'),
              trailing: Text('RWF ${totalPrice.toStringAsFixed(0)}'),
            );
          }),
          const Divider(),
          ListTile(
            title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            trailing: Text('RWF ${totalCost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => _processOrder(context),
          child: const Text('Pay Now'),
        ),
      ),
    );
  }
} 