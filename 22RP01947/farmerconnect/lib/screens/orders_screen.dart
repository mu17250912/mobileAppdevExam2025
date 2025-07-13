import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'profile_screen.dart';
import 'auth_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.getAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error:  ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No orders yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Orders will appear here when buyers place them',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data();
            final orderId = orders[index].id;
            return _orderCard(
              context,
              orderId: orderId,
              title: order['productName'] ?? 'Unknown Product',
              buyer: order['buyerName'] ?? 'Unknown Buyer',
              phone: order['buyerPhone'] ?? 'No phone',
              quantity: '${order['quantity']} kg',
              total: '${order['total']} RWF',
              delivery: order['delivery'] ?? 'Not specified',
              status: order['status'] ?? 'Pending',
              isPending: order['status'] == 'Pending',
              orderData: order,
            );
          },
        );
      },
    );
  }

  Widget _orderCard(
    BuildContext context, {
    required String orderId,
    required String title,
    required String buyer,
    required String phone,
    required String quantity,
    required String total,
    required String delivery,
    required String status,
    required bool isPending,
    Map<String, dynamic>? orderData,
  }) {
    final currentUserId = AppUser.userId;
    final isFarmer = orderData != null && orderData['farmerId'] == currentUserId;
    final isBuyerRole = AppUser.userType == 'Buyer';
    print('AppUser.userId: $currentUserId, order farmerId: ${orderData?['farmerId']}');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFE8F5E8) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: const Color(0xFF2E8B57), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E8B57))),
          const SizedBox(height: 5),
          Text('Buyer: $buyer'),
          Text('Phone: $phone'),
          Text('Quantity: $quantity'),
          Text('Total: $total'),
          Text('Delivery: $delivery'),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending ? const Color(0xFFFFC107) : const Color(0xFF28A745),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isPending ? Colors.black87 : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isBuyerRole) ...[
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _showEditOrderDialog(context, orderId, orderData),
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () => _updateOrderStatus(context, orderId, 'Cancelled'),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C757D)),
                  child: const Text('Cancel'),
                ),
              ],
              if (isPending && isFarmer) ...[
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _updateOrderStatus(context, orderId, 'Accepted'),
                  child: const Text('Accept'),
                ),
                const SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () => _updateOrderStatus(context, orderId, 'Cancelled'),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C757D)),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showEditOrderDialog(BuildContext context, String orderId, Map<String, dynamic>? orderData) {
    final _quantityController = TextEditingController(text: orderData?['quantity']?.toString() ?? '');
    final _deliveryController = TextEditingController(text: orderData?['delivery'] ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _deliveryController,
                decoration: const InputDecoration(labelText: 'Delivery'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final quantity = int.tryParse(_quantityController.text);
                final delivery = _deliveryController.text;
                if (quantity != null && delivery.isNotEmpty) {
                  await FirestoreService.updateOrder(orderId, {
                    'quantity': quantity,
                    'delivery': delivery,
                  });
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order updated!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateOrderStatus(BuildContext context, String orderId, String status) async {
    try {
      await FirestoreService.updateOrderStatus(orderId, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $status'),
            backgroundColor: status == 'Accepted' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 