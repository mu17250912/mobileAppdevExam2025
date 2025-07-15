import 'package:flutter/material.dart';
import 'services/cart_service.dart';
import 'package:provider/provider.dart';
import 'payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          Consumer<CartService>(
            builder: (context, cart, child) =>
              cart.items.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Clear All',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Cart'),
                          content: const Text('Are you sure you want to remove all items from your cart?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                cart.clearCart();
                                Navigator.pop(context);
                              },
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<CartService>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty.', style: TextStyle(fontSize: 20, color: Colors.grey)),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final price = (item['price'] ?? 0.0).toDouble();
                    final quantity = (item['quantity'] ?? 1).toInt();
                    final totalPrice = price * quantity;
                    final imageUrl = (item['imageUrl'] ?? '').isNotEmpty
                        ? item['imageUrl']
                        : 'https://via.placeholder.com/100x100.png?text=No+Image';
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[200],
                                  width: 64,
                                  height: 64,
                                  child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'Product',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RWF ${price.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: quantity > 1
                                            ? () => cart.updateQuantity(item['id'], quantity - 1)
                                            : null,
                                        color: Colors.red[400],
                                        iconSize: 22,
                                      ),
                                      Text('$quantity', style: const TextStyle(fontSize: 16)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => cart.updateQuantity(item['id'], quantity + 1),
                                        color: Colors.green[700],
                                        iconSize: 22,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Remove',
                              onPressed: () => cart.removeItem(item['id']),
                              color: Colors.red[400],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                            Text('RWF ${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Commission (5%):', style: TextStyle(fontSize: 16)),
                            Text('RWF ${(cart.total * 0.05).toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                            Text('RWF ${(cart.total * 1.05).toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: cart.items.isEmpty
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentScreen(
                                    totalAmount: cart.total,
                                    items: cart.items,
                                  ),
                                ),
                              );
                            },
                      label: const Text('Pay'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}