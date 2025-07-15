import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sales_service.dart';
import '../services/auth_service.dart';
import '../models/sale_model.dart';
import '../widgets/common_widgets.dart';

class ShoppingCartScreen extends StatelessWidget {
  const ShoppingCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          Consumer<SalesService>(
            builder: (context, salesService, child) {
              return TextButton(
                onPressed: salesService.currentCart.isEmpty ? null : () {
                  _showClearCartDialog(context, salesService);
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<SalesService>(
        builder: (context, salesService, child) {
          if (salesService.currentCart.isEmpty) {
            return const EmptyStateWidget(
              message: 'Your cart is empty',
              icon: Icons.shopping_cart_outlined,
              actionLabel: 'Start Shopping',
              onAction: null, // Will navigate back
            );
          }

          return Column(
            children: [
              // Cart Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: salesService.currentCart.length,
                  itemBuilder: (context, index) {
                    final item = salesService.currentCart[index];
                    return _buildCartItem(context, item, salesService);
                  },
                ),
              ),

              // Cart Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('\$${salesService.cartSubtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax (10%):'),
                        Text('\$${salesService.cartTax.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '\$${salesService.cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF667eea),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _completeSale(context, salesService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00b894),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Complete Sale',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, SaleItem item, SalesService salesService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image Placeholder
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.image,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)} each',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity Controls
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    salesService.updateCartItemQuantity(item.productId, item.quantity - 1);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFF667eea),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.quantity.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    salesService.updateCartItemQuantity(item.productId, item.quantity + 1);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF667eea),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, SalesService salesService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              salesService.clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _completeSale(BuildContext context, SalesService salesService) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show payment method selection
    final paymentMethod = await _showPaymentMethodDialog(context);
    if (paymentMethod == null) return;

    // Create sale object
    final sale = SaleModel(
      id: '',
      items: salesService.currentCart,
      subtotal: salesService.cartSubtotal,
      tax: salesService.cartTax,
      total: salesService.cartTotal,
      cashierId: currentUser.id,
      cashierName: currentUser.name,
      createdAt: DateTime.now(),
      paymentMethod: paymentMethod,
    );

    // Complete the sale
    final success = await salesService.completeSale(sale);

    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to complete sale'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showPaymentMethodDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('Cash'),
              onTap: () => Navigator.pop(context, 'cash'),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Card'),
              onTap: () => Navigator.pop(context, 'card'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('Mobile Payment'),
              onTap: () => Navigator.pop(context, 'mobile'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 