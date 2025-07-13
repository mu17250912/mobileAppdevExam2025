import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order.dart' as app_order;
import 'package:provider/provider.dart';
import 'user_provider.dart';

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  Color _getStatusColor(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return AppColors.textSecondary;
      case app_order.OrderStatus.confirmed:
        return AppColors.textPrimary;
      case app_order.OrderStatus.shipped:
        return AppColors.textPrimary;
      case app_order.OrderStatus.delivered:
        return AppColors.primary;
      case app_order.OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  Future<void> _updateOrderStatus(BuildContext context, String orderId, app_order.OrderStatus newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus.name});
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to ${newStatus.name}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e')),
        );
      }
    }
  }

  void _showStatusUpdateDialog(BuildContext context, String orderId, app_order.OrderStatus currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: app_order.OrderStatus.values.map((status) => ListTile(
            title: Text(status.name.toUpperCase()),
            trailing: currentStatus == status ? const Icon(Icons.check, color: AppColors.primary) : null,
            onTap: () {
              Navigator.pop(context);
              _updateOrderStatus(context, orderId, status);
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userType = userProvider.userType;
    final userId = userProvider.userData?['uid'];
    if (userType == null) {
      return const Scaffold(body: Center(child: Text('User type not found.')));
    }
    
    // Set appropriate app bar title based on user type
    String appBarTitle;
    switch (userType) {
      case 'Buyer':
        appBarTitle = 'My Orders';
        break;
      case 'Farmer':
        appBarTitle = 'Orders Received';
        break;
      case 'Admin':
        appBarTitle = 'Order Management';
        break;
      default:
        appBarTitle = 'Orders';
    }
    
    // Build the appropriate query based on user type
    Query ordersQuery;
    if (userType == 'Buyer') {
      // Orders placed by this user
      ordersQuery = FirebaseFirestore.instance.collection('orders').where('customerId', isEqualTo: userId);
    } else if (userType == 'Farmer') {
      // For farmers, we need to fetch all orders and filter in Dart
      // because Firestore doesn't support complex queries on nested array objects
      ordersQuery = FirebaseFirestore.instance.collection('orders');
    } else {
      // Admin: all orders
      ordersQuery = FirebaseFirestore.instance.collection('orders');
    }
    
    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    userType == 'Buyer' ? Icons.shopping_bag_outlined : Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userType == 'Buyer' 
                        ? 'No orders yet.\nStart shopping to see your orders here!'
                        : 'No orders received yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          
          // Filter orders for farmers (only show orders containing their products)
          List<QueryDocumentSnapshot> filteredDocs = docs;
          if (userType == 'Farmer') {
            filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final order = app_order.Order.fromMap(data);
              // Check if any item in the order belongs to this farmer
              return order.items.any((item) => item.farmerId == userId);
            }).toList();
            
            // If no orders after filtering, show empty state
            if (filteredDocs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No orders received yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }
          }
          
          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final data = filteredDocs[index].data() as Map<String, dynamic>;
              final order = app_order.Order.fromMap(data);
              final status = order.status;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text('Order #${order.id.substring(order.id.length - 8)}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (userType == 'Buyer') ...[
                        Text('Total: RWF ${order.totalAmount.toStringAsFixed(2)}'),
                      ] else ...[
                        Text('Customer: ${order.customerName}'),
                        Text('Total: RWF ${order.totalAmount.toStringAsFixed(2)}'),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Items:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('${item.productName} (${item.quantity} ${item.unit})'),
                                ),
                                Text('RWF ${item.totalPrice.toStringAsFixed(2)}'),
                              ],
                            ),
                          )),
                          const Divider(),
                          if (userType == 'Buyer') ...[
                            Text('Order Date: ${order.createdAt.toString().substring(0, 16)}'),
                            Text('Payment Method: ${order.paymentMethod}'),
                            if (order.shippingAddress != null)
                              Text('Delivery Address: ${order.shippingAddress}'),
                            if (order.phoneNumber != null)
                              Text('Contact: ${order.phoneNumber}'),
                            if (order.paymentMethod != 'Cash on Delivery')
                              Text(
                                'Payment Status: ${order.isPaid ? 'Paid' : 'Pending'}',
                                style: TextStyle(
                                  color: order.isPaid ? AppColors.primary : AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ] else ...[
                            Text('Customer Email: ${order.customerEmail}'),
                            if (order.phoneNumber != null)
                              Text('Phone: ${order.phoneNumber}'),
                            if (order.shippingAddress != null)
                              Text('Address: ${order.shippingAddress}'),
                            Text('Payment: ${order.paymentMethod}'),
                            Text('Order Date: ${order.createdAt.toString().substring(0, 16)}'),
                          ],
                          // Only show management controls for Farmers and Admins
                          if (userType != 'Buyer') ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _showStatusUpdateDialog(context, order.id, status),
                                  child: const Text('Update Status'),
                                ),
                                if (order.paymentMethod != 'Cash on Delivery')
                                  ElevatedButton(
                                    onPressed: () {
                                      // Mark as paid
                                      FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(order.id)
                                          .update({'isPaid': true});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: order.isPaid ? Colors.grey : AppColors.primary,
                                    ),
                                    child: Text(order.isPaid ? 'Paid' : 'Mark as Paid'),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 